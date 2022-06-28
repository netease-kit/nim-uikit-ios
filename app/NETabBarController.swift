
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NIMSDK
import NEKitCore
import NEKitQChatUI
import NEKitCoreIM
import NEKitConversationUI
import NEKitTeamUI
import NEKitChatUI
import NEKitContactUI

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

    func setUpControllers(){
        //chat
        let chat = ConversationController()
        chat.view.backgroundColor = UIColor.init(hexString: "#e9eff5")
        chat.tabBarItem = UITabBarItem(title: "消息", image: UIImage(named: "chat"), selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal))
        let chatNav = NENavigationController(rootViewController: chat)
        
        //qchat
        let qchat = QChatHomeViewController()
        qchat.view.backgroundColor = UIColor.init(hexString: "#e9eff5")
        qchat.tabBarItem = UITabBarItem(title: "圈组", image: UIImage(named: "qchat_tabbar_icon"), selectedImage: UIImage(named: "qchat_tabbar_icon")?.withRenderingMode(.alwaysOriginal))
        let qChatNav = NENavigationController(rootViewController: qchat)
        
        
        // Contacts
        let contactVC = ContactsViewController()
        contactVC.tabBarItem = UITabBarItem(title: "通讯录", image: UIImage(named: "contact"), selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal))
        contactVC.title = "通讯录"
        let contactsNav = NENavigationController(rootViewController: contactVC)
        
        // Me
        let meVC = MeViewController()
        meVC.view.backgroundColor = UIColor.white
        meVC.tabBarItem = UITabBarItem(title: "我", image: UIImage(named: "person"), selectedImage: UIImage(named: "personSelect")?.withRenderingMode(.alwaysOriginal))
        let meNav = NENavigationController(rootViewController: meVC)

        tabBar.backgroundColor = .white
        self.viewControllers = [chatNav,qChatNav,contactsNav,meNav]
        self.selectedIndex = 0
    }
    
    func setUpSessionBadgeValue(){
        sessionUnreadCount = ConversationRepo().getMsgUnreadCount(notify: true)
        if sessionUnreadCount > 0  {
            self.tabBar.showBadgOn(index: 0)
        }else {
            self.tabBar.hideBadg(on: 0)
        }
    }
    
    func setUpContactBadgeValue() {
        contactUnreadCount = NIMSDK.shared().systemNotificationManager.allUnreadCount()
        if contactUnreadCount > 0 {
            self.tabBar.showBadgOn(index: 2)
        }else {
            self.tabBar.hideBadg(on: 2)
        }
    }
    
    private func refreshSessionBadge(){
        setUpSessionBadgeValue()
    }
    
    deinit {
        NIMSDK.shared().systemNotificationManager.remove(self)
        NIMSDK.shared().conversationManager.remove(self)
    }
}

extension NETabBarController:NIMConversationManagerDelegate {
    
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

extension NETabBarController:NIMSystemNotificationManagerDelegate {
    func onSystemNotificationCountChanged(_ unreadCount: Int) {
        contactUnreadCount = unreadCount
        setUpContactBadgeValue()
    }
}
