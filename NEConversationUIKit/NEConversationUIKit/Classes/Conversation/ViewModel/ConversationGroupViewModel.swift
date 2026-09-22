// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objc
public protocol ConversationGroupViewModelDelegate: NSObjectProtocol {
  func conversationGroupDidReload()
  func conversationGroupSelectionChanged()
}

@objcMembers
open class ConversationGroupViewModel: NSObject, NEConversationGroupListener, NEConversationListener {
  public weak var delegate: ConversationGroupViewModelDelegate?
  public private(set) var commonGroups = [NEConversationGroupModel]()
  public private(set) var hiddenGroups = [NEConversationGroupModel]()
  public private(set) var selectedGroup: NEConversationGroupModel?
  public private(set) var selectedCustomData = [NEConversationListModel]()
  public private(set) var selectedCustomOffset: Int64 = 0
  public private(set) var selectedCustomFinished = true
  public private(set) var selectedCustomGroupNeedsReload = false
  private(set) var selectedUnreadData = [NEConversationListModel]()
  private(set) var selectedUnreadOffset: Int64 = 0
  private(set) var selectedUnreadFinished = true

  private var selectedUnreadLoading = false

  private lazy var groupRepo = ConversationGroupRepo.shared
  private lazy var conversationRepo = ConversationRepo.shared
  private let pageSize = 50
  private var defaultUnreadSubscribed = false
  private var subscribedUnreadGroupIds = Set<String>()
  private var selectedUnreadRequestID = 0
  private var listenersRegistered = false

  override public init() {
    super.init()
    syncEnabledState()
  }

  deinit {
    if listenersRegistered {
      clearUnreadSubscriptions()
      groupRepo.removeConversationGroupListener(self)
      conversationRepo.removeConversationListener(self)
    }
  }

  open var isEnabled: Bool {
    IMKitConfigCenter.shared.enableConversationGroup &&
      NIMSDK.shared().v2Option?.enableV2CloudConversation == true
  }

  @discardableResult
  func syncEnabledState() -> Bool {
    if isEnabled {
      if listenersRegistered == false {
        groupRepo.addConversationGroupListener(self)
        conversationRepo.addConversationListener(self)
        listenersRegistered = true
      }
      return true
    }

    selectedUnreadRequestID += 1
    if listenersRegistered {
      clearUnreadSubscriptions()
      groupRepo.removeConversationGroupListener(self)
      conversationRepo.removeConversationListener(self)
      listenersRegistered = false
    }
    clearGroupState()
    return false
  }

  open func loadGroups(_ completion: ((NSError?) -> Void)? = nil) {
    guard syncEnabledState() else {
      completion?(nil)
      return
    }

    groupRepo.getConversationGroupList { [weak self] groups, error in
      guard let self = self else {
        return
      }
      guard self.isEnabled else {
        completion?(nil)
        return
      }
      if let error = error {
        completion?(error)
        return
      }
      self.rebuildGroups(groups ?? [])
      self.refreshUnreadCounts()
      self.delegate?.conversationGroupDidReload()
      completion?(nil)
    }
  }

  /// Refreshes values that are derived from the current language without rebuilding
  /// the group selection and local ordering state.
  func refreshLocalizedDefaultGroupNames() {
    guard isEnabled else {
      return
    }
    let names: [NEConversationGroupType: String] = [
      .all: localizable("conversation_group_all"),
      .atMe: localizable("conversation_group_at_me"),
      .unread: localizable("conversation_group_unread"),
    ]
    var changed = false
    for group in commonGroups + hiddenGroups {
      guard let name = names[group.type], group.name != name else {
        continue
      }
      group.name = name
      changed = true
    }
    if changed {
      delegate?.conversationGroupDidReload()
    }
  }

  open func selectGroup(_ group: NEConversationGroupModel) {
    guard syncEnabledState() else {
      return
    }
    selectedUnreadRequestID += 1
    selectedGroup = group
    if group.type == .custom {
      selectedCustomOffset = 0
      selectedCustomFinished = false
      selectedCustomData.removeAll()
      loadMoreSelectedCustomGroup()
    } else if group.type == .unread {
      selectedUnreadOffset = 0
      selectedUnreadFinished = false
      selectedUnreadData.removeAll()
      selectedUnreadLoading = false
      loadMoreSelectedUnreadGroup()
    } else {
      delegate?.conversationGroupSelectionChanged()
    }
  }

