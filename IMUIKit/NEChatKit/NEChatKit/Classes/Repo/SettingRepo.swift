// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objcMembers
public class SettingRepo: NSObject {
  public static let shared = SettingRepo()
  public let settingProvider = SettingProvider.shared

  // 最近转发的会话 id 列表 key
  private let recentForwardListKey = "recentForwardList"
  // 最近转发的会话 id 列表
  private var recentForwardList: [String]?

  // 消息推送相关配置
  private var messagePushConfig: V2NIMMessagePushConfig?

  override private init() {
    super.init()
    IMKitClient.instance.addLoginListener(self)
  }

  /// 听筒是否外放
  open func getHandsetMode() -> Bool {
    settingProvider.getHandSetMode()
  }

  /// 设置听筒模式
  open func setHandsetMode(_ value: Bool) {
    settingProvider.setHandSetMode(value)
  }

  /// 获取 已读/未读开关状态
  open func getShowReadStatus() -> Bool {
    settingProvider.getMessageRead()
  }

  /// 设置 已读/未读开关状态
  open func setShowReadStatus(_ value: Bool) {
    settingProvider.setMessageRead(value)
  }

  /// 添加设置监听
  /// - Parameter listener: 监听
  open func addSettingListener(_ listener: V2NIMSettingListener) {
    settingProvider.addSettingListener(listener)
  }

  /// 移除设置监听
  /// - Parameter listener: 监听
  open func removeSettingListener(_ listener: V2NIMSettingListener) {
    settingProvider.removeSettingListener(listener)
  }

  /// 获取会话消息免打扰状态
  /// - Parameter conversationId: 会话id
  /// - Returns: 是否处于免打扰状态
  open func getConversationMuteStatus(conversationId: String) -> Bool {
    settingProvider.getConversationMuteStatus(conversationId: conversationId)
  }

