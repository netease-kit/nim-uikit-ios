// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NEContactUIKit
import NEConversationUIKit
import NIMSDK
import UIKit

class NETabBarController: UITabBarController, NEConversationListener, NEContactListener {
  private var sessionUnreadCount = 0
  private var contactUnreadCount = 0

  /// 是通过切换UI风格触发，需要重置会话是否同步完成标志位，因为不是首次登录，已经同步过，同步完成回调不会再触发，正常单皮肤可忽略此逻辑
  public var isChangeUIType = false {
    didSet {}
  }

  public init(_ isChangeUI: Bool) {
    isChangeUIType = isChangeUI
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    ContactRepo.shared.addContactListener(self)
    setUpControllers()
    setUpSessionBadgeValue()
    setUpContactBadgeValue()
    ConversationRepo.shared.addConversationListener(self)

    NotificationCenter.default.addObserver(self, selector: #selector(clearValidationUnreadCount), name: NENotificationName.clearValidationUnreadCount, object: nil)
  }

  deinit {
    ConversationRepo.shared.removeConversationListener(self)
    ContactRepo.shared.removeContactListener(self)
  }

  func setUpControllers() {
    if NEStyleManager.instance.isNormalStyle() {
      // chat
      let chat = ConversationController()
      chat.viewModel.syncFinished = isChangeUIType
      chat.tabBarItem = UITabBarItem(
        title: NSLocalizedString("message", comment: ""),
        image: UIImage(named: "chat"),
        selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      chat.tabBarItem.accessibilityIdentifier = "id.conversation"
      let chatNav = NENavigationController(rootViewController: chat)

      // Contacts
      let contactVC = ContactViewController()
      contactVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("contact", comment: ""),
        image: UIImage(named: "contact"),
        selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      contactVC.tabBarItem.accessibilityIdentifier = "id.contact"
      let contactsNav = NENavigationController(rootViewController: contactVC)

      // Me
      let meVC = MeViewController()
      meVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("mine", comment: ""),
        image: UIImage(named: "person"),
        selectedImage: UIImage(named: "personSelect")?.withRenderingMode(.alwaysOriginal)
      )
      meVC.tabBarItem.accessibilityIdentifier = "id.mine"
      meVC.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
      meVC.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
      let meNav = NENavigationController(rootViewController: meVC)

      tabBar.backgroundColor = UIColor(hexString: "#F6F8FA")
      viewControllers = [chatNav, contactsNav, meNav]
      selectedIndex = 0

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hexString: "#C5C9D2")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#999999")]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#337EFF")]
        tabBar.standardAppearance = appearance
      } else {
        tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
        viewControllers?.forEach { vc in
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
        }
      }
    } else {
      // chat
      let chat = FunConversationController()
      chat.viewModel.syncFinished = isChangeUIType
      chat.tabBarItem = UITabBarItem(
        title: NSLocalizedString("message", comment: ""),
        image: UIImage(named: "funChat"),
        selectedImage: UIImage(named: "funChatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      chat.tabBarItem.accessibilityIdentifier = "id.conversation"
      let chatNav = NENavigationController(rootViewController: chat)

      // Contacts
      let contactVC = FunContactViewController()
      contactVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("contact", comment: ""),
        image: UIImage(named: "funContact"),
        selectedImage: UIImage(named: "funContactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      contactVC.tabBarItem.accessibilityIdentifier = "id.contact"
      let contactsNav = NENavigationController(rootViewController: contactVC)

      // Me
      let meVC = MeViewController()
      meVC.tabBarItem = UITabBarItem(
        title: NSLocalizedString("mine", comment: ""),
        image: UIImage(named: "funPerson"),
        selectedImage: UIImage(named: "funPersonSelect")?.withRenderingMode(.alwaysOriginal)
      )
      meVC.tabBarItem.accessibilityIdentifier = "id.mine"
      let meNav = NENavigationController(rootViewController: meVC)

      tabBar.backgroundColor = UIColor(hexString: "#F6F6F6")
      tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
      viewControllers = [chatNav, contactsNav, meNav]
      viewControllers?.forEach { vc in
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_funTheme], for: .selected)
      }
      selectedIndex = 0

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hexString: "#C5C9D2")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#999999")]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.ne_funTheme]
        tabBar.standardAppearance = appearance
      } else {
        tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
        viewControllers?.forEach { vc in
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_funTheme], for: .selected)
        }
      }
    }
  }

  func setUpSessionBadgeValue() {
    sessionUnreadCount = ConversationRepo.shared.getTotalUnreadCount()
    if sessionUnreadCount > 0 {
      tabBar.showBadgOn(index: 0, tabbarItemNums: 3)
    } else {
      tabBar.hideBadg(on: 0)
    }
  }

  func setUpContactBadgeValue() {
    ContactRepo.shared.getUnreadApplicationCount { [self] unreadCount, error in
      contactUnreadCount = unreadCount
      if unreadCount > 0 {
        tabBar.showBadgOn(index: 1, tabbarItemNums: 3)
      } else {
        tabBar.hideBadg(on: 1)
      }
    }
  }

  private func refreshSessionBadge() {
    setUpSessionBadgeValue()
  }

  @objc public func clearValidationUnreadCount() {
    setUpContactBadgeValue()
  }
}

// MARK: - V2NIMConversationListener

extension NETabBarController {
  func onConversationChanged(_ conversations: [V2NIMConversation]) {
    refreshSessionBadge()
  }

  func onConversationCreated(_ conversation: V2NIMConversation) {
    refreshSessionBadge()
  }

  func onConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
  }

  func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }
}