  open func displayedData(from allData: [NEConversationListModel]) -> [NEConversationListModel] {
    guard isEnabled else {
      return allData
    }
    guard let selectedGroup = selectedGroup else {
      return allData
    }
    switch selectedGroup.type {
    case .all:
      return allData
    case .atMe:
      return allData.filter { model in
        guard let conversationId = model.conversation?.conversationId else {
          return false
        }
        guard V2NIMConversationIdUtil.conversationType(conversationId) == .CONVERSATION_TYPE_TEAM else {
          return false
        }
        return NEAtMessageManager.instance?.isAtCurrentUser(conversationId: conversationId) == true
      }
    case .unread:
      return selectedUnreadData
    case .custom:
      return selectedCustomData
    }
  }

  open func loadMoreSelectedCustomGroup(_ completion: ((NSError?, Bool) -> Void)? = nil) {
    guard syncEnabledState(),
          selectedGroup?.type == .custom,
          let groupId = selectedGroup?.groupId,
          selectedCustomFinished == false else {
      completion?(nil, true)
      return
    }

    groupRepo.getConversationListByGroupId(groupId, offset: selectedCustomOffset, limit: pageSize) { [weak self] conversations, offset, finished, error in
      guard let self = self else {
        return
      }
      guard self.isEnabled else {
        completion?(nil, true)
        return
      }
      if let offset = offset {
        self.selectedCustomOffset = offset
      }
      self.selectedCustomFinished = finished ?? true
      if let conversations = conversations {
        self.selectedCustomData.append(contentsOf: conversations.map {
          let model = NEConversationListModel()
          model.conversation = $0
          return model
        })
        self.sortSelectedCustomData()
      }
      self.delegate?.conversationGroupSelectionChanged()
      completion?(error, self.selectedCustomFinished)
    }
  }

  /// Loads unread conversations from the SDK and excludes muted conversations locally.
  /// If a page only contains muted conversations, continue paging so the UI does not
  /// get stuck on an empty first page while more eligible conversations exist.
  func loadMoreSelectedUnreadGroup(_ completion: ((NSError?, Bool) -> Void)? = nil) {
    guard syncEnabledState(),
          selectedGroup?.type == .unread,
          selectedUnreadFinished == false else {
      completion?(nil, true)
      return
    }
    guard selectedUnreadLoading == false else {
      return
    }

    selectedUnreadLoading = true
    let requestID = selectedUnreadRequestID
    let option = V2NIMConversationOption()
    option.onlyUnread = true
    loadUnreadPage(option: option, requestID: requestID, completion: completion)
  }

  private func loadUnreadPage(option: V2NIMConversationOption,
                              requestID: Int,
                              completion: ((NSError?, Bool) -> Void)?) {
    conversationRepo.getConversationListByOption(
      selectedUnreadOffset,
      limit: pageSize,
      option: option
    ) { [weak self] result, error in
      guard let self = self else {
        return
      }
      guard self.isEnabled else {
        completion?(nil, true)
        return
      }
      guard requestID == self.selectedUnreadRequestID,
            self.selectedGroup?.type == .unread else {
        return
      }

      if let error = error {
        self.selectedUnreadLoading = false
        completion?(error, self.selectedUnreadFinished)
        return
      }

      let conversations = result?.conversationList ?? []
      let currentOffset = self.selectedUnreadOffset
      let nextOffset = result?.offset ?? currentOffset
      self.selectedUnreadOffset = nextOffset
      self.selectedUnreadFinished = result?.finished ?? true
      if self.selectedUnreadFinished == false, nextOffset == currentOffset {
        // Prevent a malformed/non-progressing SDK page from causing an endless
        // recursive request when all returned conversations are muted.
        self.selectedUnreadFinished = true
      }
      let eligibleConversations = conversations.filter { $0.mute == false }
      let models = eligibleConversations.map {
        let model = NEConversationListModel()
        model.conversation = $0
        return model
      }
      let existingIds = Set(self.selectedUnreadData.compactMap { $0.conversation?.conversationId })
      self.selectedUnreadData.append(contentsOf: models.filter {
        guard let conversationId = $0.conversation?.conversationId else {
          return false
        }
        return existingIds.contains(conversationId) == false
      })
      self.selectedUnreadData.sort { lhs, rhs in
        ConversationListSort.comesBefore(lhs, rhs)
      }

      // A page can contain only muted unread conversations. Consume subsequent
      // pages before reporting an empty unread group to the controller.
      if models.isEmpty, self.selectedUnreadFinished == false {
        self.loadUnreadPage(option: option, requestID: requestID, completion: completion)
        return
      }

      self.selectedUnreadLoading = false
      DispatchQueue.main.async {
        self.delegate?.conversationGroupSelectionChanged()
        completion?(nil, self.selectedUnreadFinished)
      }
    }
  }

