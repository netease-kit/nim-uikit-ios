// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import NIMSDK
import UIKit

@objcMembers
open class FunBotSubSessionChatViewController: FunP2PChatViewController, TopicChatViewModelOutput {
  public let botSessionName: String
  public var botConversationDisplayTitle: String
  public let botSubSessionGuideLabel = UILabel()
  public lazy var botSubSessionGuideView: UIView = createBotSubSessionGuideView()
  private var botSubSessionGuideTopConstraint: NSLayoutConstraint?
  private weak var botSubSessionGuideTopView: UIView?

  public init(conversationId: String,
              sessionId: String,
              sessionName: String,
              topic: V2NIMTopic?) {
    botSessionName = sessionName
    botConversationDisplayTitle = sessionName
    super.init(conversationId: conversationId, anchor: nil)
    viewModel = TopicChatViewModel(conversationId: conversationId,
                                   anchor: nil,
                                   topic: topic,
                                   sessionName: sessionName)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    applyFunBotSubSessionBackground()
    configureBotSubSessionNavigation()
    applyBotSubSessionTitle()
    setupBotSubSessionGuideView()
    refreshBotSubSessionGuideView()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    applyFunBotSubSessionBackground()
    configureBotSubSessionNavigation()
    applyBotSubSessionTitle()
  }

  override public var titleContent: String {
    didSet {
      title = titleContent
      updateBotSubSessionGuideText()
    }
  }

  override open func remoteUserEndEditing() {
    title = titleContent
  }

  override public func remoteUserOnlineChanged() {
    title = titleContent
  }

  open var topicChatViewModel: TopicChatViewModel? {
    viewModel as? TopicChatViewModel
  }

