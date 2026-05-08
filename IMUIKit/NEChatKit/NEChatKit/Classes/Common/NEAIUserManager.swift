// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

/// 数字人配置代理
/// 用户自行配置相应的数字人
@objc
public protocol AIUserAgentProvider: NSObjectProtocol {
  //// 注册AI划词的AI 数字人
  /// (客户配置)
  func getAISearchUser(_ users: [V2NIMAIUser]) -> V2NIMAIUser?

  /// 注册翻译的AI数字人
  /// (客户配置)
  /// langs 传枚举
  func getAITranslateUser(_ users: [V2NIMAIUser]) -> V2NIMAIUser?

  /// 注册AI翻译的目标语言
  /// (客户配置)
  @objc optional func getAITranslateLangs(_ users: [V2NIMAIUser]) -> [String]
}

/// 数字人信息代理
@objc
public protocol AIUserChangeListener: NSObjectProtocol {
  /// 数字人信息变更回调
  /// - Parameter aiUsers: 变更的数字人列表
  func onAIUserChanged(aiUsers: [V2NIMAIUser])
}

/// 数字人信息管理器，只缓存数字人
@objcMembers
public class NEAIUserManager: NSObject {
  public static let shared = NEAIUserManager()
  private let repo = AIRepo.shared
  private weak var aiUserProvider: AIUserAgentProvider?
  private let aiUserChangeListeners = MultiDelegate<AIUserChangeListener>(strongReferences: false)

  // 数字人信息列表
  private var aiUserCache: [String: V2NIMAIUser]?

  // 是否默认置顶,1置顶，0不置顶
  private let pinDefaultKey = "pinDefault"

  // 是否ai聊,1是，0否
  private let aiChatKey = "aiChat"

  // 欢迎语
  private let welcomeTextKey = "welcomeText"

  override private init() {
    super.init()
    IMKitClient.instance.addLoginListener(self)
  }

  /// 添加监听
  /// - Parameter listener: listener
  open func addAIUserChangeListener(listener: AIUserChangeListener) {
    aiUserChangeListeners.addDelegate(listener)
    if let aiUserCache = aiUserCache {
      let aiUsers = aiUserCache.values.compactMap { $0 }
      listener.onAIUserChanged(aiUsers: aiUsers)
    }
  }

  /// 移除监听
  /// - Parameter listener: listener
  open func removeAIUserChangeListener(listener: AIUserChangeListener) {
    aiUserChangeListeners.removeDelegate(listener)
  }

  /// 设置Provider
  open func setProvider(provider: AIUserAgentProvider) {
    aiUserProvider = provider
  }

  open func isAIUserListEmpty() -> Bool {
    aiUserCache?.isEmpty ?? true
  }

  /// 拉取AI用户信息，并缓存
  open func getAIUserList() {
    DispatchQueue.global().async { [weak self] in
      guard let self = self else { return }
      self.repo.getAIUserList { aiUsers, error in
        if let err = error {
          NEALog.errorLog(NEAIUserManager.className(), desc: #function + " err: \(err.localizedDescription)")
        } else {
          self.aiUserCache = [:]
          for aiUser in aiUsers ?? [] {
            guard let accid = aiUser.accountId else { return }
            self.aiUserCache?[accid] = aiUser
          }

          DispatchQueue.main.async {
            self.aiUserChangeListeners |> {
              $0.onAIUserChanged(aiUsers: aiUsers ?? [])
            }
          }
        }
      }
    }
  }

  open func getAIUserById(_ accountId: String) -> V2NIMAIUser? {
    aiUserCache?[accountId]
  }

  open func getNEUserById(_ accountId: String) -> NEUserWithFriend? {
    if let user = aiUserCache?[accountId] {
      return NEUserWithFriend(user: user)
    }
    return nil
  }

  /// 获取AI聊功能的数字人
  open func getAIChatUserList() -> [V2NIMAIUser] {
    aiUserCache?.values.filter { isAIChatUser(aiUser: $0) } ?? []
  }

  /// 是否是AI聊用户
  func isAIChatUser(aiUser: V2NIMAIUser) -> Bool {
    if let serverExt = aiUser.serverExtension,
       let extDic = NECommonUtil.getDictionaryFromJSONString(serverExt) {
      return extDic[aiChatKey] as? Int == 1
    }
    return false
  }

  /// 根据accId判断是否是AI聊用户
  open func isAIChatUser(account: String) -> Bool {
    guard let aiUser = aiUserCache?[account] else { return false }
    return isAIChatUser(aiUser: aiUser)
  }

  /// 获取所有AI用户
  open func getAllAIUsers() -> [V2NIMAIUser] {
    aiUserCache?.values.compactMap { $0 } ?? []
  }

  /// 是否是AI数字人
  open func isAIUser(_ account: String) -> Bool {
    aiUserCache?[account] != nil
  }

  /// 获取默认置顶的AI用户
  open func getPinDefaultUserList() -> [V2NIMAIUser] {
    aiUserCache?.values.filter { isPinDefault($0) } ?? []
  }

  /// 是否默认置顶
  open func isPinDefault(_ aiUser: V2NIMAIUser) -> Bool {
    if let serverExt = aiUser.serverExtension, let extDic = NECommonUtil.getDictionaryFromJSONString(serverExt) {
      return extDic[pinDefaultKey] as? Int == 1
    }
    return false
  }

  /// 获取欢迎语
  open func getWelcomeText(_ userId: String) -> String? {
    guard let aiUser = aiUserCache?[userId] else { return nil }
    if let serverExt = aiUser.serverExtension, let extDic = NECommonUtil.getDictionaryFromJSONString(serverExt) {
      if let welcomeText = extDic[welcomeTextKey] as? String {
        return welcomeText
      }
    }
    return nil
  }

  /// 获取划词搜索机器人
  open func getAISearchUser() -> V2NIMAIUser? {
    aiUserProvider?.getAISearchUser(getAllAIUsers())
  }

  /// 获取翻译机器人
  open func getAITranslateUser() -> V2NIMAIUser? {
    aiUserProvider?.getAITranslateUser(getAllAIUsers())
  }

  /// 获取翻译的目标语言
  open func getAITranslateLanguages() -> [String] {
    if let languages = aiUserProvider?.getAITranslateLangs?(getAllAIUsers()) {
      return languages
    }
    return ["英语", "日语", "韩语", "俄语", "法语", "德语"]
  }

  /// 获取翻译 prompt key
  open func getTranslatePromptKey() -> String {
    "Language"
  }

  /// 取值范围(0,2)，用于控制随机性和多样性的程度,  默认0.2
  open func getTranslateTemperature() -> CGFloat {
    0.2
  }

  open func getShowName(_ accountId: String) -> String? {
    aiUserCache?[accountId]?.showName()
  }
}

// MARK: - NEIMKitClientListener

extension NEAIUserManager: NEIMKitClientListener {
  /// 数据同步回调
  /// - Parameters:
  ///   - type: 同步的数据类型
  ///   - state: 同步状态
  ///   - error: 错误信息
  open func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    if type == .DATA_SYNC_TYPE_MAIN, state == .DATA_SYNC_STATE_COMPLETED {
      if IMKitConfigCenter.shared.enableAIUser {
        getAIUserList()
      }
    }
  }
}
