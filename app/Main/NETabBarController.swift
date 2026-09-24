// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEContactUIKit
import NEConversationUIKit
import NELocalConversationUIKit
import NIMSDK
import UIKit

class NETabBarController: UITabBarController {
  private var chat: UIViewController?
  private var contactVC: NEBaseContactViewController?
  private var meVC = MeViewController()
  private var sessionUnreadCount = 0
  private var sessionUnreadFilter: V2NIMConversationFilter?
  private var localSessionUnreadFilter: V2NIMLocalConversationFilter?
  private var contactUnreadCount = 0

  /// 是通过切换UI风格触发，需要重置会话是否同步完成标志位，因为不是首次登录，已经同步过，同步完成回调不会再触发，正常单皮肤可忽略此逻辑
  var isChangeUIType = false {
    didSet {}
  }

  init(_ isChangeUI: Bool) {
    isChangeUIType = isChangeUI
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    ContactRepo.shared.addContactListener(self)
    TeamRepo.shared.addTeamListener(self)
    setUpControllers()

    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      LocalConversationRepo.shared.addLocalConversationListener(self)
    } else {
      ConversationRepo.shared.addConversationListener(self)
    }

    setUpSessionBadgeValue()
    setUpContactBadgeValue()

    NotificationCenter.default.addObserver(self, selector: #selector(clearValidationUnreadCount), name: NENotificationName.clearValidationMessageUnreadCount, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeLanguage), name: NENotificationName.changeLanguage, object: nil)
  }

  @objc func changeLanguage() {
    chat?.tabBarItem.title = localizable("message")
    contactVC?.tabBarItem.title = localizable("contact")
    meVC.tabBarItem.title = localizable("mine")
  }

  deinit {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      if let filter = localSessionUnreadFilter {
        LocalConversationRepo.shared.unsubscribeUnreadCountByFilter(filter)
      }
      LocalConversationRepo.shared.removeLocalConversationListener(self)
    } else {
      if let filter = sessionUnreadFilter {
        ConversationRepo.shared.unsubscribeUnreadCountByFilter(filter) { _ in }
      }
      ConversationRepo.shared.removeConversationListener(self)
    }

