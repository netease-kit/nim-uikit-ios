// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit
import UIKit

public protocol ContactViewModelDelegate: NSObjectProtocol {
  func reloadTableView()
  func reloadTableView(_ index: IndexPath)
}

@objcMembers
open class ContactViewModel: NSObject {
  typealias RefreshBlock = () -> Void
  public var contacts: [ContactSection] = []
  public var indexs: [String]?
  private var contactHeaders: ContactSection?
  public var contactRepo = ContactRepo.shared
  private var initalDict = [String: [ContactInfo]]()
  public weak var delegate: ContactViewModelDelegate?

  /// 在线状态记录
  public var onlineStatusDic = [String: NIMSubscribeEvent]()

  var unreadCount = 0 {
    didSet {
      refresh?()
    }
  }

  var refresh: RefreshBlock?
  init(contactHeaders: [ContactHeadItem]?) {
    super.init()
    NEALog.infoLog(
      ModuleName + " " + className(),
      desc: #function + ", contactHeaders.count: \(contactHeaders?.count ?? 0)"
    )

    if let headSection = headerSection(headerItem: contactHeaders) {
      self.contactHeaders = headSection
      contacts.append(headSection)
    }

    contactRepo.addContactListener(self)

    if IMKitConfigCenter.shared.onlineStatusEnable {
      EventSubscribeRepo.shared.addListener(self)
    }
  }

  deinit {
    contactRepo.removeContactListener(self)
    if IMKitConfigCenter.shared.onlineStatusEnable {
      EventSubscribeRepo.shared.removeListener(self)
    }
  }

  func loadData(_ filters: Set<String>? = nil, completion: @escaping (NSError?, Int) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
    getContactList(filters) { contacts, error in
      if let users = contacts {
        NEALog.infoLog("contact loadData", desc: "contact data:\(users)")
        weakSelf?.contacts.removeAll()
        if let contactHeaders = weakSelf?.contactHeaders {
          weakSelf?.contacts.append(contactHeaders)
        }
        weakSelf?.contacts.append(contentsOf: users)
        weakSelf?.indexs = self.getIndexs(contactSections: users)
        completion(nil, users.count)
        if IMKitConfigCenter.shared.onlineStatusEnable {
          weakSelf?.subscribeOnlineStatus()
        }
      } else {
        completion(nil, 0)
      }
    }
  }

  func getContactList(_ filters: Set<String>? = nil, _ completion: @escaping ([ContactSection]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", filters.count: \(filters?.count ?? 0)")

    // 优选从缓存中取
    if !NEFriendUserCache.shared.isEmpty() {
      let friends = NEFriendUserCache.shared.getFriendListNotInBlocklist().map(\.value)
      let contactList = formatData(friends, filters)
      completion(contactList, nil)
      return
    }

    // 缓存中没有则远端查询
    contactRepo.getContactList { [weak self] friends, error in
      NEALog.infoLog("contact bar getFriendList", desc: "friend count:\(String(describing: friends?.count))")
      let contactList = self?.formatData(friends, filters)
      completion(contactList, error)
    }
  }

  /// 数据格式化
  /// - Parameters:
  ///   - friends: 好友列表
  ///   - filters: 过滤列表
  /// - Returns: 格式化后的好友列表
  func formatData(_ friends: [NEUserWithFriend]?, _ filters: Set<String>? = nil) -> [ContactSection] {
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
        contactInfo.headerBackColor = UIColor.colorWithString(string: userFriend.user?.accountId ?? "")

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

      digitList.sort { s1, s2 in
        s1.user!.showName()! < s2.user!.showName()!
      }
      specialCharList.sort { s1, s2 in
        s1.user!.showName()! < s2.user!.showName()!
      }

      for key in initalDict.keys {
        if var value = initalDict[key] {
          value.sort { s1, s2 in
            s1.user!.showName()! < s2.user!.showName()!
          }
          contactList.append(ContactSection(initial: key, contacts: value))
        }
      }

      var result = contactList.sorted { s1, s2 in
        s1.initial < s2.initial
      }

      let specialList = digitList + specialCharList
      if specialList.count > 0 {
        result.append(ContactSection(initial: "#", contacts: specialList))
      }
      return result
    }
    return contactList
  }

  /// 返回好友列表
  /// - Returns: 不包含顶部预设数据（验证消息、黑名单、我的群聊）的好友列表
  func getFriendSections() -> [ContactSection] {
    let friendSections = contacts.filter { $0.initial != "" }
    return friendSections
  }

  func getAddApplicationUnreadCount(_ completion: ((Int, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.getUnreadApplicationCount { [weak self] count, error in
      self?.unreadCount = count
      completion?(count, error as? NSError)
    }
  }

  func headerSection(headerItem: [ContactHeadItem]?) -> ContactSection? {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", headerItem.count: \(headerItem?.count ?? 0)")
    guard let header = headerItem else {
      return nil
    }
    var infos: [ContactInfo] = []
    for item in header {
      let info = ContactInfo()
      info.user = NEUserWithFriend(alias: item.name, avatar: item.imageName)
      info.contactCellType = ContactCellType.ContactOthers.rawValue
      info.router = item.router
      info.headerBackColor = item.color
      infos.append(info)
    }
    return ContactSection(initial: "", contacts: infos)
  }

  func getIndexs(contactSections: [ContactSection]?) -> [String]? {
    // ["A"..."Z", "#"]
    let idx = UnicodeScalar("A").value ... UnicodeScalar("Z").value
    var indexs = (idx.map { String(UnicodeScalar($0)!) })
    indexs.append("#")

    return indexs
  }
}

