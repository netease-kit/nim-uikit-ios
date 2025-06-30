
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
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  public var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window?.backgroundColor = .white
    setupMarvel()
    setupInit() {}
    NotificationCenter.default.addObserver(self, selector: #selector(refreshRoot), name: Notification.Name("logout"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshUIStyle), name: Notification.Name(CHANGE_UI), object: nil)
    registerAPNS()
    return true
  }
  
  func setupIM(_ appkey: String? = nil) {
    // 设置IM SDK的配置项，包括AppKey，推送配置和一些全局配置等
    let option = NIMSDKOption()
    option.appKey = appkey ?? AppKey.appKey
    option.apnsCername = AppKey.apnsCername
    option.pkCername = AppKey.pkCerName
    
    // 设置IM SDK V2的配置项，包括是否使用旧的登录接口和是否使用云端会话
    let v2Option = V2NIMSDKOption()
    v2Option.enableV2CloudConversation = (UserDefaults.standard.value(forKey: keyEnableCloudConversation) as? Bool) ?? false
    
    // 初始化IM UIKit，初始化Kit层和IM SDK，将配置信息透传给IM SDK。无需再次初始化IM SDK
    IMKitClient.instance.setupIM2(option, v2Option)
  }
  
  func setupInit(_ completion: @escaping () -> Void) {
    if IMSDKConfigManager.instance.getConfig().enableCustomConfig.boolValue {
      // 开启自定义配置，使用自定义配置
//      NIMSDK.shared().serverSetting = NIMServerSetting()
      
      if IMSDKConfigManager.instance.getConfig().customJson?.count ?? 0 > 0 {
        loginWithAutoParseConfig(completion)
        return
      } else if let appkey = IMSDKConfigManager.instance.getConfig().configMap[#keyPath(NIMSDKOption.appKey)] as? String {
        setupIM(appkey)
        loginWithCustomConfig(completion)
        return
      }
    }
    
    setupIM()
    
    NEAIUserManager.shared.setProvider(provider: self)
    NEKeyboardManager.shared.enable = true
    NEKeyboardManager.shared.shouldResignOnTouchOutside = true
    
    loadService()
    
    // 群聊申请邀请功能
    IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth = true
    
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
    
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.global())
    pushRegistry.delegate = self
    pushRegistry.desiredPushTypes = [PKPushType.voIP]
  }
  
  func initializePage(_ isLoginInit: Bool = false) {
    loadService()
    let tab = NETabBarController(isLoginInit)
    self.window?.rootViewController = tab
  }
  
  // regist router
  func loadService() {
    // 注册路由
    ChatKitClient.shared.setupInit(isFun: !NEStyleManager.instance.isNormalStyle())
    if NEStyleManager.instance.isNormalStyle() == false {
      registerFunCustom()
    }else {
      registerNormalCustom()
    }
    
    // 会话列表顶部插入警告内容
    CustomConfig.shared.loadSecurityWarningView()
    
    // 加载 AI 助聊数据
    CustomConfig.shared.loadAIChatData()
    
    // 注册【个人信息】页面ss
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
      
      let count = nav?.viewControllers.count ?? 0
      nav?.pushViewController(p2pChatVC, animated: true)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { 
        if let remove = param["removeUserVC"] as? Bool, remove {
          if count > 1,
             nav?.viewControllers.last?.isKind(of: ChatViewController.self) == true {
            nav?.viewControllers.remove(at: count - 1)
          }
        }
      }))
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
      
      let count = nav?.viewControllers.count ?? 0
      nav?.pushViewController(p2pChatVC, animated: true)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { 
        if let remove = param["removeUserVC"] as? Bool, remove {
          if count > 1,
             nav?.viewControllers.last?.isKind(of: ChatViewController.self) == true {
            nav?.viewControllers.remove(at: count - 1)
          }
        }
      }))
    }
  }
  
  func loginWithAutoParseConfig(_ completion: @escaping () -> Void) {
    
    guard let json = IMSDKConfigManager.instance.getConfig().customJson else {
      loginWithUI()
      completion()
      return
    }
    
    let jsonData = json.data(using: .utf8) ?? Data()
    do {
      let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any]
      let appkey = dict?["appkey"] as? String
      setupIM(appkey)
      
      if let accountId = IMSDKConfigManager.instance.getConfig().accountId, 
          let accountIdToken = IMSDKConfigManager.instance.getConfig().accountIdToken {
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
          completion()
        }
      } else {
        loginWithUI()
        completion()
      }
    } catch let error {
      NEALog.infoLog(self.className(), desc: "login poc IM error : \(error.localizedDescription)")
      loginWithUI()
      completion()
    }
  }
  
  func loginWithCustomConfig(_ completion: @escaping () -> Void) {
    if let accountId = IMSDKConfigManager.instance.getConfig().accountId, 
        let accountIdToken = IMSDKConfigManager.instance.getConfig().accountIdToken {
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
        completion()
      }
    } else {
      loginWithUI()
      completion()
    }
  }
  
  func setupMarvel(){
#if DEBUG
    // 本地开发不上报
#else
    // 打正式包之后上报
    MarvelWrapper.initMarvel(ServerAddresses.getAppkey())
#endif
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
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // 获取 sessionId 和 type
    if let sessionId = userInfo["sessionId"] as? String,
       let sessionType = userInfo["sessionType"] as? String {
      setupInit { [weak self] in
        let tabBar = self?.window?.rootViewController as? NETabBarController
        if sessionType == "p2p" {
          let cid = V2NIMConversationIdUtil.p2pConversationId(sessionId)
          Router.shared.use(
            PushP2pChatVCRouter,
            parameters: ["nav": tabBar?.viewControllers?[tabBar?.selectedIndex ?? 0],
                         "conversationId": cid,
                         "anchor": nil],
            closure: nil
          )
        } else if sessionType == "team" {
          let cid = V2NIMConversationIdUtil.teamConversationId(sessionId)
          Router.shared.use(
            PushTeamChatVCRouter,
            parameters: ["nav": tabBar?.viewControllers?[tabBar?.selectedIndex ?? 0],
                         "conversationId": cid,
                         "anchor": nil],
            closure: nil
          )
        }
      }
    }
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

// MARK: - PKPushRegistryDelegate

extension AppDelegate: PKPushRegistryDelegate {
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    if pushCredentials.token.isEmpty {
      print("voip token isEmpty")
      return
    }
    
    NIMSDK.shared().updatePushKitToken(pushCredentials.token)
  }
  
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    // 判断是否是云信发的payload
    if payload.dictionaryPayload["nim"] == nil {
      print("not found nim payload")
      return
    }
    
    let param = NECallSystemIncomingCallParam()
    param.payload = payload.dictionaryPayload
    
    if #available(iOS 17.4, *) {
      NECallEngine.sharedInstance().reportIncomingCall(with: param) { error, callInfo in
        if let err = error {
          print("lck accept failed \(err.localizedDescription)")
        }
      } hangupCompletion: { error in
        if let err = error {
          print("lck hangup error \(err.localizedDescription)")
        }
      }
    }
    
    completion();
  }
}

// MARK: - AIUserAgentProvider

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
