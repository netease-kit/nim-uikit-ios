// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactKit
import NECoreKit
import NECoreIMKit
import UIKit

@objcMembers
public class ContactViewModel: NSObject, ContactRepoSystemNotiDelegate {
  typealias RefreshBlock = () -> Void
  public var contacts: [ContactSection] = []
  public var indexs: [String]?
  private var contactHeaders: [ContactHeadItem]?
  public var contactRepo = ContactRepo()
  private var initalDict: [String: [ContactInfo]] = ["#": []]
  private let className = "ContactViewModel"

  var unreadCount = 0

  var refresh: RefreshBlock?
  init(contactHeaders: [ContactHeadItem]?) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", contactHeaders.count: \(contactHeaders?.count ?? 0)"
    )
    super.init()
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", contactHeaders.count: \(contactHeaders?.count ?? 0)"
    )
    contactRepo.notiDelegate = self
    unreadCount = contactRepo.getNotificationUnreadCount()
    self.contactHeaders = contactHeaders
  }

  public func onNotificationUnreadCountChanged(_ count: Int) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", count: \(count)")
    print("onNotificationUnreadCountChanged : ", count)
    unreadCount = count
    if let block = refresh {
      block()
    }
  }

  public func onRecieveNotification(_ notification: XNotification) {}

  func loadData(_ filters: Set<String>? = nil, completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    initalDict = ["#": []]
    weak var weakSelf = self
    getContactList(filters) { contacts, error in
      if let users = contacts {
        weakSelf?.contacts = users
        weakSelf?.indexs = self.getIndexs(contactSections: users)
        if let headSection = weakSelf?.headerSection(headerItem: weakSelf?.contactHeaders) {
          weakSelf?.contacts.insert(headSection, at: 0)
        }
        completion(nil)
      }
    }
  }

  func getContactList(_ filters: Set<String>? = nil, _ completion: @escaping ([ContactSection]?, NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", filters.count: \(filters?.count ?? 0)")
    var contactList: [ContactSection] = []
    weak var weakSelf = self
    contactRepo.getFriendList { [self] friends, error in
      if var users = friends {
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
//                return contactList
        }
        for contact: User in users {
          // get inital of name
          var name = contact.alias != nil ? contact.alias : contact.userInfo?.nickName
          if name == nil {
            name = contact.userId
          }
          let inital = name?.initalLetter()
          let contactInfo = ContactInfo()
          contactInfo.user = contact
          contactInfo.headerBackColor = UIColor.colorWithString(string: contact.showName() ?? "")

          var contactsTemp = weakSelf?.initalDict[inital!]
          if contactsTemp == nil {
            contactsTemp = [contactInfo]
            weakSelf?.initalDict[inital!] = contactsTemp
          } else {
            weakSelf?.initalDict[inital!]?.append(contactInfo)
          }
        }

        for key in initalDict.keys {
          contactList.append(ContactSection(initial: key, contacts: (weakSelf?.initalDict[key]!)!))
        }

        let result = contactList.sorted { s1, s2 in
          s1.initial < s2.initial
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
      let user = User()
      user.alias = item.name
      let userInfo = UserInfo(nickName: "", avatar: item.imageName)
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
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", contactSections.count: \(contactSections?.count ?? 0)"
    )
    guard let sections = contactSections else {
      return nil
    }
    var indexs: [String] = []
    for section in sections {
      if section.initial.count > 0 {
        indexs.append(section.initial)
      }
    }
    return indexs
  }
}