  open func loadGroupConversations(groupId: String,
                                   offset: Int64 = 0,
                                   limit: Int = 100,
                                   _ completion: @escaping ([NEConversationListModel], Int64, Bool, NSError?) -> Void) {
    guard syncEnabledState() else {
      completion([], offset, true, nil)
      return
    }
    groupRepo.getConversationListByGroupId(groupId, offset: offset, limit: limit) { [weak self] conversations, nextOffset, finished, error in
      guard self?.isEnabled == true else {
        completion([], offset, true, nil)
        return
      }
      let models = (conversations ?? []).map { conversation in
        let model = NEConversationListModel()
        model.conversation = conversation
        return model
      }
      completion(models, nextOffset ?? offset, finished ?? true, error)
    }
  }

  open func loadAllGroupConversationIds(groupId: String,
                                        _ completion: @escaping (Set<String>?, NSError?) -> Void) {
    guard syncEnabledState() else {
      completion([], nil)
      return
    }
    var ids = Set<String>()
    func loadPage(_ offset: Int64) {
      groupRepo.getConversationListByGroupId(groupId, offset: offset, limit: 100) { [weak self] conversations, nextOffset, finished, error in
        guard self?.isEnabled == true else {
          completion(ids, nil)
          return
        }
        if let error = error {
          completion(nil, error)
          return
        }
        conversations?.forEach { ids.insert($0.conversationId) }
        if finished == true {
          completion(ids, nil)
        } else if let nextOffset = nextOffset, nextOffset != offset {
          loadPage(nextOffset)
        } else {
          completion(ids, nil)
        }
      }
    }
    loadPage(0)
  }

  open func createGroup(name: String, _ completion: @escaping (V2NIMConversationGroup?, NSError?) -> Void) {
    guard syncEnabledState() else {
      completion(nil, featureDisabledError())
      return
    }
    groupRepo.createConversationGroup(name, serverExtension: nil, conversationIds: nil) { [weak self] result, error in
      guard let self = self else {
        completion(result?.group, error)
        return
      }
      guard self.isEnabled else {
        completion(nil, self.featureDisabledError())
        return
      }
      if let group = result?.group {
        self.insertNewVisibleGroup(group)
        self.refreshUnreadCounts()
        self.delegate?.conversationGroupDidReload()
        completion(group, nil)
      } else {
        completion(nil, error)
      }
    }
  }

  open func updateGroupName(groupId: String, name: String, _ completion: @escaping (NSError?) -> Void) {
    guard syncEnabledState() else {
      completion(featureDisabledError())
      return
    }
    groupRepo.updateConversationGroup(groupId, name: name, serverExtension: nil) { [weak self] error in
      guard let self = self else {
        completion(error)
        return
      }
      guard self.isEnabled else {
        completion(self.featureDisabledError())
        return
      }
      if error == nil {
        self.loadGroups()
      }
      completion(error)
    }
  }

  open func deleteGroup(groupId: String, _ completion: @escaping (NSError?) -> Void) {
    guard syncEnabledState() else {
      completion(featureDisabledError())
      return
    }
    groupRepo.deleteConversationGroup(groupId) { [weak self] error in
      guard let self = self else {
        completion(error)
        return
      }
      guard self.isEnabled else {
        completion(self.featureDisabledError())
        return
      }
      if error == nil {
        self.removeGroup(groupId)
      }
      completion(error)
    }
  }

