
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NEContactUIKit
import NIMSDK
import UIKit

import NERtcCallKit
import NERtcCallUIKit
import PushKit

private let conversationGroupDefaultEnabledMigrationKey = "nim_conversation_group_default_enabled_v2"

/// Mirrors the `railWidth` passed to `NEAdaptiveShellConfiguration` in
/// `NETabBarController`. Login pages use it to stay out of the same region
/// before the adaptive shell exists.
private let neDemoTrailingRailWidth: CGFloat = 72

private final class MapFallbackViewController: UIViewController {
  private let mapType: NEMapType

  init(mapType: NEMapType) {
    self.mapType = mapType
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = mapType == .search ? "位置搜索" : "位置详情"

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.font = .systemFont(ofSize: 15)
    label.text = "当前示例构建未包含地图模块，位置相关能力已在此链路下禁用。"
    view.addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

/// Keeps the pre-login navigation stack out of Duo's trailing tool region.
/// The adaptive shell is created only after login, so login pages need the
/// same trailing budget from their host container instead of relying on the
/// shell's later layout pass.
private final class NELoginContainerViewController: UIViewController {
  private let loginNavigationController: NENavigationController

  init(rootViewController: UIViewController) {
    loginNavigationController = NENavigationController(rootViewController: rootViewController)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    addChild(loginNavigationController)
    let loginView = loginNavigationController.view!
    loginView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(loginView)
    let trailingInset = NEAdaptiveDeviceGate.isFoldableDevice ? neDemoTrailingRailWidth : 0
    NSLayoutConstraint.activate([
      loginView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      loginView.topAnchor.constraint(equalTo: view.topAnchor),
      loginView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      loginView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingInset),
    ])
    loginNavigationController.didMove(toParent: self)
  }
}

class SceneDelegate: UIResponder {
  static var window: UIWindow?
  private var voipPushRegistry: PKPushRegistry?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    if Self.window == nil {
      let window = UIWindow(windowScene: windowScene)
      Self.window = window
    }
    Self.window!.rootViewController = ViewController()
    Self.window!.makeKeyAndVisible()

    NotificationCenter.default.addObserver(self, selector: #selector(refreshRoot), name: Notification.Name("logout"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshUIStyle), name: Notification.Name(CHANGE_UI), object: nil)

    setupInit { [weak self] error in
      if let remoteNotification = connectionOptions.notificationResponse?.notification.request.content.userInfo as? [String: Any] {
        self?.pushToChat(remoteNotification)
      }
    }
  }

  // 禁用场景保存/恢复
  func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    nil
  }

  func setupIM(_ appkey: String? = nil) {
    // 设置IM SDK的配置项，包括AppKey，推送配置和一些全局配置等
    let option = NIMSDKOption()
    option.appKey = appkey ?? AppKey.appKey
    option.apnsCername = AppKey.apnsCername
    option.pkCername = AppKey.pkCerName

    // 设置IM SDK V2的配置项，包括是否使用旧的登录接口和是否使用云端会话
    let v2Option = V2NIMSDKOption()
    let userDefaults = UserDefaults.standard
    if userDefaults.object(forKey: conversationGroupDefaultEnabledMigrationKey) == nil {
      userDefaults.set(false, forKey: keyEnableCloudConversation)
      userDefaults.set(true, forKey: conversationGroupDefaultEnabledMigrationKey)
    }
    v2Option.enableV2CloudConversation = (userDefaults.value(forKey: keyEnableCloudConversation) as? Bool) ?? false

    // IM配置
    IMKitClient.instance.config.fcsEnable = false
    IMKitClient.instance.config.shouldSyncStickTopSessionInfos = true
    IMKitClient.instance.config.teamReceiptEnabled = true
    IMKitClient.instance.config.shouldSyncUnreadCount = true
    IMKitClient.instance.config.fetchAttachmentAutomaticallyAfterReceiving = true
    IMKitClient.instance.config.shouldConsiderRevokedMessageUnreadCount = true

    // 初始化IM UIKit，初始化Kit层和IM SDK，将配置信息透传给IM SDK。无需再次初始化IM SDK
    IMKitClient.instance.setupIM2(option, v2Option)
    IMKitClient.instance.addLoginListener(self)
  }

