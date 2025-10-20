// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objc
public protocol ContactViewModelDelegate: NSObjectProtocol {
  func reloadTableView()
}

@objcMembers
open class ContactViewModel: NSObject {
  typealias RefreshBlock = () -> Void
  public var contactSections: [ContactSection] = []

  public var indexs: [String]?
  private var contactHeaders: ContactSection?
  public var contactRepo = ContactRepo.shared
  private var initalDict = [String: [ContactInfo]]()
  public weak var delegate: ContactViewModelDelegate?

  /// 在线状态记录，[accountId: 是否在线]
  public var onlineStatusDic = [String: Bool]()

  var unreadCount = 0 {
    didSet {
      refresh?()
    }
  }

  var refresh: RefreshBlock?
  public init(contactHeaders: [ContactHeadItem]?) {
    super.init()
    NEALog.infoLog(
      ModuleName + " " + className(),
      desc: #function + ", contactHeaders.count: \(contactHeaders?.count ?? 0)"
    )

    if let headSection = headerSection(headerItem: contactHeaders) {
      self.contactHeaders = headSection
      contactSections.append(headSection)
    }

    contactRepo.addContactListener(self)
    TeamRepo.shared.addTeamListener(self)

    if IMKitConfigCenter.shared.enableOnlineStatus {
      SubscribeRepo.shared.addListener(self)
    }
  }

  deinit {
    contactRepo.removeContactListener(self)
    TeamRepo.shared.removeTeamListener(self)

    if IMKitConfigCenter.shared.enableOnlineStatus {
      SubscribeRepo.shared.removeListener(self)
    }
  }

  open func loadData(_ filters: Set<String>? = nil, completion: @escaping (NSError?, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
    getContactList(filters) { contacts, error in
      if let users = contacts {
        weakSelf?.contactSections.removeAll()
        if let contactHeaders = weakSelf?.contactHeaders {
          weakSelf?.contactSections.append(contactHeaders)
        }
        weakSelf?.contactSections.append(contentsOf: users)
        weakSelf?.indexs = self.getIndexs(contactSections: users)
        completion(nil, users.count)
        if IMKitConfigCenter.shared.enableOnlineStatus {
          weakSelf?.subscribeOnlineStatus()
        }
      } else {
        completion(nil, 0)
      }
    }
  }

  open func getContactList(_ filters: Set<String>? = nil, _ completion: @escaping ([ContactSection]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", filters.count: \(filters?.count ?? 0)")

    // 优选从缓存中取
    if !NEFriendUserCache.shared.isEmpty() {
      let friends = NEFriendUserCache.shared.getFriendListNotInBlocklist().map(\.value)
      let contactList = formatData(friends, filters)
      completion(contactList, nil)
      return
    }

    // 缓存中没有则远端查询, 刷新统一走缓存通知
    contactRepo.getContactList { friends, error in
      NEALog.infoLog("contact bar getFriendList", desc: "friend count:\(String(describing: friends?.count))")
    }
  }

  /// 数据格式化
  /// - Parameters:
  ///   - friends: 好友列表
  ///   - filters: 过滤列表
  /// - Returns: 格式化后的好友列表
  open func formatData(_ friends: [NEUserWithFriend]?, _ filters: Set<String>? = nil) -> [ContactSection] {
    var contactList: [ContactSection] = []
    if var users = friends {
      initalDict = [String: [ContactInfo]]()
      if let filterUsers = filters {
        users = users.filter { userFriend in
          if let uid = userFriend.user?.accountId, filterUsers.contains(uid) {
            return false
          }
          return true
        }
      }

      if users.isEmpty {
        return contactList
      }

      let digitRegular = NSPredicate(format: "SELF MATCHES %@", "[0-9]")
      let azRegular = NSPredicate(format: "SELF MATCHES %@", "[A-Z]")
      var digitList = [ContactInfo]()
      var specialCharList = [ContactInfo]()
      for userFriend: NEUserWithFriend in users {
        // get inital of name
        var name = userFriend.user?.name ?? userFriend.user?.accountId
        if let alias = userFriend.friend?.alias, !alias.isEmpty {
          name = alias
        }

        let inital = name?.initalLetter() ?? "#"
        let contactInfo = ContactInfo()
        contactInfo.user = userFriend

        if digitRegular.evaluate(with: inital) { // [0-9]
          digitList.append(contactInfo)
        } else if !azRegular.evaluate(with: inital) { // [#]
          specialCharList.append(contactInfo)
        } else { // [A-Z]
          if initalDict[inital] != nil {
            initalDict[inital]?.append(contactInfo)
          } else {
            initalDict[inital] = [contactInfo]
          }
        }
      }

      digitList.sort()
      specialCharList.sort()

      for key in initalDict.keys {
        if let value = initalDict[key] {
          contactList.append(ContactSection(initial: key, contacts: value.sorted()))
        }
      }

      var result = contactList.sorted()

      let specialList = digitList + specialCharList
      if !specialList.isEmpty {
        result.append(ContactSection(initial: "#", contacts: specialList))
      }
      return result
    }
    return contactList
  }

  /// 返回好友列表
  /// - Returns: 不包含顶部预设数据（验证消息、黑名单、我的群聊）的好友列表
  open func getFriendSections() -> [ContactSection] {
    let friendSections = contactSections.filter { $0.initial != "" }
    return friendSections
  }

  /// 获取验证消息未读数，包含好友申请和入群申请
  /// - Parameter completion: 回调
  open func getValidationMessage(_ completion: ((Int, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.getUnreadApplicationCount { [weak self] count, error in
      if IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth {
        let option = V2NIMTeamJoinActionInfoQueryOption()
        option.offset = 0
        option.limit = neTeamJoinActionPageLimit
        TeamRepo.shared.getTeamJoinActionInfoList(option) { result, error in
          if let actions = result?.infos {
            let unreadActions = actions.filter { $0.timestamp > neTeamJoinActionReadTime }
            self?.unreadCount = count + unreadActions.count
          } else {
            self?.unreadCount = count
          }
          completion?(self?.unreadCount ?? count, error)
        }
      }
    }
  }

  open func headerSection(headerItem: [ContactHeadItem]?) -> ContactSection? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", headerItem.count: \(headerItem?.count ?? 0)")
    guard let header = headerItem else {
      return nil
    }
    var infos: [ContactInfo] = []
    for item in header {
      let info = ContactInfo()
      info.user = NEUserWithFriend(alias: item.name, avatar: item.imageName)
      info.contactCellType = .ContactOthers
      info.router = item.router
      infos.append(info)
    }
    return ContactSection(initial: "", contacts: infos)
  }

  open func getIndexs(contactSections: [ContactSection]?) -> [String]? {
    // ["A"..."Z", "#"]
    let idx = UnicodeScalar("A").value ... UnicodeScalar("Z").value
    var indexs = (idx.map { String(UnicodeScalar($0)!) })
    indexs.append("#")

    return indexs
  }
}

// MARK: - NEContactListener

extension ContactViewModel: NEContactListener {
  /// 好友信息缓存更新（包含好友信息和用户信息）
  /// - Parameter changeType: 操作类型
  /// - Parameter contacts: 好友列表
  open func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    guard contactSections.count > 1 else {
      return
    }