// MARK: - NEContactListener

extension ContactViewModel: NEContactListener {
  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if let accid = contact.user?.accountId,
         !NEFriendUserCache.shared.isBlockAccount(accid) {
        loadData { [weak self] _, _ in
          self?.delegate?.reloadTableView()
        }
      }
    }
  }

  /// 从通讯录中移除
  /// - Parameter accountId: 好友 Id
  func removeFromContacts(_ accountId: String) {
    for (title, section) in contacts.enumerated() {
      for (i, contact) in section.contacts.enumerated() {
        if contact.user?.user?.accountId == accountId {
          section.contacts.remove(at: i)

          // 该分组无好友后要删除该分组
          if section.contacts.isEmpty {
            contacts.remove(at: title)
          }
          delegate?.reloadTableView()
          return
        }
      }
    }
  }

  /// 好友添加回调
  /// - Parameter friendInfo: 好友信息
  public func onFriendAdded(_ friendInfo: V2NIMFriend) {
    loadData { [weak self] _, _ in
      self?.delegate?.reloadTableView()
    }
  }

  /// 删除好友通知
  /// 本端删除好友，多端同步
  /// - Parameters:
  ///   - accountId: 删除的好友账号ID
  ///   - deletionType: 好友删除的类型
  public func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    if NEFriendUserCache.shared.isBlockAccount(accountId) {
      return
    }

    removeFromContacts(accountId)
  }

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  public func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    getAddApplicationUnreadCount(nil)
  }

  /// 好友添加申请被拒绝回调
  /// - Parameter rejectionInfo: 申请添加好友拒绝信息
  public func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    getAddApplicationUnreadCount(nil)
  }

  /// 黑名单添加回调
  /// - Parameter user: 用户信息
  public func onBlockListAdded(_ user: V2NIMUser) {
    guard let accountId = user.accountId else { return }
    removeFromContacts(accountId)
  }

  /// 黑名单移除回调
  /// - Parameter accountId: 用户 Id
  public func onBlockListRemoved(_ accountId: String) {
    NEFriendUserCache.shared.removeBlockAccount(accountId)
    if NEFriendUserCache.shared.isFriend(accountId) {
      loadData { [weak self] _, _ in
        self?.delegate?.reloadTableView()
      }
    }
  }
}

// MARK: - NEEventListener

extension ContactViewModel: NEEventListener {
  /// 订阅在线状态
  public func subscribeOnlineStatus() {
    var subscribeList: [String] = []
    for section in contacts {
      for contact in section.contacts {
        if let accountId = contact.user?.user?.accountId {
          subscribeList.append(accountId)
        }
      }
    }
    weak var weakSelf = self
    if subscribeList.count > 0 {
      NEEventSubscribeManager.shared.subscribeUsersOnlineState(subscribeList) { error in
        NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + " contact subscribeUsersOnlineState : \(error?.localizedDescription ?? "")")
      }
    }
  }

  /// 取消订阅
  public func unsubscribeOnlineStatus() {
    var subscribeList: [String] = []
    for section in contacts {
      for contact in section.contacts {
        if let accountId = contact.user?.user?.accountId {
          subscribeList.append(accountId)
        }
      }
    }
    weak var weakSelf = self
    NEEventSubscribeManager.shared.unSubscribeUsersOnlineState(subscribeList) { error in
      NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + " contact unSubscribeUsersOnlineState : \(error?.localizedDescription ?? "")")
    }
  }

  public func onRecvSubscribeEvents(_ event: [NIMSubscribeEvent]) {
    NEALog.infoLog(className(), desc: #function + " event count : \(event.count)")
    for e in event {
      print("event from : \(e.from ?? "") event value : \(e.value) event type : \(e.type)")
      if e.type == NIMSubscribeSystemEventType.online.rawValue, let acountId = e.from {
        onlineStatusDic[acountId] = e
      }
    }
    delegate?.reloadTableView()
  }
}