  open func addConversations(groupId: String,
                             conversationIds: [String],
                             _ completion: @escaping ([V2NIMConversationOperationResult]?, NSError?) -> Void) {
    guard syncEnabledState() else {
      completion(nil, featureDisabledError())
      return
    }
    groupRepo.addConversationsToGroup(groupId, conversationIds: conversationIds) { [weak self] results, error in
      guard let self = self else {
        completion(results, error)
        return
      }
      guard self.isEnabled else {
        completion(nil, self.featureDisabledError())
        return
      }
      let hasSuccessfulResult = results?.contains { result in
        guard let error = result.error as V2NIMError? else { return true }
        return error.code == 0 || error.code == 200
      } == true
      if error == nil, hasSuccessfulResult {
        self.selectedCustomGroupNeedsReload = true
      }
      completion(results, error)
    }
  }

  open func removeConversations(groupId: String,
                                conversationIds: [String],
                                _ completion: @escaping ([V2NIMConversationOperationResult]?, NSError?) -> Void) {
    guard syncEnabledState() else {
      completion(nil, featureDisabledError())
      return
    }
    groupRepo.removeConversationsFromGroup(groupId, conversationIds: conversationIds) { [weak self] results, error in
      guard let self = self else {
        completion(results, error)
        return
      }
      guard self.isEnabled else {
        completion(nil, self.featureDisabledError())
        return
      }
      let hasSuccessfulResult = results?.contains { result in
        guard let error = result.error as V2NIMError? else { return true }
        return error.code == 0 || error.code == 200
      } == true
      if error == nil, hasSuccessfulResult {
        self.selectedCustomGroupNeedsReload = true
      }
      completion(results, error)
    }
  }

  /// 返回会话列表后，重新拉取当前选中的自定义分组数据。
  open func refreshSelectedCustomGroup(_ completion: (() -> Void)? = nil) {
    guard syncEnabledState(), selectedGroup?.type == .custom else {
      selectedCustomGroupNeedsReload = false
      completion?()
      return
    }

    selectedCustomGroupNeedsReload = false
    selectedCustomOffset = 0
    selectedCustomFinished = false
    selectedCustomData.removeAll()
    loadMoreSelectedCustomGroup { _, _ in
      completion?()
    }
  }

  open func moveCommonToHidden(_ group: NEConversationGroupModel) {
    guard isEnabled,
          group.canHide,
          let index = commonGroups.firstIndex(where: { $0.groupId == group.groupId }) else {
      return
    }
    commonGroups.remove(at: index)
    hiddenGroups.append(group)
    ensureAllFirst()
    saveLocalConfig()
    resetSelectionIfNeeded()
    delegate?.conversationGroupDidReload()
  }

  open func moveHiddenToCommon(_ group: NEConversationGroupModel) {
    guard isEnabled,
          let index = hiddenGroups.firstIndex(where: { $0.groupId == group.groupId }) else {
      return
    }
    hiddenGroups.remove(at: index)
    commonGroups.append(group)
    ensureAllFirst()
    saveLocalConfig()
    delegate?.conversationGroupDidReload()
  }

  open func updateCommonOrder(_ groups: [NEConversationGroupModel]) {
    guard isEnabled else {
      return
    }
    commonGroups = groups
    ensureAllFirst()
    saveLocalConfig()
    delegate?.conversationGroupDidReload()
  }

  open func groupErrorMessage(_ error: NSError?) -> String {
    guard let error = error else {
      return commonLocalizable("failed_operation")
    }
    switch error.code {
    case 110_304:
      return localizable("conversation_group_belonged_limit")
    case 110_404:
      return localizable("conversation_group_conversation_not_exist")
    case 116_404:
      return localizable("conversation_group_not_exist")
    case 116_435:
      return localizable("conversation_group_limit")
    case 116_437:
      return localizable("conversation_group_members_limit")
    default:
      return error.localizedDescription
    }
  }

