
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol NEAIWordSearchViewModelDelegate {
  func tableViewReload(_ isLoading: Bool)
}

@objcMembers
open class NEAIWordSearchViewModel: NSObject {
  let repo = AIRepo.shared
  public weak var delegate: NEAIWordSearchViewModelDelegate?
  public var data: [NEAIWordSearchModel] = []
  var searchTexts: [String] = []
  let aiModelTemperature: CGFloat = 0.8
  var requestIds = [String]()

  override public init() {
    super.init()
    repo.addAIListener(self)
  }

  deinit {
    repo.removeAIListener(self)
  }

  /// 获取大模型请求内容类型
  /// - Parameters:
  ///   - msg: 请求/响应的文本内容
  ///   - type: 类型
  /// - Returns: 大模型请求内容类型
  func getAIModelCallContent(_ msg: String,
                             _ type: V2NIMAIModelCallContentType) -> V2NIMAIModelCallContent {
    let content = V2NIMAIModelCallContent()
    content.msg = msg
    content.type = .NIM_AI_MODEL_CONTENT_TYPE_TEXT
    return content
  }

  /// 获取 AI 大模型配置
  /// - Parameter temperature: 控制随机性和多样性的程度
  /// - Returns: AI 大模型配置
  func getAIModelConfigParams(_ temperature: CGFloat) -> V2NIMAIModelConfigParams {
    let aiConfig = V2NIMAIModelConfigParams()
    aiConfig.temperature = temperature
    return aiConfig
  }

  /// 获取请求调用上下文内容
  /// - Returns: 请求调用上下文内容
  func getAIMessages() -> [V2NIMAIModelCallMessage]? {
    var aiMessages = [V2NIMAIModelCallMessage]()
    for (i, text) in searchTexts.enumerated() {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[AISearch], message text\(i + 1): \(String(describing: text))")
      let message = V2NIMAIModelCallMessage()
      message.msg = text
      message.role = .NIM_AI_MODEL_ROLE_TYPE_USER
      message.type = .NIM_AI_MODEL_CONTENT_TYPE_TEXT
      aiMessages.append(message)
    }
    return aiMessages.isEmpty ? nil : aiMessages
  }

  /// 获取 Al 数字人请求参数
  /// - Parameters:
  ///   - accid: 机器人账号ID
  ///   - requestId: 请求 id
  ///   - content: 请求大模型的内容
  ///   - modelConfigParams: 请求接口模型相关参数配置
  /// - Returns: Al 数字人请求参数
  func getProxyAIModelCallParams(_ accid: String,
                                 _ requestId: String,
                                 _ content: V2NIMAIModelCallContent,
                                 _ modelConfigParams: V2NIMAIModelConfigParams) -> V2NIMProxyAIModelCallParams {
    let params = V2NIMProxyAIModelCallParams()
    params.accountId = accid
    params.requestId = requestId
    params.content = content
    params.modelConfigParams = modelConfigParams
    params.messages = getAIMessages()
    return params
  }

  /// 请求 AI 大模型
  /// - Parameters:
  ///   - searchText: 搜索文本
  ///   - completion: 完成回调
  func loadData(_ searchText: String?, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[AISearch], searchText: \(String(describing: searchText))")
    guard let text = searchText else {
      completion(nil)
      return
    }

    guard let aiUser = NEAIUserManager.shared.getAISearchUser() else { return }
    if let accid = aiUser.accountId {
      let requestId = UUID().uuidString
      let content = getAIModelCallContent(text, .NIM_AI_MODEL_CONTENT_TYPE_TEXT)
      let modelConfigParams = getAIModelConfigParams(aiModelTemperature)
      let params = getProxyAIModelCallParams(accid, requestId, content, modelConfigParams)

      repo.proxyAIModelCall(params) { [weak self] error in
        if let err = error {
          print("proxyAIModelCall error: \(err.localizedDescription)")
          completion(err)
        } else {
          self?.searchTexts.append(text)
          self?.requestIds.append(requestId)
        }
      }
    }
  }
}

// MARK: - V2NIMAIListener

extension NEAIWordSearchViewModel: V2NIMAIListener {
  /// 展示错误弹窗
  /// - Parameter error: 错误信息
  func getErrorText(_ data: V2NIMAIModelCallResult) -> String {
    switch data.code {
    case operationSuccess:
      return data.content.msg
    case failedOperation:
      return commonLocalizable("parameter_setting_error")
    case rateLimitExceeded:
      return commonLocalizable("rate_limit_exceeded")
    case userNotExistCode:
      return commonLocalizable("user_not_exist")
    case userBannedCode:
      return commonLocalizable("user_banned")
    case userChatBannedCode:
      return commonLocalizable("user_chat_banned")
    case noFriendCode:
      return commonLocalizable("friend_not_exist")
    case messageHitAntispam1, messageHitAntispam2:
      return commonLocalizable("message_hit_antispam")
    case teamMemberNotExist:
      return commonLocalizable("team_member_not_exist")
    case teamNormalMemberChatBanned:
      return commonLocalizable("team_normal_member_chat_banned")
    case teamMemberChatBanned:
      return commonLocalizable("team_member_chat_banned")
    case notAIAccount:
      return commonLocalizable("not_ai_account")
    case cannotBlockAIAccount:
      return commonLocalizable("cannot_blocklist_ai_account")
    case aiMessagesDisabled:
      return commonLocalizable("ai_messages_function_disabled")
    case aiMessageRequestFailed:
      return commonLocalizable("failed_request_to_the_LLM")
    default:
      return localizable("request_exception")
    }
  }

  /// AI 透传接口的响应的回调
  /// - Parameter data: 响应内容
  public func onProxyAIModelCall(_ data: V2NIMAIModelCallResult) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "[aiSearch], data: \(data.content.msg)")

    guard requestIds.contains(data.requestId) else { return }

    let showText = getErrorText(data)
    let arr = NSAttributedString(string: showText)
    let model = NEAIWordSearchModel(arr)
    self.data.insert(model, at: 0)
    requestIds.removeAll { $0 == data.requestId }

    let isLoading = !requestIds.isEmpty
    delegate?.tableViewReload(isLoading)
  }
}
