
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitContactUI
import YXLogin
import NEKitCore
import NIMSDK
import NEKitQChatUI
import NEKitCoreIM
import IQKeyboardManagerSwift
import NEKitConversationUI
import NEKitTeamUI
import NEKitChatUI

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
        CoreKitEngine.instance.setupCoreKit(option)
        

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
       
        //login action
        startLogin(account: <#imaccid#>, token: <#imToken#>)
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
                        UIApplication.shared.keyWindow?.makeToast("请到设置中开启推送功能")
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
        QChatLog.infoLog("app delegate : ", desc: error.localizedDescription)
    }
    
    func startLogin(account:String,token:String){
        weak var weakSelf = self
        CoreKitEngine.instance.login(account, token) { error in
            if let err = error {
                print("NEKitCore login error : ", err)
            }else {
                ChatRouter.setupInit()
                let param = QChatLoginParam(account,token)
                CoreKitIMEngine.instance.loginQchat(param) { error, response in
                    if let err = error {
                        print("qchatLogin failed, error : ", err)
                    }else {
                        weakSelf?.setupTabbar()
                    }
                }
            }
        }
    }
    
    
    func setupTabbar() {
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
        
        Router.shared.register(MeSetting) { param in
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