  private func rebuildGroups(_ sdkGroups: [V2NIMConversationGroup]) {
    let config = NEConversationGroupLocalConfigHelper.mergeAndSave(groups: sdkGroups)
    let configMap = Dictionary(uniqueKeysWithValues: config.items.map { ($0.groupId, $0) })
    let customGroups = sdkGroups.compactMap { group -> NEConversationGroupModel? in
      guard let groupId = group.groupId else {
        return nil
      }
      return NEConversationGroupModel(type: .custom, groupId: groupId, name: group.name ?? "", sdkGroup: group)
    }

    let defaults = defaultGroups()
    commonGroups = [defaults[0]]
    hiddenGroups = []

    for defaultGroup in defaults.dropFirst() {
      if configMap[defaultGroup.groupId]?.hidden == true {
        hiddenGroups.append(defaultGroup)
      } else {
        commonGroups.append(defaultGroup)
      }
    }

    for custom in customGroups {
      if configMap[custom.groupId]?.hidden == false {
        commonGroups.append(custom)
      } else {
        hiddenGroups.append(custom)
      }
    }

    commonGroups = sort(groups: commonGroups, configMap: configMap)
    hiddenGroups = sort(groups: hiddenGroups, configMap: configMap)
    ensureAllFirst()
    if selectedGroup == nil || commonGroups.contains(where: { $0.groupId == selectedGroup?.groupId }) == false {
      selectedGroup = commonGroups.first
    }
  }

  private func defaultGroups() -> [NEConversationGroupModel] {
    [
      NEConversationGroupModel(type: .all, groupId: NEConversationGroupModel.allId, name: localizable("conversation_group_all")),
      NEConversationGroupModel(type: .atMe, groupId: NEConversationGroupModel.atMeId, name: localizable("conversation_group_at_me")),
      NEConversationGroupModel(type: .unread, groupId: NEConversationGroupModel.unreadId, name: localizable("conversation_group_unread")),
    ]
  }

  private func sort(groups: [NEConversationGroupModel],
                    configMap: [String: NEConversationGroupLocalConfigItem]) -> [NEConversationGroupModel] {
    groups.sorted { lhs, rhs in
      if lhs.type == .all {
        return true
      }
      if rhs.type == .all {
        return false
      }
      let lhsOrder = configMap[lhs.groupId]?.order ?? Int.max
      let rhsOrder = configMap[rhs.groupId]?.order ?? Int.max
      if lhsOrder == rhsOrder {
        return lhs.groupId < rhs.groupId
      }
      return lhsOrder < rhsOrder
    }
  }

  private func ensureAllFirst() {
    if let allIndex = commonGroups.firstIndex(where: { $0.type == .all }), allIndex != 0 {
      let all = commonGroups.remove(at: allIndex)
      commonGroups.insert(all, at: 0)
    }
  }

  private func saveLocalConfig() {
    NEConversationGroupLocalConfigHelper.update(common: commonGroups, hidden: hiddenGroups)
  }

  private func insertNewVisibleGroup(_ group: V2NIMConversationGroup) {
    guard let groupId = group.groupId else {
      return
    }
    let model = NEConversationGroupModel(type: .custom, groupId: groupId, name: group.name ?? "", sdkGroup: group)
    commonGroups.removeAll { $0.groupId == groupId }
    hiddenGroups.removeAll { $0.groupId == groupId }
    commonGroups.append(model)
    saveLocalConfig()
  }

  private func removeGroup(_ groupId: String) {
    unsubscribeCustomGroupUnread(groupId)
    commonGroups.removeAll { $0.groupId == groupId }
    hiddenGroups.removeAll { $0.groupId == groupId }
    saveLocalConfig()
    resetSelectionIfNeeded()
    delegate?.conversationGroupDidReload()
  }

  private func resetSelectionIfNeeded() {
    guard let selected = selectedGroup,
          commonGroups.contains(where: { $0.groupId == selected.groupId }) else {
      selectedGroup = commonGroups.first
      delegate?.conversationGroupSelectionChanged()
      return
    }
  }

