// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class ContactViewModel: NSObject, ContactRepoSystemNotiDelegate {
  typealias RefreshBlock = () -> Void
  public var contacts: [ContactSection] = []
  public var indexs: [String]?
  private var contactHeaders: [ContactHeadItem]?
  public var contactRepo = ContactRepo.shared
  private var initalDict = [String: [ContactInfo]]()
  private let className = "ContactViewModel"

  var unreadCount = 0

  var refresh: RefreshBlock?
  init(contactHeaders: [ContactHeadItem]?) {
    super.init()
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", contactHeaders.count: \(contactHeaders?.count ?? 0)"
    )
    contactRepo.notiDelegate = self
    unreadCount = contactRepo.getNotificationUnreadCount()
    self.contactHeaders = contactHeaders
  }

  open func onNotificationUnreadCountChanged(_ count: Int) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", count: \(count)")
    print("onNotificationUnreadCountChanged : ", count)
    unreadCount = count
    if let block = refresh {
      block()
    }
  }

  open func onRecieveNotification(_ notification: NENotification) {}

  func loadData(fetch: Bool = false, _ filters: Set<String>? = nil, completion: @escaping (NSError?, Int) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    weak var weakSelf = self
    getContactList(fetch, filters) { contacts, error in
      if let users = contacts {
        NELog.infoLog("contact loadData", desc: "contact data:\(users)")
        weakSelf?.contacts = users
        weakSelf?.indexs = self.getIndexs(contactSections: users)
        if let headSection = weakSelf?.headerSection(headerItem: weakSelf?.contactHeaders) {
          weakSelf?.contacts.insert(headSection, at: 0)
        }
        completion(nil, users.count)
      }
    }
  }

  func getContactList(_ fetch: Bool = false, _ filters: Set<String>? = nil, _ completion: @escaping ([ContactSection]?, NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", filters.count: \(filters?.count ?? 0)")
    var contactList: [ContactSection] = []
    weak var weakSelf = self
    var local = false
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      local = true
    }
    contactRepo.getFriendList(fetch, local: local) { friends, error in
      if var users = friends {
        NELog.infoLog("contact bar getFriendList", desc: "friend count:\(users.count)")
        weakSelf?.initalDict = [String: [ContactInfo]]()
        if let filterUsers = filters {
          users = users.filter { user in
            if let uid = user.userId, filterUsers.contains(uid) {
              return false
            }
            return true
          }
        }

        if users.isEmpty {
          completion(contactList, nil)
          return
        }

        let digitRegular = NSPredicate(format: "SELF MATCHES %@", "[0-9]")
        let azRegular = NSPredicate(format: "SELF MATCHES %@", "[A-Z]")
        var digitList = [ContactInfo]()
        var specialCharList = [ContactInfo]()
        for contact: NEKitUser in users {
          // get inital of name
          var name = contact.alias?.isEmpty == false ? contact.alias : contact.userInfo?.nickName
          if name == nil {
            name = contact.userId
          }
          let inital = name?.initalLetter() ?? "#"
          let contactInfo = ContactInfo()
          contactInfo.user = contact
          contactInfo.headerBackColor = UIColor.colorWithString(string: contact.userId ?? "")

          if digitRegular.evaluate(with: inital) { // [0-9]
            digitList.append(contactInfo)
          } else if !azRegular.evaluate(with: inital) { // [#]
            specialCharList.append(contactInfo)
          } else { // [A-Z]
            if weakSelf?.initalDict[inital] != nil {
              weakSelf?.initalDict[inital]?.append(contactInfo)
            } else {
              weakSelf?.initalDict[inital] = [contactInfo]
            }
          }
        }

        digitList.sort { s1, s2 in
          s1.user!.showName()! < s2.user!.showName()!
        }
        specialCharList.sort { s1, s2 in
          s1.user!.showName()! < s2.user!.showName()!
        }

        guard let initalDict = weakSelf?.initalDict else {
          return
        }

        for key in initalDict.keys {
          if var value = weakSelf?.initalDict[key] {
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
        completion(result, nil)
      }
    }
  }

  func headerSection(headerItem: [ContactHeadItem]?) -> ContactSection? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", headerItem.count: \(headerItem?.count ?? 0)")
    guard let header = headerItem else {
      return nil
    }
    var infos: [ContactInfo] = []
    for item in header {
      let user = NEKitUser()
      user.alias = item.name
      let userInfo = NEKitUserInfo(nickName: "", avatar: item.imageName)
      user.userInfo = userInfo

      let info = ContactInfo()
      info.user = user
      info.contactCellType = ContactCellType.ContactOthers.rawValue
      info.router = item.router
      info.headerBackColor = item.color
      if let _ = user.userId {
        info.headerBackColor = UIColor.colorWithString(string: user.userId)
      }
      infos.append(info)
    }
    return ContactSection(initial: "", contacts: infos)
  }

  func getIndexs(contactSections: [ContactSection]?) -> [String]? {
    // 根据用户列表获取导航标签
//    NELog.infoLog(
//      ModuleName + " " + className,
//      desc: #function + ", contactSections.count: \(contactSections?.count ?? 0)"
//    )
//    guard let sections = contactSections else {
//      return nil
//    }
//    var indexs: [String] = []
//    for section in sections {
//      if section.initial.count > 0 {
//        indexs.append(section.initial)
//      }
//    }

    // ["A"..."Z", "#"]
    let idx = UnicodeScalar("A").value ... UnicodeScalar("Z").value
    var indexs = (idx.map { String(UnicodeScalar($0)!) })
    indexs.append("#")

    return indexs
  }
}