    var needRefresh = false
    for contact in contacts {
      if let accid = contact.user?.accountId,
         NEFriendUserCache.shared.isFriend(accid),
         !NEFriendUserCache.shared.isBlockAccount(accid) {
        needRefresh = true
        break
      }
    }

    if needRefresh {
      loadData { [weak self] _, _ in
        self?.delegate?.reloadTableView()
      }
    }
  }

  /// 从通讯录中移除
  /// - Parameter accountId: 好友 Id
  open func removeFromContacts(_ accountId: String) {
    for (index, section) in contactSections.enumerated() {
      for (i, contact) in section.contacts.enumerated() {
        if contact.user?.user?.accountId == accountId {
          section.contacts.remove(at: i)

          // 该分组无好友后要删除该分组
          if section.contacts.isEmpty {
            contactSections.remove(at: index)
          }
          delegate?.reloadTableView()
          return
        }
      }
    }
  }

  /// 好友添加回调
  /// - Parameter friendInfo: 好友信息
  open func onFriendAdded(_ friendInfo: V2NIMFriend) {
    loadData { [weak self] _, _ in
      self?.delegate?.reloadTableView()
    }
  }

  /// 删除好友通知
  /// 本端删除好友，多端同步
  /// - Parameters:
  ///   - accountId: 删除的好友账号ID
  ///   - deletionType: 好友删除的类型
  open func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    if NEFriendUserCache.shared.isBlockAccount(accountId) {
      return
    }

    removeFromContacts(accountId)
  }

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  open func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    getValidationMessage(nil)
  }

  /// 好友添加申请被拒绝回调
  /// - Parameter rejectionInfo: 申请添加好友拒绝信息
  open func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    getValidationMessage(nil)
  }

  /// 黑名单添加回调
  /// - Parameter user: 用户信息
  open func onBlockListAdded(_ user: V2NIMUser) {
    guard let accountId = user.accountId else { return }
    removeFromContacts(accountId)
  }

  /// 黑名单移除回调
  /// - Parameter accountId: 用户 Id
  open func onBlockListRemoved(_ accountId: String) {
    NEFriendUserCache.shared.removeBlockAccount(accountId)
    if NEFriendUserCache.shared.isFriend(accountId) {
      loadData { [weak self] _, _ in
        self?.delegate?.reloadTableView()
      }
    }
  }
}

// MARK: - NETeamListener

/// 入群操作回调
/// - Parameter joinActionInfo： 群信息
extension ContactViewModel: NETeamListener {
  public func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo) {
    getValidationMessage(nil)
  }
}

// MARK: - NEEventListener

extension ContactViewModel: NESubscribeListener {
  /// 订阅在线状态
  open func subscribeOnlineStatus() {
    var subscribeList: [String] = []
    for section in contactSections {
      for contact in section.contacts {
        if let accountId = contact.user?.user?.accountId {
          if let event = NESubscribeManager.shared.getSubscribeStatus(accountId) {
            onlineStatusDic[accountId] = event.statusType == .USER_STATUS_TYPE_LOGIN
          } else {
            subscribeList.append(accountId)
          }
        }
      }
    }

    if !subscribeList.isEmpty {
      NESubscribeManager.shared.subscribeUsersOnlineState(subscribeList) { error in
      }
    }
  }

  /// 取消订阅
  open func unsubscribeOnlineStatus() {
    var subscribeList: [String] = []
    for section in contactSections {
      for contact in section.contacts {
        if let accountId = contact.user?.user?.accountId {
          subscribeList.append(accountId)
        }
      }
    }

    NESubscribeManager.shared.unSubscribeUsersOnlineState(subscribeList) { error in
    }
  }

  /// 用户状态变更
  /// - Parameter data: 用户状态列表
  public func onUserStatusChanged(_ data: [V2NIMUserStatus]) {
    var needRefresh = false
    for d in data {
      if NEFriendUserCache.shared.isFriend(d.accountId) {
        onlineStatusDic[d.accountId] = d.statusType == .USER_STATUS_TYPE_LOGIN
        needRefresh = true
        break
      }
    }

    if needRefresh {
      delegate?.reloadTableView()
    }
  }
}