  open func refreshVirtualCounts(allData: [NEConversationListModel]) {
    guard isEnabled else {
      return
    }
    let atMeCount = allData.filter { model in
      guard let conversationId = model.conversation?.conversationId else {
        return false
      }
      guard V2NIMConversationIdUtil.conversationType(conversationId) == .CONVERSATION_TYPE_TEAM else {
        return false
      }
      return NEAtMessageManager.instance?.isAtCurrentUser(conversationId: conversationId) == true
    }.count
    for group in commonGroups + hiddenGroups {
      switch group.type {
      case .atMe:
        group.unreadCount = atMeCount
      case .all, .unread, .custom:
        break
      }
    }
  }

  private func refreshDefaultUnreadCount() {
    guard isEnabled else {
      return
    }
    groupRepo.getUnreadCountByFilter(makeUnreadCountFilter()) { [weak self] count, error in
      guard self?.isEnabled == true, error == nil, let count = count else {
        return
      }
      DispatchQueue.main.async {
        self?.updateDefaultUnreadCount(count)
      }
    }
  }

  private func updateDefaultUnreadCount(_ unreadCount: Int) {
    var changed = false
    for group in commonGroups + hiddenGroups where group.type == .all || group.type == .unread {
      if group.unreadCount != unreadCount {
        changed = true
      }
      group.unreadCount = unreadCount
    }
    if changed {
      delegate?.conversationGroupDidReload()
    }
  }

  func refreshUnreadCounts() {
    guard syncEnabledState() else {
      return
    }
    syncUnreadSubscriptions()
    refreshDefaultUnreadCount()
    for group in commonGroups + hiddenGroups where group.type == .custom {
      refreshCustomGroupUnreadCount(group.groupId)
    }
  }

  private func refreshCustomGroupUnreadCount(_ groupId: String) {
    guard isEnabled else {
      return
    }
    groupRepo.getUnreadCountByFilter(makeUnreadCountFilter(groupId)) { [weak self] count, error in
      guard let self = self, self.isEnabled, error == nil else {
        return
      }
      guard let count = count else {
        return
      }
      DispatchQueue.main.async {
        for group in self.commonGroups + self.hiddenGroups where group.groupId == groupId {
          group.unreadCount = count
        }
        self.delegate?.conversationGroupDidReload()
      }
    }
  }

  private func refreshChangedGroup(_ groupId: String) {
    guard isEnabled else {
      return
    }
    refreshCustomGroupUnreadCount(groupId)
    guard selectedGroup?.type == .custom, selectedGroup?.groupId == groupId else {
      return
    }
    selectedCustomGroupNeedsReload = true
    selectedCustomOffset = 0
    selectedCustomFinished = false
    selectedCustomData.removeAll()
    loadMoreSelectedCustomGroup()
  }

  private func sortSelectedCustomData() {
    selectedCustomData.sort { lhsModel, rhsModel in
      ConversationListSort.comesBefore(lhsModel, rhsModel)
    }
  }

  private func syncUnreadSubscriptions() {
    guard isEnabled else {
      return
    }
    if defaultUnreadSubscribed == false {
      if groupRepo.subscribeUnreadCountByFilter(makeUnreadCountFilter()) == nil {
        defaultUnreadSubscribed = true
      }
    }

    let currentGroupIds = Set((commonGroups + hiddenGroups).filter { $0.type == .custom }.map(\.groupId))
    for groupId in Array(subscribedUnreadGroupIds) where currentGroupIds.contains(groupId) == false {
      unsubscribeCustomGroupUnread(groupId)
    }
    for groupId in currentGroupIds where subscribedUnreadGroupIds.contains(groupId) == false {
      if groupRepo.subscribeUnreadCountByFilter(makeUnreadCountFilter(groupId)) == nil {
        subscribedUnreadGroupIds.insert(groupId)
      }
    }
  }

  private func unsubscribeCustomGroupUnread(_ groupId: String) {
    guard subscribedUnreadGroupIds.contains(groupId) else {
      return
    }
    _ = groupRepo.unsubscribeUnreadCountByFilter(makeUnreadCountFilter(groupId))
    subscribedUnreadGroupIds.remove(groupId)
  }