  func setupInit(_ completion: ((Error?) -> Void)?) {
    if IMPocConfigManager.instance.getConfig().enableCustomConfig.boolValue {
      // 开启自定义配置，使用自定义配置
//      NIMSDK.shared().serverSetting = NIMServerSetting()

      if IMPocConfigManager.instance.getConfig().customJson?.count ?? 0 > 0 {
        loginWithAutoParseConfig(completion)
        return
      } else if let appkey = IMPocConfigManager.instance.getConfig().configMap[#keyPath(NIMSDKOption.appKey)] as? String {
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

    // 恢复翻译配置
    let userDefaults = UserDefaults.standard
    let savedEnableTime = userDefaults.double(forKey: "autoTranslationEnableTime")
    IMKitConfigCenter.shared.autoTranslationEnableTime = savedEnableTime
    if let savedLang = userDefaults.string(forKey: "translationTargetLanguage"), !savedLang.isEmpty {
      IMKitConfigCenter.shared.translationTargetLanguage = savedLang
    }

    loginWithUI()
  }

  @objc func refreshRoot() {
    print("refresh root")
    loginWithUI()
  }

  @objc func refreshUIStyle() {
    initializePage(true)
  }

  func loginWithUI() {
    weak var weakSelf = self
    let loginCtrl = NELoginViewController()
    loginCtrl.successLogin = {
      weakSelf?.initConfig()
      weakSelf?.initializePage()
    }
    SceneDelegate.window?.rootViewController = NELoginContainerViewController(rootViewController: loginCtrl)
  }

  func initConfig() {
    // 初始化呼叫引擎和呼叫 UI。呼叫路由会在用户点击音视频入口时使用这里的单例。
    let setupConfig = NESetupConfig(appkey: AppKey.appKey)
    NECallEngine.sharedInstance().setup(setupConfig)
    NECallEngine.sharedInstance().setTimeout(30)

    let uiConfig = NECallUIKitConfig()
    NERtcCallUIKit.sharedInstance().setup(with: uiConfig)

    // PushKit 需要持有 registry，避免初始化方法返回后停止接收来电推送。
    if voipPushRegistry == nil {
      let pushRegistry = PKPushRegistry(queue: DispatchQueue.global())
      pushRegistry.delegate = self
      pushRegistry.desiredPushTypes = [PKPushType.voIP]
      voipPushRegistry = pushRegistry
    }

    // 注册呼叫路由，ChatViewController 的 CallViewRouter 入口依赖此处理器。
    Router.shared.register(CallViewRouter) { param in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        UIApplication.shared.keyWindow?.neMakeToast(commonLocalizable("network_error"), duration: 2, position: .center)
        return
      }

      let callParam = NEUICallParam()
      callParam.remoteUserAccid = param["remoteUserAccid"] as? String ?? ""
      callParam.remoteShowName = param["remoteShowName"] as? String ?? ""
      callParam.remoteAvatar = param["remoteAvatar"] as? String ?? ""
      callParam.callType = (param["type"] as? NSNumber)?.intValue == 1 ? .audio : .video
      NERtcCallUIKit.sharedInstance().call(with: callParam)
    }
  }

  func initializePage(_ isLoginInit: Bool = false) {
    loadService()
    let tab = NETabBarController(isLoginInit)
    SceneDelegate.window?.rootViewController = tab
  }

  func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace,
                   interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
                   traitCollection previousTraitCollection: UITraitCollection) {
    (SceneDelegate.window?.rootViewController as? NETabBarController)?.adaptiveShell?.refreshWindow()
  }

