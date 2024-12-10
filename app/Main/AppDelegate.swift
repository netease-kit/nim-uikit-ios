
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEContactUIKit
import NECoreKit
import NIMSDK
import NECoreIM2Kit
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
        if IMSDKConfigManager.instance.getConfig().enableCustomConfig.boolValue {
            // 开启自定义配置，使用自定义配置
//            NIMSDK.shared().serverSetting = NIMServerSetting()
            
            if IMSDKConfigManager.instance.getConfig().customJson?.count ?? 0 > 0 {
                loginWithAutoParseConfig()
                return
            }else if let appkey = IMSDKConfigManager.instance.getConfig().configMap[#keyPath(NIMSDKOption.appKey)] as? String {
                let option = NIMSDKOption()
                option.v2 = true
                option.appKey = appkey
                IMKitClient.instance.setupIM(option)
                loginWithCustomConfig()
                return
            }
        }
        
        // 初始化NIMSDK
        let option = NIMSDKOption()
        option.v2 = true
        option.appKey = AppKey.appKey
        option.apnsCername = AppKey.pushCerName
        IMKitClient.instance.setupIM(option)
        
        NEAIUserManager.shared.setProvider(provider: self)
        
        loadService()
        NEKeyboardManager.shared.enable = true
        NEKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        loginWithUI()
        
    }
    
    @objc func refreshRoot(){
        print("refresh root")
        loginWithUI()
    }
    
    @objc func refreshUIStyle(){
        initializePage(true)
    }
    
    func loginWithUI(){
        weak var weakSelf = self
        let loginCtrl = NELoginViewController.init()
        loginCtrl.successLogin = {
            weakSelf?.initConfig()
            weakSelf?.initializePage()
        }
        window?.rootViewController = NENavigationController.init(rootViewController: loginCtrl)
    }
    
    func initConfig() {
        //地图组件初始化
        NEMapClient.shared().setupMapClient(withAppkey: AppKey.gaodeMapAppkey, withServerKey: AppKey.gaodeMapServerAppkey)
        
        //呼叫组件初始化
        let setupConfig = NESetupConfig(appkey: AppKey.appKey)
        NECallEngine.sharedInstance().setup(setupConfig)
        NECallEngine.sharedInstance().setTimeout(30)
        
        let uiConfig = NECallUIKitConfig()
        NERtcCallUIKit.sharedInstance().setup(with: uiConfig)
    }
    
    func initializePage(_ isLoginInit: Bool = false) {
        loadService()
        let tab = NETabBarController(isLoginInit)
        self.window?.rootViewController = tab
    }
    
    //    regist router
    func loadService() {
        ChatKitClient.shared.setupInit(isFun: !NEStyleManager.instance.isNormalStyle())
        if NEStyleManager.instance.isNormalStyle() == false {
            registerFunCustom()
        }else {
            registerNormalCustom()
        }

        Router.shared.register(MeSettingRouter) { param in
            if let nav = param["nav"] as? UINavigationController {
                let me = PersonInfoViewController()
                nav.pushViewController(me, animated: true)
            }
        }
    }
    
    
    /// 注册娱乐版自定义内容
    func registerFunCustom(){
        Router.shared.register(PushP2pChatVCRouter) { param in
            print("param:\(param)")
            let nav = param["nav"] as? UINavigationController
            guard let conversationId = param["conversationId"] as? String else {
                return
            }
            let anchor = param["anchor"] as? V2NIMMessage
            let p2pChatVC = CustomFunChatViewController(conversationId: conversationId, anchor: anchor)
            
            for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
                if vc.isKind(of: ChatViewController.self) {
                    nav?.viewControllers[i] = p2pChatVC
                    nav?.popToViewController(p2pChatVC, animated: true)
                    return
                }
            }
            
            if let remove = param["removeUserVC"] as? Bool, remove {
                nav?.viewControllers.removeLast()
            }
            
            nav?.pushViewController(p2pChatVC, animated: true)
        }
    }
    
    /// 注册通用版自定义内容
    func registerNormalCustom(){
        Router.shared.register(PushP2pChatVCRouter) { param in
            print("param:\(param)")
            let nav = param["nav"] as? UINavigationController
            guard let conversationId = param["conversationId"] as? String else {
                return
            }
            let anchor = param["anchor"] as? V2NIMMessage
            let p2pChatVC = CustomNormalChatViewController(conversationId: conversationId, anchor: anchor)
            
            for (i, vc) in (nav?.viewControllers ?? []).enumerated() {
                if vc.isKind(of: ChatViewController.self) {
                    nav?.viewControllers[i] = p2pChatVC
                    nav?.popToViewController(p2pChatVC, animated: true)
                    return
                }
            }
            if let remove = param["removeUserVC"] as? Bool, remove {
                nav?.viewControllers.removeLast()
            }
            
            nav?.pushViewController(p2pChatVC, animated: true)
        }
    }
    
    func loginWithAutoParseConfig(){
        
        guard let json = IMSDKConfigManager.instance.getConfig().customJson else {
            loginWithUI()
            return
        }
        
        let jsonData = json.data(using: .utf8) ?? Data()
        do {
            let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any]
            let option = NIMSDKOption()
            option.v2 = true
            if let appkey = dict?["appkey"] as? String {
                option.v2 = true
                option.appKey = appkey
                IMKitClient.instance.setupIM(option)
            }
            if let accountId = IMSDKConfigManager.instance.getConfig().accountId, let accountIdToken = IMSDKConfigManager.instance.getConfig().accountIdToken {
                NEAIUserManager.shared.setProvider(provider: self)
                IMKitClient.instance.login(accountId, accountIdToken, nil) { [weak self] error in
                    if let err = error {
                        NEALog.infoLog(self?.className() ?? "", desc: "login IM error : \(err.localizedDescription)")
                        UIApplication.shared.keyWindow?.makeToast(err.localizedDescription)
                        self?.loginWithUI()
                    } else {
                        NEALog.infoLog(self?.className() ?? "", desc: "login IM Success")
                        self?.initConfig()
                        self?.initializePage()
                    }
                }
            } else {
                loginWithUI()
            }
        } catch let error {
            NEALog.infoLog(self.className(), desc: "login poc IM error : \(error.localizedDescription)")
        }
    }
    
    func loginWithCustomConfig(){
        if let accountId = IMSDKConfigManager.instance.getConfig().accountId, let accountIdToken = IMSDKConfigManager.instance.getConfig().accountIdToken {
            NEAIUserManager.shared.setProvider(provider: self)
            IMKitClient.instance.login(accountId, accountIdToken, nil) { [weak self] error in
                if let err = error {
                    NEALog.infoLog(self?.className() ?? "", desc: "login IM error : \(err.localizedDescription)")
                    UIApplication.shared.keyWindow?.makeToast(err.localizedDescription)
                    self?.loginWithUI()
                } else {
                    NEALog.infoLog(self?.className() ?? "", desc: "login IM Success")
                    self?.initConfig()
                    self?.initializePage()
                }
            }
        } else {
            loginWithUI()
        }
    }
    
    func registerAPNS(){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.badge, .sound, .alert]) { grant, error in
                if grant == false {
                    DispatchQueue.main.async {
                        UIApplication.shared.keyWindow?.makeToast(localizable("open_push"))
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
        NEALog.infoLog("app delegate : ", desc: error.localizedDescription)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

extension AppDelegate: AIUserAgentProvider {
    public func getAISearchUser(_ users: [V2NIMAIUser]) -> V2NIMAIUser? {
        for user in users {
            if user.accountId == "search" {
                return user
            }
        }
        return nil
    }
    
    public func getAITranslateUser(_ users: [V2NIMAIUser]) -> V2NIMAIUser? {
        for user in users {
            if user.accountId == "translation" {
                return user
            }
        }
        return nil
    }
    
    public func getAITranslateLangs(_ users: [V2NIMAIUser]) -> [String] {
        ["英语", "日语", "韩语", "俄语", "法语", "德语"]
    }
}