  private func clearUnreadSubscriptions() {
    if defaultUnreadSubscribed {
      _ = groupRepo.unsubscribeUnreadCountByFilter(makeUnreadCountFilter())
      defaultUnreadSubscribed = false
    }
    for groupId in Array(subscribedUnreadGroupIds) {
      _ = groupRepo.unsubscribeUnreadCountByFilter(makeUnreadCountFilter(groupId))
    }
    subscribedUnreadGroupIds.removeAll()
  }

  private func clearGroupState() {
    commonGroups.removeAll()
    hiddenGroups.removeAll()
    selectedGroup = nil
    selectedCustomData.removeAll()
    selectedCustomOffset = 0
    selectedCustomFinished = true
    selectedCustomGroupNeedsReload = false
    selectedUnreadData.removeAll()
    selectedUnreadOffset = 0
    selectedUnreadFinished = true
    selectedUnreadLoading = false
  }

  private func featureDisabledError() -> NSError {
    NSError(
      domain: "NEConversationUIKit.ConversationGroup",
      code: NSFeatureUnsupportedError,
      userInfo: [NSLocalizedDescriptionKey: commonLocalizable("failed_operation")]
    )
  }

  private func makeUnreadCountFilter(_ groupId: String? = nil) -> V2NIMConversationFilter {
    let filter = V2NIMConversationFilter()
    filter.conversationGroupId = groupId
    // 分组未读数需要过滤掉免打扰会话。
    filter.ignoreMuted = true
    return filter
  }

  public func onConversationGroupCreated(_ group: V2NIMConversationGroup) {
    guard isEnabled else {
      return
    }
    loadGroups()
  }

  public func onConversationGroupDeleted(_ groupId: String) {
    guard isEnabled else {
      return
    }
    removeGroup(groupId)
  }

  public func onConversationGroupChanged(_ group: V2NIMConversationGroup) {
    guard isEnabled, let groupId = group.groupId else {
      return
    }
    var groupFound = false
    for model in commonGroups + hiddenGroups where model.groupId == groupId {
      model.name = group.name ?? ""
      model.sdkGroup = group
      groupFound = true
    }
    if groupFound {
      delegate?.conversationGroupDidReload()
      refreshChangedGroup(groupId)
    } else {
      loadGroups()
    }
  }

  public func onConversationsAddedToGroup(_ groupId: String, conversations: [V2NIMConversation]) {
    guard isEnabled else {
      return
    }
    if selectedGroup?.type == .custom, selectedGroup?.groupId == groupId {
      selectedCustomGroupNeedsReload = true
    }
    refreshChangedGroup(groupId)
  }

  public func onConversationsRemovedFromGroup(_ groupId: String, conversationIds: [String]) {
    guard isEnabled else {
      return
    }
    if selectedGroup?.type == .custom, selectedGroup?.groupId == groupId {
      selectedCustomGroupNeedsReload = true
    }
    refreshChangedGroup(groupId)
  }

  public func onConversationChanged(_ conversations: [V2NIMConversation]) {
    guard isEnabled else {
      return
    }
    if selectedGroup?.type == .unread {
      var changed = false
      for conversation in conversations {
        let index = selectedUnreadData.firstIndex {
          $0.conversation?.conversationId == conversation.conversationId
        }
        let shouldDisplay = conversation.unreadCount > 0 && conversation.mute == false
        if shouldDisplay {
          if let index = index {
            selectedUnreadData[index].conversation = conversation
          } else {
            let model = NEConversationListModel()
            model.conversation = conversation
            selectedUnreadData.append(model)
          }
          changed = true
        } else if let index = index {
          selectedUnreadData.remove(at: index)
          changed = true
        }
      }

      if changed {
        selectedUnreadData.sort { lhs, rhs in
          ConversationListSort.comesBefore(lhs, rhs)
        }
        delegate?.conversationGroupSelectionChanged()
      } else if selectedUnreadData.isEmpty, selectedUnreadFinished == false {
        loadMoreSelectedUnreadGroup()
      }
      return
    }

    guard selectedGroup?.type == .custom,
          let groupId = selectedGroup?.groupId else {
      return
    }

    var changed = false
    for conversation in conversations {
      let containsCurrentGroup = conversation.groupIds?.contains(groupId) == true
      if let index = selectedCustomData.firstIndex(where: { $0.conversation?.conversationId == conversation.conversationId }) {
        if containsCurrentGroup {
          selectedCustomData[index].conversation = conversation
        } else {
          selectedCustomData.remove(at: index)
        }
        changed = true
      } else if containsCurrentGroup {
        let model = NEConversationListModel()
        model.conversation = conversation
        selectedCustomData.append(model)
        changed = true
      }
    }

    if changed {
      sortSelectedCustomData()
      delegate?.conversationGroupSelectionChanged()
    }
  }