  /// 设置群组消息免打扰模式
  /// - Parameters:
  ///   - teamId: 群组Id
  ///   - teamType: 群组类型
  ///   - muteMode: 群组消息免打扰模式
  ///   - completion: 回调
  open func setTeamMessageMuteMode(teamId: String,
                                   teamType: V2NIMTeamType,
                                   muteMode: V2NIMTeamMessageMuteMode,
                                   _ completion: @escaping (NSError?) -> Void) {
    settingProvider.setTeamMessageMuteMode(teamId: teamId,
                                           teamType: teamType,
                                           muteMode: muteMode) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 获取群消息免打扰模式
  /// - Parameters:
  ///   - teamId: 群组id
  ///   - teamType: 群组类型
  /// - Returns: 免打扰模式
  open func getTeamMessageMuteMode(teamId: String,
                                   teamType: V2NIMTeamType) -> V2NIMTeamMessageMuteMode {
    settingProvider.getTeamMessageMuteMode(teamId: teamId, teamType: teamType)
  }

  /// 设置点对点消息免打扰模式
  /// - Parameters:
  ///   - accountId: 账号Id
  ///   - muteMode: 点对点消息免打扰模式
  ///   - completion: 回调
  open func setP2PMessageMuteMode(accountId: String,
                                  muteMode: V2NIMP2PMessageMuteMode,
                                  _ completion: @escaping (NSError?) -> Void) {
    settingProvider.setP2PMessageMuteMode(accountId: accountId, muteMode: muteMode) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 获取点对点消息免打扰模式
  /// - Parameter accountId: 账号id
  /// - Returns: 免打扰模式
  open func getP2PMessageMuteMode(accountId: String) -> V2NIMP2PMessageMuteMode {
    settingProvider.getP2PMessageMuteMode(accountId: accountId)
  }

  /// 获取点对点消息免打扰列表
  /// - Parameter completion: 返回V2NIMP2PMessageMuteMode状态为V2NIM_P2P_MESSAGE_MUTE_MODE_ON的用户
  open func getP2PMessageMuteList(_ completion: @escaping ([String]?) -> Void) {
    settingProvider.getP2PMessageMuteList(completion)
  }

  /// 设置当桌面端在线时，移动端是否需要推送
  /// 运行在移动端时， 需要调用该接口
  /// - Parameters:
  ///   - need: 桌面端在线时，移动端是否需要推送     true： 需要 fasle：不需要
  ///   - completion: 回调
  open func setPushMobileOnDesktopOnline(need: Bool,
                                         _ completion: @escaping (NSError?) -> Void) {
    settingProvider.setPushMobileOnDesktopOnline(need: need) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 设置Apns免打扰与详情显示
  /// - Parameter config: 免打扰与详情配置参数
  open func setDndConfig(config: V2NIMDndConfig, _ completion: @escaping (NSError?) -> Void) {
    settingProvider.setDndConfig(config: config) { error in
      completion(error?.nserror as? NSError)
    }
  }

  /// 设置新消息通知（消息免打扰）
  /// - Parameter value: 是否新消息通知（关闭消息免打扰）
  open func setMessageNotify(_ value: Bool, _ completion: @escaping (NSError?) -> Void) {
    let config = V2NIMDndConfig()
    config.dndOn = !value
    setDndConfig(config: config) { error in
      completion(error)
    }
  }

  /// 通知栏展示推送详情
  /// - Parameter value: 是否展示详情
  open func setPushShowDetail(_ value: Bool, _ completion: @escaping (NSError?) -> Void) {
    let config = V2NIMDndConfig()
    config.showDetail = value
    setDndConfig(config: config) { error in
      completion(error)
    }
  }

  /// 获取推送是否开启
  /// - Returns: 是否开启推送
  open func getPushEnable() -> Bool {
    settingProvider.getPushEnable()
  }

  /// 设置推送是否开启
  /// - Parameter open: 是否开启
  open func setPushEnable(_ open: Bool) {
    settingProvider.setPushEnable(open)
  }

  /// 是否开启推送细节
  /// - Returns 是否开启
  open func getPushDetailEnable() -> Bool {
    settingProvider.getPushDetailEnable()
  }

  /// 设置推送相关配置
  /// - Parameter messagePushConfig: 推送配置
  open func setMessagePushConfig(_ messagePushConfig: V2NIMMessagePushConfig) {
    self.messagePushConfig = messagePushConfig
  }

  /// 获取推送相关配置
  /// - Returns 推送相关配置
  open func getMessagePushConfig() -> V2NIMMessagePushConfig? {
    messagePushConfig
  }

  /// 获取最近转发的会话 id 列表，首次从 plist 中取
  /// - Returns: 会话 id 列表
  open func getRecentForward() -> [String]? {
    var recentList: [String]?

    // 首次从 plist 中取
    if recentForwardList == nil {
      if var recentForwardPath = NEPathUtils.getDirectoryForDocuments(dir: imkitDir) {
        recentForwardPath += "\(IMKitClient.instance.account())_\(recentForwardListKey).plist"
        if FileManager.default.fileExists(atPath: recentForwardPath),
           let recentList = NSArray(contentsOfFile: recentForwardPath) as? [String] {
          recentForwardList = recentList
        } else {
          recentForwardList = []
        }
      } else {
        recentForwardList = []
      }
    }

    // 取前 N 个
    if let topLimit = recentForwardList?.prefix(IMKitConfigCenter.shared.recentForwardListMaxCount) {
      recentList = Array(topLimit)
    }

    return recentList
  }

  /// 更新最近转发的会话 id 列表，同步写入 plist
  /// - Parameter recentList: 会话 id 列表
  open func updateRecentForward(_ recentList: [String]) {
    // 移除已存在的会话 id（去重）
    recentForwardList?.removeAll { recentList.contains($0) }

    // 头插法，最新的转发 id 在最前面
    recentForwardList?.insert(contentsOf: recentList, at: 0)

    // 数据持久化

    if let recentForwardList: NSArray = getRecentForward() as? NSArray,
       var recentForwardPath = NEPathUtils.getDirectoryForDocuments(dir: imkitDir) {
      recentForwardPath += "\(IMKitClient.instance.account())_\(recentForwardListKey).plist"
      recentForwardList.write(toFile: recentForwardPath, atomically: true)
    }
  }

  // 节点配置
  open func getNodeValue() -> Bool {
    settingProvider.getNodeConfig()
  }

  open func setNodeValue(_ value: Bool) {
    settingProvider.setNodeConfig(value)
  }
}

// MARK: - NEIMKitClientListener

extension SettingRepo: NEIMKitClientListener {
  ///  登录状态变更回调
  ///  - Parameter status: 登录状态
  open func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      recentForwardList = nil
    }
  }
}