    ContactRepo.shared.removeContactListener(self)
    TeamRepo.shared.removeTeamListener(self)
    NotificationCenter.default.removeObserver(self)
  }

  func setUpControllers() {
    // Only NormalUI remains.
    // chat
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      chat = LocalConversationController()
      (chat as? LocalConversationController)?.viewModel.syncFinished = isChangeUIType
    } else {
      chat = ConversationController()
      (chat as? ConversationController)?.viewModel.syncFinished = isChangeUIType
    }

    chat?.tabBarItem = UITabBarItem(
      title: localizable("message"),
      image: UIImage(named: "chat"),
      selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal)
    )
    chat?.tabBarItem.accessibilityIdentifier = "id.conversation"
    let chatNav = NENavigationController(rootViewController: chat!)

    // Contacts
    contactVC = ContactViewController()
    contactVC?.tabBarItem = UITabBarItem(
      title: localizable("contact"),
      image: UIImage(named: "contact"),
      selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal)
    )
    contactVC?.tabBarItem.accessibilityIdentifier = "id.contact"
    let contactsNav = NENavigationController(rootViewController: contactVC!)

    // Me
    meVC.tabBarItem = UITabBarItem(
      title: localizable("mine"),
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
  }

  func setUpSessionBadgeValue() {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      if localSessionUnreadFilter == nil {
        let filter = V2NIMLocalConversationFilter()
        filter.ignoreMuted = true
        localSessionUnreadFilter = filter
        LocalConversationRepo.shared.addUnreadCountChangeObserver(filter) { _ in }
      }
      guard let filter = localSessionUnreadFilter else {
        return
      }
      LocalConversationRepo.shared.getUnreadCountByFilter(filter) { [weak self] count, _ in
        self?.updateSessionBadge(count ?? 0)
      }
    } else {
      if sessionUnreadFilter == nil {
        let filter = V2NIMConversationFilter()
        filter.ignoreMuted = true
        sessionUnreadFilter = filter
        ConversationRepo.shared.subscribeUnreadCountByFilter(filter) { _ in }
      }
      guard let filter = sessionUnreadFilter else {
        return
      }
      ConversationRepo.shared.getUnreadCountByFilter(filter) { [weak self] count, _ in
        self?.updateSessionBadge(count ?? 0)
      }
    }
  }

  private func updateSessionBadge(_ count: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      self.sessionUnreadCount = count
      if count > 0 {
        self.tabBar.showBadgOn(index: 0, tabbarItemNums: 3)
      } else {
        self.tabBar.hideBadg(on: 0)
      }
    }
  }

  // 设置通讯录未读显示状态
  func setUpContactBadgeValue() {
    DispatchQueue.global().async { [weak self] in
      ContactRepo.shared.getUnreadApplicationCount { count, error in
        if IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth {
          let option = V2NIMTeamJoinActionInfoQueryOption()
          option.offset = 0
          option.limit = neTeamJoinActionPageLimit
          TeamRepo.shared.getTeamJoinActionInfoList(option) { result, error in
            if let actions = result?.infos {
              let unreadActions = actions.filter { $0.timestamp > neTeamJoinActionReadTime }
              self?.contactUnreadCount = count + unreadActions.count
            } else {
              self?.contactUnreadCount = count
            }

            // 显示红点
            DispatchQueue.main.async {
              if (self?.contactUnreadCount ?? 0) > 0 {
                self?.tabBar.showBadgOn(index: 1, tabbarItemNums: 3)
              } else {
                self?.tabBar.hideBadg(on: 1)
              }

              //      // 显示未读数
              //      self?.setupContactBadge(unreadCount: contactUnreadCount)
            }
          }
        }
      }
    }
  }

  // 设置通讯录显示未读数
  func setupContactBadge(unreadCount: Int) {
    if unreadCount > 0 {
      if unreadCount > 99 {
        tabBar.setServerBadge(count: "99+")
      } else {
        tabBar.setServerBadge(count: "\(unreadCount)")
      }
    } else {
      tabBar.setServerBadge(count: nil)
    }
  }

  private func refreshSessionBadge() {
    setUpSessionBadgeValue()
  }

  @objc open func clearValidationUnreadCount() {
    tabBar.hideBadg(on: 1)
  }
}

// MARK: - NEContactListener

extension NETabBarController: NEContactListener {
  func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }

  func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }
}

// MARK: - NETeamListener

extension NETabBarController: NETeamListener {
  func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo) {
    setUpContactBadgeValue()
  }
}

// MARK: - V2NIMConversationListener

extension NETabBarController: NEConversationListener {
  func onConversationChanged(_ conversations: [V2NIMConversation]) {
    refreshSessionBadge()
  }

  func onConversationCreated(_ conversation: V2NIMConversation) {
    refreshSessionBadge()
  }

  func onConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
  }

  func onUnreadCountChangedByFilter(_ filter: V2NIMConversationFilter, _ unreadCount: Int) {
    guard filter.ignoreMuted, filter.conversationGroupId == nil else {
      return
    }
    updateSessionBadge(unreadCount)
  }
}

// MARK: - NELocalConversationListener

extension NETabBarController: NELocalConversationListener {
  func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation]) {
    refreshSessionBadge()
  }

  func onLocalConversationCreated(_ conversation: V2NIMLocalConversation) {
    refreshSessionBadge()
  }

  func onLocalConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
  }

  func onLocalUnreadCountChangedByFilter(_ filter: V2NIMLocalConversationFilter, _ unreadCount: Int) {
    guard filter.ignoreMuted else {
      return
    }
    updateSessionBadge(unreadCount)
  }
}
