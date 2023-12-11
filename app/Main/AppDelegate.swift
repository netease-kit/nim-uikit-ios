
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEContactUIKit
import YXLogin
import NECoreKit
import NIMSDK
import NECoreIMKit
import NEConversationUIKit
import NETeamUIKit
import NEChatUIKit
import NEMapKit
import NERtcCallKit
import NERtcCallUIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public var window: UIWindow?
    
    private var tabbarCtrl = UITabBarController()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window?.backgroundColor = .white
        setupInit()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRoot), name: Notification.Name("logout"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUIStyle), name: Notification.Name(CHANGE_UI), object: nil)
        registerAPNS()
        return true
    }
    
        
    func setupInit(){
        
        // 初始化NIMSDK
        let option = NIMSDKOption()
        option.appKey = AppKey.appKey
        option.apnsCername = AppKey.pushCerName
        IMKitClient.instance.setupCoreKitIM(option)
        
        // 登录IM之前先初始化 @ 消息监听mananger
        NEAtMessageManager.setupInstance()
        
        let account = "chenyu3"
        let token = "123456"
        
        weak var weakSelf = self
        IMKitClient.instance.loginIM(account, token) { error in
            if let err = error {
                print("login error in app : ", err.localizedDescription)
            }else {
                let _ = NEAtMessageManager.instance
                ChatRouter.setupInit()
                weakSelf?.initializePage()
            }
        }
        
    }
    
    @objc func refreshRoot(){
        print("refresh root")
        //loginWithUI()
    }
    
    @objc func refreshUIStyle(){
        initializePage()
    }
    
    func registerAPNS(){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            center.requestAuthorization(options: [.badge, .sound, .alert]) { grant, error in
                if grant == false {
                    DispatchQueue.main.async {
                        UIApplication.shared.keyWindow?.makeToast(NSLocalizedString("open_push", comment: ""))
                    }
                }
            }
        } else {
            let setting = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(setting)
        }
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NIMSDK.shared().updateApnsToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NELog.infoLog("app delegate : ", desc: error.localizedDescription)
    }
    
    func initializePage() {
        self.window?.rootViewController = NETabBarController()
        loadService()
    }
    
//    regist router
    func loadService() {
        
        ContactRouter.register()
        ChatRouter.register()
        TeamRouter.register()
        ConversationRouter.register()
        if NEStyleManager.instance.isNormalStyle() == false {
            ContactRouter.registerFun()
            ChatRouter.registerFun()
            TeamRouter.registerFun()
            ConversationRouter.registerFun()
        }
        
        // 自定义示例
        customVerification()
        
        //地图map初始化
        NEMapClient.shared().setupMapClient(withAppkey: AppKey.gaodeMapAppkey)
        
        /* 聊天面板外部扩展示例
         // 新增未知类型
        let item = NEMoreItemModel()
        item.customDelegate = self
        item.action = #selector(testLog)
        item.customImage = UIImage(named: "chatSelect")
        NEChatUIKitClient.instance.moreAction.append(item)
         
         // 覆盖已有类型
         let item = NEMoreItemModel()
         item.customImage = UIImage(named: "chatSelect")
         item.type = .rtc
         item.title = "测试"
         NEChatUIKitClient.instance.moreAction.append(item)
         
         // 移除已有类型
         // 遍历 NEChatUIKitClient.instance.moreAction， 根据type 移除已有类型
         */
        
        //呼叫组件初始化
        let option = NERtcCallOptions()
        option.apnsCerName = AppKey.pushCerName
        option.isDisableLog = true
        option.supportAutoJoinWhenCalled = false
        NERtcCallKit.sharedInstance().setupAppKey(AppKey.appKey, options: option)
        let uiConfig = NECallUIKitConfig()
        uiConfig.appKey = AppKey.appKey
        uiConfig.uiConfig.showCallingSwitchCallType = option.supportAutoJoinWhenCalled
        NERtcCallKit.sharedInstance().timeOutSeconds = 30
        NERtcCallUIKit.sharedInstance().setup(with: uiConfig)
        
        Router.shared.register(MeSettingRouter) { param in
            if let nav = param["nav"] as? UINavigationController {
                let me = PersonInfoViewController()
                nav.pushViewController(me, animated: true)
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func customVerification(){
        if NEStyleManager.instance.isNormalStyle() {
            Router.shared.register(PushP2pChatVCRouter) { param in
              print("param:\(param)")
              let nav = param["nav"] as? UINavigationController
              guard let session = param["session"] as? NIMSession else {
                return
              }
              let anchor = param["anchor"] as? NIMMessage
              var p2pChatVC = P2PChatViewController(session: session, anchor: anchor)
              for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
                if vc.isKind(of: ChatViewController.self) {
                  nav?.viewControllers[i] = p2pChatVC
                  nav?.popToViewController(p2pChatVC, animated: true)
                  return
                }
              }
              nav?.pushViewController(p2pChatVC, animated: true)
            }
        } else {
            Router.shared.register(PushP2pChatVCRouter) { param in
              print("param:\(param)")
              let nav = param["nav"] as? UINavigationController
              guard let session = param["session"] as? NIMSession else {
                return
              }
              let anchor = param["anchor"] as? NIMMessage
              var p2pChatVC = FunP2PChatViewController(session: session, anchor: anchor)
              for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
                if vc.isKind(of: ChatViewController.self) {
                  nav?.viewControllers[i] = p2pChatVC
                  nav?.popToViewController(p2pChatVC, animated: true)
                  return
                }
              }
              nav?.pushViewController(p2pChatVC, animated: true)
            }
        }
    }
}