  public func onConversationUnreadCountCleared(_ conversationIds: [String]) {
    guard isEnabled else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.isEnabled else { return }
      let clearedIds = Set(conversationIds)
      var changed = false
      if self.selectedGroup?.type == .unread {
        for model in self.selectedUnreadData where clearedIds.contains(model.conversation?.conversationId ?? "") {
          model.markUnreadCountCleared()
        }
        let oldCount = self.selectedUnreadData.count
        self.selectedUnreadData.removeAll { $0.unreadCount == 0 }
        changed = oldCount != self.selectedUnreadData.count
      } else if self.selectedGroup?.type == .custom {
        for model in self.selectedCustomData {
          guard let conversationId = model.conversation?.conversationId,
                clearedIds.contains(conversationId) else { continue }
          model.markUnreadCountCleared()
          changed = true
        }
      }
      if changed {
        self.delegate?.conversationGroupSelectionChanged()
      }
    }
  }

  public func onConversationReadTimeUpdated(_ conversationId: String, _ readTime: TimeInterval) {
    guard isEnabled else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.isEnabled else { return }
      if self.selectedGroup?.type == .unread {
        guard let model = self.selectedUnreadData.first(where: {
          $0.conversation?.conversationId == conversationId
        }) else { return }
        model.markUnreadCountCleared(through: readTime)
        self.selectedUnreadData.removeAll { $0.unreadCount == 0 }
      } else if self.selectedGroup?.type == .custom,
                let model = self.selectedCustomData.first(where: {
                  $0.conversation?.conversationId == conversationId
                }) {
        model.markUnreadCountCleared(through: readTime)
      } else {
        return
      }
      self.delegate?.conversationGroupSelectionChanged()
    }
  }

  public func onConversationDeleted(_ conversationIds: [String]) {
    guard isEnabled else {
      return
    }
    if selectedGroup?.type == .unread {
      let ids = Set(conversationIds)
      let oldCount = selectedUnreadData.count
      selectedUnreadData.removeAll { model in
        guard let conversationId = model.conversation?.conversationId else {
          return false
        }
        return ids.contains(conversationId)
      }
      if oldCount != selectedUnreadData.count {
        delegate?.conversationGroupSelectionChanged()
      }
      return
    }

    guard selectedGroup?.type == .custom else {
      return
    }
    let ids = Set(conversationIds)
    let oldCount = selectedCustomData.count
    selectedCustomData.removeAll { model in
      guard let conversationId = model.conversation?.conversationId else {
        return false
      }
      return ids.contains(conversationId)
    }
    if oldCount != selectedCustomData.count {
      delegate?.conversationGroupSelectionChanged()
    }
  }

  public func onTotalUnreadCountChanged(_ unreadCount: Int) {
    // Group counts are filtered by ignoreMuted and are updated by the filter callback.
  }

  public func onConversationSyncFinished() {
    guard isEnabled else {
      return
    }
    refreshUnreadCounts()
  }

  public func onUnreadCountChangedByFilter(_ filter: V2NIMConversationFilter, _ unreadCount: Int) {
    guard isEnabled else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.isEnabled else {
        return
      }
      guard let groupId = filter.conversationGroupId, groupId.isEmpty == false else {
        self.updateDefaultUnreadCount(unreadCount)
        return
      }
      for group in self.commonGroups + self.hiddenGroups where group.groupId == groupId {
        group.unreadCount = unreadCount
      }
      self.delegate?.conversationGroupDidReload()
    }
  }
}