  // regist router
  func loadService() {
    // 注册路由
    ChatKitClient.shared.setupInit(isFun: !NEStyleManager.instance.isNormalStyle())
    DemoStickerConfig.registerPackages()
    registerMapFallbackRouter()

    // 会话列表顶部插入警告内容
    CustomConfig.shared.loadSecurityWarningView()

    // 加载 AI 助聊数据
    CustomConfig.shared.loadAIChatData()

    // 加载自定义图片选择器
    CustomConfig.shared.loadPhotoBrowser()

    // 自定义推送配置
    let pushConfig = IMPushConfigManager.instance.getConfig().config
    if pushConfig.pushEnabled {
      SettingRepo.shared.setMessagePushConfig(pushConfig)
    }

    // 发送消息前，推送配置中添加点击跳转所需参数
    // 点击通知跳转逻辑详见 pushToChat(_:)
    ChatKitClient.shared.beforeSend = { viewController, param in
      if let pushConfig = param.params?.pushConfig ?? SettingRepo.shared.getMessagePushConfig() {
        if let pushPayload = pushConfig.pushPayload,
           var pushDic = NECommonUtil.getDictionaryFromJSONString(pushPayload) as? [String: Any] {
          let sessionType = V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId)
          if sessionType == .CONVERSATION_TYPE_P2P {
            // 单聊传自己的 accountId
            pushDic["sessionId"] = IMKitClient.instance.account()
            pushDic["sessionType"] = "p2p"
          } else {
            // 群聊传 teamId
            pushDic["sessionId"] = ChatRepo.sessionId
            pushDic["sessionType"] = "team"
          }
          pushConfig.pushPayload = NECommonUtil.getJSONStringFromDictionary(pushDic)
        } else {
          var pushDic = [String: Any]()

          let sessionType = V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId)
          if sessionType == .CONVERSATION_TYPE_P2P {
            // 单聊传自己的 accountId
            pushDic["sessionId"] = IMKitClient.instance.account()
            pushDic["sessionType"] = "p2p"
          } else {
            // 群聊传 teamId
            pushDic["sessionId"] = ChatRepo.sessionId
            pushDic["sessionType"] = "team"
          }

          pushConfig.pushPayload = NECommonUtil.getJSONStringFromDictionary(pushDic)
        }
        param.params?.pushConfig = pushConfig
      }

      return param
    }

    // 注册【个人信息】页面
    Router.shared.register(MeSettingRouter) { param in
      if let nav = param["nav"] as? UINavigationController {
        let me = PersonInfoViewController()
        nav.pushViewController(me, animated: true)
      }
    }
  }

  func loginWithAutoParseConfig(_ completion: ((Error?) -> Void)?) {
    guard let json = IMPocConfigManager.instance.getConfig().customJson else {
      loginWithUI()
      completion?(nil)
      return
    }

    let jsonData = json.data(using: .utf8) ?? Data()
    do {
      let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any]
      let appkey = dict?["appkey"] as? String
      setupIM(appkey)

      if let accountId = IMPocConfigManager.instance.getConfig().accountId,
         let accountIdToken = IMPocConfigManager.instance.getConfig().accountIdToken {
        NEAIUserManager.shared.setProvider(provider: self)
        IMKitClient.instance.login(accountId, accountIdToken, nil) { [weak self] error in
          if let err = error {
            NEALog.infoLog(SceneDelegate.className(), desc: "login IM error : \(err.localizedDescription)")
            SceneDelegate.window?.neMakeToast(err.localizedDescription)
            self?.loginWithUI()
          } else {
            NEALog.infoLog(SceneDelegate.className(), desc: "login IM Success")
            self?.initConfig()
            self?.initializePage()
          }
          completion?(error)
        }
      } else {
        loginWithUI()
        completion?(nil)
      }
    } catch {
      NEALog.infoLog(className(), desc: "login poc IM error : \(error.localizedDescription)")
      loginWithUI()
      completion?(error)
    }
  }

  func loginWithCustomConfig(_ completion: ((Error?) -> Void)?) {
    if let accountId = IMPocConfigManager.instance.getConfig().accountId,
       let accountIdToken = IMPocConfigManager.instance.getConfig().accountIdToken {
      NEAIUserManager.shared.setProvider(provider: self)
      IMKitClient.instance.login(accountId, accountIdToken, nil) { [weak self] error in
        if let err = error {
          NEALog.infoLog(SceneDelegate.className(), desc: "login IM error : \(err.localizedDescription)")
          SceneDelegate.window?.neMakeToast(err.localizedDescription)
          self?.loginWithUI()
        } else {
          NEALog.infoLog(SceneDelegate.className(), desc: "login IM Success")
          self?.initConfig()
          self?.initializePage()
        }
        completion?(error)
      }
    } else {
      loginWithUI()
      completion?(nil)
    }
  }

  func registerAPNS() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.badge, .sound, .alert]) { grant, error in
      if grant == false {
        DispatchQueue.main.async {
          Self.window?.neMakeToast(localizable("open_push"))
        }
      }
    }
    UIApplication.shared.registerForRemoteNotifications()
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}