  override open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    loadBaseSessionInfo { [weak self] in
      guard let self = self else {
        completion()
        return
      }
      self.viewModel.loadShowName([sessionId]) { [weak self] in
        guard let self = self else {
          completion()
          return
        }
        DispatchQueue.main.async {
          self.botConversationDisplayTitle = self.normalConversationDisplayTitle(sessionId)
          self.applyBotSubSessionTitle(fallback: sessionId)
          completion()
        }
      }
    }
  }

  open func loadBaseSessionInfo(_ completion: @escaping () -> Void) {
    if NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) == nil {
      ContactRepo.shared.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { _, _ in
        completion()
      }
    } else {
      completion()
    }
  }

  override open func getUserSettingViewController() -> NEBaseUserSettingViewController {
    let controller = super.getUserSettingViewController()
    controller.fromBotSubSession = true
    controller.botSubSessionTopic = topicChatViewModel?.topic
    return controller
  }

  override open func toSetting() {
    guard let vm = topicChatViewModel,
          vm.topic != nil else {
      return
    }
    showBotSubSessionActionSheet()
  }

  open func showBotSubSessionActionSheet() {
    guard topicChatViewModel != nil else {
      return
    }
    let controller = BotSubSessionActionSheetController(title: botSubSessionDisplayTitle())
    controller.onRename = { [weak self, weak controller] in
      controller?.dismiss(animated: false)
      self?.showRenameAlert()
    }
    controller.onDelete = { [weak self, weak controller] in
      controller?.dismiss(animated: false)
      self?.showDeleteAlert()
    }
    // 微信皮肤：展开双栏时底部弹窗只覆盖右列，折叠外屏保持窗口级呈现。
    showBottomSheetInDetailColumn(controller, animated: false)
  }

  open func showRenameAlert() {
    guard let vm = topicChatViewModel,
          vm.topic != nil else {
      return
    }
    let controller = BotSubSessionRenameDialogController(name: botSubSessionDisplayTitle(), saveButtonBackgroundColor: UIColor(hexString: "#58BE6B"))
    controller.onSave = { [weak self, weak controller] name in
      if name.isEmpty {
        controller?.showToast(chatLocalizable("bot_sub_session_input_name"))
        return
      }
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        controller?.showToast(commonLocalizable("network_error"))
        return
      }
      vm.updateTopicName(name) { _, error in
        if error != nil {
          controller?.showToast(chatLocalizable("bot_sub_session_rename_failed"))
        } else {
          controller?.dismiss(animated: false)
        }
      }
    }
    present(controller, animated: false)
  }

  open func showDeleteAlert() {
    guard let vm = topicChatViewModel,
          let _ = vm.topic else {
      return
    }
    let topicName = botSubSessionDisplayTitle()
    let controller = BotSubSessionDeleteDialogController(title: chatLocalizable("bot_sub_session_delete_title"), message: String(format: chatLocalizable("bot_sub_session_delete_topic"), topicName), confirmButtonBackgroundColor: UIColor(hexString: "#58BE6B"))
    controller.onDelete = { [weak self, weak controller] in
      controller?.dismiss(animated: false)
      guard NEChatDetectNetworkTool.shareInstance.manager?.isReachable != false else {
        self?.showToast(commonLocalizable("network_error"))
        return
      }
      vm.removeCurrentTopic { error in
        if error != nil {
          self?.showToast(chatLocalizable("bot_sub_session_delete_failed"))
        }
      }
    }
    present(controller, animated: false)
  }

  public func onTopicChanged(_ topic: V2NIMTopic) {
    applyBotSubSessionTitle()
    configureBotSubSessionNavigation()
    refreshBotSubSessionGuideView()
  }

  public func onTopicTipMessage(_ text: String) {
    showToast(text)
  }

  override open func sending(_ message: V2NIMMessage, _ index: IndexPath) {
    super.sending(message, index)
    refreshBotSubSessionGuideView()
  }

  override open func sendSuccess(_ message: V2NIMMessage, _ index: IndexPath) {
    super.sendSuccess(message, index)
    refreshBotSubSessionGuideView()
  }

  override open func onRecvMessages(_ messages: [V2NIMMessage], _ indexs: [IndexPath]) {
    super.onRecvMessages(messages, indexs)
    refreshBotSubSessionGuideView()
  }

  override open func setOperationItems(items: inout [OperationItem], model: MessageContentModel?) {
    items.removeAll { item in
      item.type == .pin || item.type == .removePin || item.type == .recall
    }
  }

  @discardableResult
  override open func expandMoreAction() -> [NEMoreItemModel] {
    var items = super.expandMoreAction()
    items.removeAll { $0.type == .aiChat }
    chatInputView.chatAddMoreView.configData(data: items)
    return items
  }

  public func onCurrentTopicRemoved() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.onCurrentTopicRemoved()
      }
      return
    }
    guard isViewLoaded,
          let navigationController,
          navigationController.topViewController === self else {
      return
    }
    let toast = chatLocalizable("bot_sub_session_removed")
    let showToastOnList = { [weak self] in
      guard let self,
            let navigationController = self.navigationController,
            let listController = navigationController.viewControllers.dropLast().last as? NEBaseBotSubSessionListViewController else {
        return
      }
      navigationController.popViewController(animated: false)
      listController.showToast(toast)
    }
    let presentedController = presentedViewController ?? navigationController.presentedViewController
    if let presentedController {
      presentedController.dismiss(animated: false, completion: showToastOnList)
    } else {
      showToastOnList()
    }
  }

  open func createBotSubSessionGuideView() -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.isUserInteractionEnabled = false

    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "bot_sub_session_guide"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit

    let label = botSubSessionGuideLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 24, weight: .semibold)
    label.textColor = UIColor(red: 153 / 255.0, green: 153 / 255.0, blue: 153 / 255.0, alpha: 1)
    label.textAlignment = .center
    updateBotSubSessionGuideText()

    container.addSubview(imageView)
    container.addSubview(label)
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      imageView.topAnchor.constraint(equalTo: container.topAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 64),
      imageView.heightAnchor.constraint(equalToConstant: 64),
      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
      label.leftAnchor.constraint(greaterThanOrEqualTo: container.leftAnchor, constant: 24),
      label.rightAnchor.constraint(lessThanOrEqualTo: container.rightAnchor, constant: -24),
      label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    return container
  }

  open func setupBotSubSessionGuideView() {
    contentView.addSubview(botSubSessionGuideView)
    botSubSessionGuideTopConstraint = botSubSessionGuideView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12)
    let centerYConstraint = botSubSessionGuideView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    centerYConstraint.priority = .defaultLow
    NSLayoutConstraint.activate([
      botSubSessionGuideView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      botSubSessionGuideView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      botSubSessionGuideView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
      botSubSessionGuideView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      centerYConstraint,
      botSubSessionGuideTopConstraint!,
    ])
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateBotSubSessionGuideTopConstraint()
  }

  func updateBotSubSessionGuideTopConstraint() {
    let topView: UIView? = topMessageView.superview != nil && topMessageView.isHidden == false
      ? topMessageView
      : nil
    guard topView !== botSubSessionGuideTopView else {
      return
    }
    botSubSessionGuideTopConstraint?.isActive = false
    if let topView {
      botSubSessionGuideTopConstraint = botSubSessionGuideView.topAnchor.constraint(greaterThanOrEqualTo: topView.bottomAnchor, constant: 12)
    } else {
      botSubSessionGuideTopConstraint = botSubSessionGuideView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12)
    }
    botSubSessionGuideTopConstraint?.isActive = true
    botSubSessionGuideTopView = topView
  }

  open func refreshBotSubSessionGuideView() {
    updateBotSubSessionGuideText()
    let hasMessage = !viewModel.messages.isEmpty
    botSubSessionGuideView.isHidden = topicChatViewModel?.topic != nil || hasMessage
  }

  open func botSubSessionDisplayTitle() -> String {
    if let title = topicChatViewModel?.topic?.topicName?.trimmingCharacters(in: .whitespacesAndNewlines),
       !title.isEmpty {
      return title
    }
    if topicChatViewModel?.topic == nil {
      return chatLocalizable("bot_sub_session_new_conversation")
    }
    let conversationTitle = botConversationDisplayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if !conversationTitle.isEmpty {
      return conversationTitle
    }
    let fallbackTitle = titleContent.trimmingCharacters(in: .whitespacesAndNewlines)
    if !fallbackTitle.isEmpty {
      return fallbackTitle
    }
    return botConversationTitleFallback()
  }

  open func updateBotSubSessionGuideText() {
    botSubSessionGuideLabel.text = String(
      format: chatLocalizable("bot_sub_session_guide"),
      botSubSessionGuideTitle()
    )
  }

  open func botSubSessionGuideTitle() -> String {
    if let title = topicChatViewModel?.topic?.topicName?.trimmingCharacters(in: .whitespacesAndNewlines),
       !title.isEmpty {
      return title
    }
    let conversationTitle = botConversationDisplayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if !conversationTitle.isEmpty {
      return conversationTitle
    }
    return botConversationTitleFallback()
  }

  open func applyBotSubSessionTitle(fallback: String? = nil) {
    let displayTitle = botSubSessionDisplayTitleWithFallback(fallback)
    titleContent = displayTitle
    title = displayTitle
    updateBotSubSessionGuideText()
  }

  open func botSubSessionDisplayTitleWithFallback(_ fallback: String? = nil) -> String {
    let displayTitle = botSubSessionDisplayTitle()
    if !displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return displayTitle
    }
    return fallback ?? botConversationTitleFallback()
  }

  open func normalConversationDisplayTitle(_ sessionId: String) -> String {
    let showName = viewModel.getShowName(sessionId).trimmingCharacters(in: .whitespacesAndNewlines)
    if !showName.isEmpty {
      return showName
    }
    let routeTitle = botSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !routeTitle.isEmpty {
      return routeTitle
    }
    return sessionId
  }

  open func botConversationTitleFallback() -> String {
    let routeTitle = botSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !routeTitle.isEmpty {
      return routeTitle
    }
    return ChatRepo.sessionId
  }

  open func configureBotSubSessionNavigation() {
    let canShowAction = topicChatViewModel?.topic != nil
    navigationView.moreButton.isHidden = !canShowAction
    guard canShowAction else {
      navigationItem.rightBarButtonItem = nil
      return
    }
    let image = ChatUIConfig.shared.messageProperties.titleBarRightRes ?? coreLoader.loadImage("three_point")
    navigationView.setMoreButtonImage(image)
    navigationView.moreButton.removeTarget(nil, action: nil, for: .touchUpInside)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(toSetting))
    addRightAction(image, #selector(toSetting), self)
  }

  open func applyFunBotSubSessionBackground() {
    navigationController?.navigationBar.backgroundColor = .funChatNavigationBg
    navigationView.backgroundColor = .funChatNavigationBg
    navigationView.titleBarBottomLine.backgroundColor = .funChatNavigationDivideBg
    if #available(iOS 13.0, *) {
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = .funChatNavigationBg
      appearance.shadowColor = .funChatNavigationDivideBg
      navigationController?.navigationBar.standardAppearance = appearance
      navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
  }
}
