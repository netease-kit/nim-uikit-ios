
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import UIKit
import NECoreKit

@objcMembers
public class IMKitClient: NSObject {
  public static let instance = IMKitClient()

  public var repo = SettingRepo()
  // save loginInfo
  public var imAccid: String = ""
  public var imToken: String = ""

  // 数据埋点参数, 均在 setupCoreKitIM 中初始化
  public private(set) var appkey: String = ""
  public private(set) var imVersion: String = ""
  public private(set) var imkitVersion: String = ""

  public func setupCoreKitIM(_ option: NIMSDKOption) {
    NIMSDK.shared().register(with: option)
    setupIMConfig() // config im
    CoreKitEngine.instance.setupCoreKit() // 配置日志打印
    // 配置数据埋点参数
    appkey = option.appKey
    imVersion = NIMSDK.shared().sdkVersion()
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      imkitVersion = version
    }
    NELog.setUp()
  }

  /// IM配置
  public func setupIMConfig() {
    // 和头像上传速度相关配置
    NIMSDKConfig.shared().fcsEnable = false

    NIMSDKConfig.shared().shouldSyncStickTopSessionInfos = true
    // 此处设置为True，具体开关在每条消息体中设置
    NIMSDKConfig.shared().teamReceiptEnabled = true
    NIMSDKConfig.shared().shouldSyncUnreadCount = true
    NIMSDKConfig.shared().shouldConsiderRevokedMessageUnreadCount = true

    // 圈组消息存储本地
    NIMQChatConfig.shared().enabledMessageCache = true
  }

  /// 初始化SDK
  /// - Parameters:
  ///   - appkey: 申请的appKey
  ///   - cerName: 推送证书名
  public func register(appkey: String, cerName: String?) {
    self.appkey = appkey
    NIMSDK.shared().register(withAppID: appkey, cerName: cerName)
  }

  /// IM 登录
  /// - Parameters:
  ///   - account: 账号
  ///   - token: 令牌（在后台绑定的登录token）
  ///   - block: 回调
  public func loginIM(_ account: String, _ token: String, _ block: @escaping (Error?) -> Void) {
    imAccid = account
    imToken = token
    IMKitEngine.instance.imAccid = account
    IMKitEngine.instance.imToken = token

    NIMSDK.shared().loginManager.login(account, token: token) { error in
      if let err = error {
        block(err)
      } else {
        block(nil)
      }
    }
  }

  /// IM 登录
  /// - Parameters:
  ///   - account: 账号
  ///   - token: 令牌（在后台绑定的登录token）
  ///   - authType: authType
  ///   - loginExt: loginExt
  ///   - block: 回调
  public func loginIM(account: String, token: String, authType: Int32, loginExt: String,
                      _ block: @escaping (Error?) -> Void) {
    imAccid = account
    imToken = token
    IMKitEngine.instance.imAccid = account
    IMKitEngine.instance.imToken = token
    NIMSDK.shared().loginManager
      .login(account, token: token, authType: authType, loginExt: loginExt) { error in
        if let err = error {
          block(err)
        } else {
          block(nil)
        }
      }
  }

  /// 自动登录
  /// - Parameters:
  ///   - account: 账号
  ///   - token: 令牌 (在后台绑定的登录token)
  public func autoLogin(account: String, token: String) {
    imAccid = account
    imToken = token
    IMKitEngine.instance.imAccid = account
    IMKitEngine.instance.imToken = token
    NIMSDK.shared().loginManager.autoLogin(account, token: token)
  }

  /// 自动登录
  /// - Parameter loginData: 自动登录参数
  public func autoLogin(loginData: NIMAutoLoginData) {
    imAccid = loginData.account
    imToken = loginData.token
    IMKitEngine.instance.imAccid = loginData.account
    IMKitEngine.instance.imToken = loginData.token
    NIMSDK.shared().loginManager.autoLogin(loginData)
  }

  /// IM 登出
  public func logout(_ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().loginManager.logout(completion)
  }

  /// 圈组登录
  /// - Parameters:
  ///   - loginParam: 登录参数
  ///   - completion: 回调
  public func loginQchat(_ loginParam: QChatLoginParam,
                         completion: @escaping (Error?, QChatLoginResult?) -> Void) {
    NIMSDK.shared().qchatManager.login(loginParam.toIMParam()) { error, result in
      if let err = error {
        completion(err, nil)
      } else {
        completion(nil, QChatLoginResult(loginResult: result))
      }
    }
  }

  /// 圈组登出
  /// - Parameter completion: 回调
  public func logoutQchat(_ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatManager.logout(completion)
  }

  /// 当前是否已登录
  /// - Returns: true已登录，false未登录
  public func isLogined() -> Bool {
    NIMSDK.shared().loginManager.isLogined()
  }

  /// 是否是自己
  /// - Parameter accid: 账户id
  /// - Returns: 是否是自己
  public func isMySelf(_ accid: String?) -> Bool {
    if let aid = accid, aid == imAccid {
      return true
    }
    return false
  }

  /// 获取AppKey
  /// - Returns: 返回当前注册的AppKey
  public func getAppkey() -> String? {
    NIMSDK.shared().appKey()
  }

  /// 是否正在使用Demo AppKey
  /// - Returns: 返回是否正在使用Demo AppKey
  public func isUsingDemoAppKey() -> Bool {
    NIMSDK.shared().isUsingDemoAppKey()
  }

  /// 设置圈组选项
  /// - Parameter option: 圈组选项
  public func qchatWithOption(option: NIMQChatOption) {
    NIMSDK.shared().qchat(with: option)
  }

  /// 更新APNS Token
  /// - Parameter token: token APNS Token
  public func updateApnsToken(token: Data) -> String {
    NIMSDK.shared().updateApnsToken(token)
  }

  /// 更新APNS Token
  /// - Parameters:
  ///   - data: APNS Token
  ///   - key: 自定义本端推送内容, 设置key可对应业务服务器自定义推送文案; 传@"" 清空配置, nil 则不更改
  /// - Returns: 格式化后的APNS Token
  public func updateApnsToken(data: Data, key: String) -> String {
    NIMSDK.shared().updateApnsToken(data, customContentKey: key)
  }

  /// 更新APNS Token
  /// - Parameters:
  ///   - data: APNS Token
  ///   - key: 自定义本端推送内容, 设置key可对应业务服务器自定义推送文案; 传@"" 清空配置, nil 则不更改
  ///   - qchatKey: qchatKey 自定义圈组本端推送内容, 设置key可对应业务服务器自定义推送文案; 传@"" 清空配置, nil 则不更改
  /// - Returns: 格式化后的APNS Token
  public func updateApnsToken(data: Data, key: String, qchatKey: String) -> String {
    NIMSDK.shared()
      .updateApnsToken(data, customContentKey: key, qchatCustomContentKey: qchatKey)
  }

  /// 更新 PushKit Token(目前仅支持 PKPushTypeVoIP)
  /// - Parameter token: PushKit token
  public func updatePushKitToken(token: Data) {
    NIMSDK.shared().updatePushKitToken(token)
  }

  /// 上传日志
  /// - Parameter completion: 上传日志完成回调
  public func uploadLogs(_ completion: @escaping NIMUploadLogsHandler) {
    NIMSDK.shared().uploadLogs(completion)
  }

  /// 设置用户信息代理
  /// - Parameter delegate: 代理
  public func addDelegate(_ delegate: IUserInfoDelegate) {
    UserInfoProvider.shared.addDelegate(delegate)
  }

  /// 移除用户信息代理
  /// - Parameter delegate: 代理
  public func removeDelegate(_ delegate: IUserInfoDelegate) {
    UserInfoProvider.shared.removeDelegate(delegate)
  }

  /// 是否登录
  /// - Returns: true 已登录  false 未登录
  public func hasLogin() -> Bool {
    NIMSDK.shared().loginManager.isLogined()
  }

  /// 是否初始化
  /// - Returns: true 初始化  false 未初始化
  public func hasInit() -> Bool {
    if let appKey = NIMSDK.shared().appKey(), appKey.count > 0 {
      return true
    }
    return false
  }
}