// MARK: - UIWindowSceneDelegate

extension SceneDelegate: UIWindowSceneDelegate {
  func sceneWillEnterForeground(_ scene: UIScene) {
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}

// MARK: - PKPushRegistryDelegate

extension SceneDelegate: PKPushRegistryDelegate {
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
      completion()
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

    completion()
  }
}

// MARK: - AIUserAgentProvider

extension SceneDelegate: AIUserAgentProvider {
  func getAISearchUser(_ users: [V2NIMAIUser]) -> V2NIMAIUser? {
    for user in users {
      if user.accountId == "search" {
        return user
      }
    }
    return nil
  }

  func getAITranslateUser(_ users: [V2NIMAIUser]) -> V2NIMAIUser? {
    for user in users {
      if user.accountId == "translation" {
        return user
      }
    }
    return nil
  }

  func getAITranslateLangs(_ users: [V2NIMAIUser]) -> [String] {
    ["英语", "日语", "韩语", "俄语", "法语", "德语"]
  }
}

// MARK: NEIMKitClientListener

extension SceneDelegate: NEIMKitClientListener {
  func onLoginFailed(_ error: V2NIMError) {
    if error.code == userBannedCode {
      SceneDelegate.window?.neMakeToast(localizable("account_forbidden"))
      loginWithUI()
    }
  }

  func onKickedOffline(_ detail: V2NIMKickedOfflineDetail) {
    if detail.reason == .KICKED_OFFLINE_REASON_SERVER {
      SceneDelegate.window?.neMakeToast(localizable("account_kicked_offline"))
      loginWithUI()
    }
  }

  func registerMapFallbackRouter() {
    Router.shared.register(NERouterUrl.LocationVCRouter) { param in
      guard let nav = param["nav"] as? UINavigationController else { return }
      let mapTypeValue = param["type"] as? Int ?? NEMapType.detail.rawValue
      let mapType = NEMapType(rawValue: mapTypeValue) ?? .detail
      let controller = MapFallbackViewController(mapType: mapType)
      nav.pushViewController(controller, animated: true)
    }
  }
}

extension SceneDelegate: UNUserNotificationCenterDelegate {
  // 点击通知时的统一入口
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    if let userInfo = response.notification.request.content.userInfo as? [String: Any] {
      // 解析自定义跳转参数
      pushToChat(userInfo)
    }

    completionHandler()
  }

  func pushToChat(_ userInfo: [String: Any]) {
    // 获取 sessionId 和 type
    if let sessionId = userInfo["sessionId"] as? String,
       let sessionType = userInfo["sessionType"] as? String {
      let tabBar = SceneDelegate.window?.rootViewController as? NETabBarController
      tabBar?.adaptiveShell?.selectSection(0)
      let navigation = tabBar?.adaptiveShell?.sections.first ?? tabBar?.viewControllers?[tabBar?.selectedIndex ?? 0] as? UINavigationController
      let adaptivePresentation = tabBar?.adaptiveShell != nil
      if sessionType == "p2p" {
        let cid = V2NIMConversationIdUtil.p2pConversationId(sessionId)
        if adaptivePresentation {
          Router.shared.use(
            PushP2pChatVCRouter,
            parameters: ["nav": navigation as Any, "conversationId": cid, "animated": false],
            closure: nil
          )
        } else {
          Router.shared.use(
            PushP2pChatVCRouter,
            parameters: ["nav": navigation as Any, "conversationId": cid, "animated": false, "anchor": nil],
            closure: nil
          )
        }
      } else if sessionType == "team" {
        let cid = V2NIMConversationIdUtil.teamConversationId(sessionId)
        if adaptivePresentation {
          Router.shared.use(
            PushTeamChatVCRouter,
            parameters: ["nav": navigation as Any, "conversationId": cid, "animated": false],
            closure: nil
          )
        } else {
          Router.shared.use(
            PushTeamChatVCRouter,
            parameters: ["nav": navigation as Any, "conversationId": cid, "animated": false, "anchor": nil],
            closure: nil
          )
        }
      }
    }
  }
}
