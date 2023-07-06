
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NECoreKit
import NECoreIMKit
import NEConversationUIKit
import NETeamUIKit
import NEChatUIKit
import NEContactUIKit

class NETabBarController: UITabBarController {
  private var sessionUnreadCount = 0
  private var contactUnreadCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpControllers()
    setUpSessionBadgeValue()
    setUpContactBadgeValue()
    NIMSDK.shared().conversationManager.add(self)
    NIMSDK.shared().systemNotificationManager.add(self)
  }

  func setUpControllers() {
    if NEStyleManager.instance.isNormalStyle() {
      // chat
      let chat = ConversationController()
      chat.tabBarItem = UITabBarItem(
        title: NSLocalizedString("message", comment: ""),
        image: UIImage(named: "chat"),
        selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let chatNav = NENavigationController(rootViewController: chat)

      // Contacts
      let contactVC = ContactsViewController()
      contactVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("contact", comment: ""),
        image: UIImage(named: "contact"),
        selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let contactsNav = NENavigationController(rootViewController: contactVC)

      // Me
      let meVC = MeViewController()
      meVC.view.backgroundColor = UIColor.white
      meVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("mine", comment: ""),
        image: UIImage(named: "person"),
        selectedImage: UIImage(named: "personSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let meNav = NENavigationController(rootViewController: meVC)

      tabBar.backgroundColor = .white
      viewControllers = [chatNav, contactsNav, meNav]
      selectedIndex = 0

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#337EFF")]
        tabBar.standardAppearance = appearance
      }
    } else {
      // chat
      let chat = FunConversationController()
      chat.tabBarItem = UITabBarItem(
        title: NSLocalizedString("message", comment: ""),
        image: UIImage(named: "funChat"),
        selectedImage: UIImage(named: "funChatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      setFunStyleColor(chat.tabBarItem)
      let chatNav = NENavigationController(rootViewController: chat)

      // Contacts
      let contactVC = FunContactsViewController()
      contactVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("contact", comment: ""),
        image: UIImage(named: "funContact"),
        selectedImage: UIImage(named: "funContactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      setFunStyleColor(contactVC.tabBarItem)
      let contactsNav = NENavigationController(rootViewController: contactVC)

      // Me
      let meVC = MeViewController()
      meVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("mine", comment: ""),
        image: UIImage(named: "funPerson"),
        selectedImage: UIImage(named: "funPersonSelect")?.withRenderingMode(.alwaysOriginal)
      )
      setFunStyleColor(meVC.tabBarItem)
      let meNav = NENavigationController(rootViewController: meVC)

      tabBar.backgroundColor = .white
      viewControllers = [chatNav, contactsNav, meNav]
      selectedIndex = 0

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#58BE6B")]
        tabBar.standardAppearance = appearance
      }
    }
  }

  func setUpSessionBadgeValue() {
    sessionUnreadCount = ConversationProvider.shared.allUnreadCount(notify: true)
    if sessionUnreadCount > 0 {
      tabBar.showBadgOn(index: 0, tabbarItemNums: 3)
    } else {
      tabBar.hideBadg(on: 0)
    }
  }

  func setUpContactBadgeValue() {
    contactUnreadCount = NIMSDK.shared().systemNotificationManager.allUnreadCount()
    if contactUnreadCount > 0 {
      tabBar.showBadgOn(index: 1, tabbarItemNums: 3)
    } else {
      tabBar.hideBadg(on: 1)
    }
  }

  private func refreshSessionBadge() {
    setUpSessionBadgeValue()
  }

  private func setFunStyleColor(_ item: UITabBarItem) {
    item.setTitleTextAttributes([.foregroundColor: UIColor(hexString: "#58BE6B")], for: .selected)
  }

  deinit {
    NIMSDK.shared().systemNotificationManager.remove(self)
    NIMSDK.shared().conversationManager.remove(self)
  }
}

extension NETabBarController: NIMConversationManagerDelegate {
  func didAdd(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    refreshSessionBadge()
  }

  func didUpdate(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    refreshSessionBadge()
  }

  func didRemove(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    refreshSessionBadge()
  }
}

extension NETabBarController: NIMSystemNotificationManagerDelegate {
  func onSystemNotificationCountChanged(_ unreadCount: Int) {
    contactUnreadCount = unreadCount
    setUpContactBadgeValue()
  }
}
