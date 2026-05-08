//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class AIRepo: NSObject {
  public static let shared = AIRepo()

  public var aiProvider = AIProvider.shared

  /// 构造方法私有化
  override private init() {
    super.init()
  }

  /// 添加代理
  /// - Parameter listener: 代理实现实例
  open func addAIListener(_ listener: V2NIMAIListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    aiProvider.addAIListener(listener)
  }

  /// 移除代理
  /// - Parameter listener: 代理实现实例
  open func removeAIListener(_ listener: V2NIMAIListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    aiProvider.removeAIListener(listener)
  }

  /// 数字人拉取接口  返回全量的当前Appkey相关的数字人用户
  /// - Parameter completion: 结果回调
  open func getAIUserList(_ completion: @escaping ([V2NIMAIUser]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    aiProvider.getAIUserList(completion)
  }

  /// Al数字人请求代理接口
  /// - Parameter params: 接口入参
  /// - Parameter completion: 结果回调
  open func proxyAIModelCall(_ params: V2NIMProxyAIModelCallParams, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " params:\(params.description)")
    aiProvider.proxyAIModelCall(params) { error in
      completion(error)
    }
  }

  /// 停止 AI 数字人流式输出
  /// - Parameter params: 接口入参，包含 accountId 和 requestId
  /// - Parameter completion: 结果回调
  open func stopAIModelStreamCall(_ params: V2NIMAIModelStreamCallStopParams, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accountId:\(params.accountId) requestId:\(params.requestId)")
    aiProvider.stopAIModelStreamCall(params) { error in
      completion(error)
    }
  }

  // MARK: - 用户级 AI Bot 管理

  /// 创建用户级 AI Bot
  /// - Parameter params: 创建参数，accid 和 name 为必填
  /// - Parameter completion: 结果回调，成功返回包含 token 的结果，失败返回 error
  open func createUserAIBot(_ params: V2NIMCreateUserAIBotParams, _ completion: @escaping (V2NIMCreateUserAIBotResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accid:\(params.accid) name:\(params.name)")
    aiProvider.createUserAIBot(params) { result, error in
      completion(result, error)
    }
  }

  /// 分页查询用户级 AI Bot 列表
  /// - Parameter params: 分页参数，可为 nil（默认 limit=100，从第一页开始）
  /// - Parameter completion: 结果回调，成功返回 bot 列表及分页信息，失败返回 error
  open func getUserAIBotList(_ params: V2NIMGetUserAIBotListParams?, _ completion: @escaping (V2NIMGetUserAIBotListResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    aiProvider.getUserAIBotList(params) { result, error in
      completion(result, error)
    }
  }

  /// 查询单个用户级 AI Bot
  /// - Parameter params: 查询参数，accid 为必填
  /// - Parameter completion: 结果回调，成功返回 bot 完整信息，失败返回 error
  open func getUserAIBot(_ params: V2NIMGetUserAIBotParams, _ completion: @escaping (V2NIMUserAIBot?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accid:\(params.accid)")
    aiProvider.getUserAIBot(params) { result, error in
      completion(result, error)
    }
  }

  /// 更新用户级 AI Bot
  /// - Parameter params: 更新参数，accid 为必填，其余字段选填（nil 表示不更新）
  /// - Parameter completion: 结果回调
  open func updateUserAIBot(_ params: V2NIMUpdateUserAIBotParams, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accid:\(params.accid)")
    aiProvider.updateUserAIBot(params) { error in
      completion(error)
    }
  }

  /// 删除用户级 AI Bot
  /// - Parameter params: 删除参数，accid 为必填
  /// - Parameter completion: 结果回调
  open func deleteUserAIBot(_ params: V2NIMDeleteUserAIBotParams, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accid:\(params.accid)")
    aiProvider.deleteUserAIBot(params) { error in
      completion(error)
    }
  }

  /// 通过扫码绑定用户级 AI Bot
  /// - Parameter accid: Bot 的账号 ID（必填）
  /// - Parameter token: Bot 的登录 token（必填）
  /// - Parameter qrCode: 扫码得到的二维码 UUID（必填，有效期 300s）
  /// - Parameter completion: 结果回调
  open func bindUserAIBot(accid: String, token: String, qrCode: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accid:\(accid) qrCode:\(qrCode)")
    let params = V2NIMBindUserAIBotToQrCodeParams()
    params.accid = accid
    params.token = token
    params.qrCode = qrCode
    aiProvider.bindUserAIBotToQrCode(params) { error in
      completion(error)
    }
  }

  /// 刷新用户级 AI Bot 登录 Token
  /// - Parameter params: 刷新参数，accid 为必填
  /// - Parameter completion: 结果回调，成功返回包含新 token 的结果，失败返回 error
  open func refreshUserAIBotToken(_ params: V2NIMRefreshUserAIBotTokenParams, _ completion: @escaping (V2NIMRefreshUserAIBotTokenResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " accid:\(params.accid)")
    aiProvider.refreshUserAIBotToken(params) { result, error in
      completion(result, error)
    }
  }
}
