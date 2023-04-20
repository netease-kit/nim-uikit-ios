
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
        registerAPNS()
        return true
    }
    
        
    func setupInit(){
        
        // init
        let option = NIMSDKOption()
        option.appKey = AppKey.appKey
        option.apnsCername = AppKey.pushCerName
        IMKitClient.instance.setupCoreKitIM(option)

        NEKeyboardManager.shared.enable = true
        NEKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        // 登录IM之前先初始化 @ 消息监听mananger
        let _ = NEAtMessageManager.instance
        
        weak var weakSelf = self
        IMKitClient.instance.loginIM("<#accid#>", "<#token#>") { error in
            if let err = error {
                print("NEKitCore login error : ", err)
            }else {
                ChatRouter.setupInit()
                weakSelf?.initializePage()
            }
        }
    }
    
    @objc func refreshRoot(){
        print("refresh root")
        
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
        //TODO: service
        ContactRouter.register()
        ChatRouter.register()
        TeamRouter.register()
        ConversationRouter.register()
        
        //地图map初始化
        NEMapClient.shared().setupMapClient(withAppkey: AppKey.gaodeMapAppkey)
        
        /* 聊天面板外部扩展示例
        let item = NEMoreItemModel()
        item.customDelegate = self
        item.action = #selector(testLog)
        item.customImage = UIImage(named: "chatSelect")
        NEChatUIKitClient.instance.moreAction.append(item)
         */
        
        //呼叫组件初始化
        let option = NERtcCallOptions()
        option.apnsCerName = AppKey.pushCerName
        option.isDisableLog = true
        let uiConfig = NERtcCallUIConfig()
        uiConfig.option = option
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
    
}

