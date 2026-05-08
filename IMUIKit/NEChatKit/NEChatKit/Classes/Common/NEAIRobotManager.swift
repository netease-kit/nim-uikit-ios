// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

/// AI 机器人缓存管理器（参考 NEAIUserManager）
/// 维护用户级 AI Bot 的内存缓存，随 SDK 登录完成自动拉取，
/// 各处增删改操作成功后调用对应方法同步更新缓存。
@objcMembers
public class NEAIRobotManager: NSObject {
  public static let shared = NEAIRobotManager()
  private let repo = AIRepo.shared

  /// 内存缓存：accid → V2NIMUserAIBot
  private var botCache: [String: V2NIMUserAIBot] = [:]

  /// 通过 getUserAIBot 错误码确认属于机器人体系、但无 bot 对象的 accid 集合
  private var confirmedRobotAccids: Set<String> = []

  /// 缓存是否已完成首次加载
  public private(set) var isCacheLoaded = false

  /// 是否正在拉取中（防止重复并发请求）
  private var isLoading = false

  override private init() {
    super.init()
    IMKitClient.instance.addLoginListener(self)
  }

  // MARK: - 对外只读属性

  /// 按创建时间倒序排列的机器人列表（对外只读）
  public var sortedBots: [V2NIMUserAIBot] {
    botCache.values.sorted { ($0.createTime) > ($1.createTime) }
  }

  /// 缓存中的机器人数量
  public var count: Int { botCache.count }

  // MARK: - 全量加载

  /// 全量拉取机器人列表并刷新缓存（自动分页）
  /// 若已有请求正在进行中，则跳过本次调用（防止并发重复拉取）
  /// - Parameter completion: 完成回调，nil error 表示成功
  public func loadAll(_ completion: ((NSError?) -> Void)? = nil) {
    guard !isLoading else {
      completion?(nil)
      return
    }
    isLoading = true
    fetchPage(pageToken: nil, accumulated: [], completion: { [weak self] error in
      self?.isLoading = false
      completion?(error)
    })
  }

  private func fetchPage(pageToken: String?, accumulated: [V2NIMUserAIBot], completion: ((NSError?) -> Void)?) {
    let params = V2NIMGetUserAIBotListParams()
    if let token = pageToken { params.pageToken = token }
    params.limit = 100
    repo.getUserAIBotList(params) { [weak self] result, error in
      guard let self = self else { return }
      if let error = error {
        completion?(error)
        return
      }
      let merged = accumulated + (result?.bots ?? [])
      if result?.hasMore == true, let nextToken = result?.nextToken, !nextToken.isEmpty {
        self.fetchPage(pageToken: nextToken, accumulated: merged, completion: completion)
      } else {
        // 全部拉取完毕，重置缓存
        self.botCache = [:]
        for bot in merged {
          self.botCache[bot.accid] = bot
        }
        self.isCacheLoaded = true
        completion?(nil)
      }
    }
  }

  /// 用指定列表完整替换缓存（由 ViewModel fetch 后调用）
  public func replaceAll(bots: [V2NIMUserAIBot]) {
    botCache = [:]
    for bot in bots {
      botCache[bot.accid] = bot
    }
    isCacheLoaded = true
  }

  // MARK: - 单条增删改

  /// 新建机器人后，将其加入缓存
  public func add(_ bot: V2NIMUserAIBot) {
    botCache[bot.accid] = bot
  }

  /// 更新机器人信息后，用最新 bot 覆盖缓存中对应条目
  public func update(_ bot: V2NIMUserAIBot) {
    botCache[bot.accid] = bot
  }

  /// 删除机器人后，从缓存中移除
  public func remove(accid: String) {
    botCache.removeValue(forKey: accid)
  }

  // MARK: - 查询

  /// 根据 accid 查询缓存中的机器人
  /// 若缓存从未加载过，会在后台自动触发一次全量拉取
  public func getBot(_ accid: String) -> V2NIMUserAIBot? {
    triggerLoadIfNeeded()
    return botCache[accid]
  }

  /// 判断指定 accid 是否为机器人账号（同步，从缓存读取）
  /// 若缓存从未加载过，会在后台自动触发一次全量拉取
  public func isRobot(_ accid: String) -> Bool {
    triggerLoadIfNeeded()
    return botCache[accid] != nil || confirmedRobotAccids.contains(accid)
  }

  /// 异步精确判断指定 accid 是否为机器人账号，回调在主线程执行
  ///
  /// 判断优先级：
  /// 1. 缓存命中 → 立即回调 true
  /// 2. 缓存未加载 → 先 loadAll，再用缓存判断；若仍未命中，调用 getUserAIBot 兜底
  /// 3. 缓存已加载但未命中 → 直接调用 getUserAIBot 接口，防止已删除的缓存导致误判
  public func checkIfRobot(_ accid: String, completion: @escaping (Bool) -> Void) {
    // 1. 缓存命中，直接返回
    if botCache[accid] != nil {
      DispatchQueue.main.async { completion(true) }
      return
    }

    // 2. 缓存未加载，先全量拉取再判断
    if !isCacheLoaded {
      loadAll { [weak self] _ in
        guard let self = self else {
          DispatchQueue.main.async { completion(false) }
          return
        }
        if self.botCache[accid] != nil {
          DispatchQueue.main.async { completion(true) }
        } else {
          // loadAll 完成后仍未命中，调用单个查询兜底
          self.queryRobotFromServer(accid, completion: completion)
        }
      }
      return
    }

    // 3. 缓存已加载但未命中（可能是被删除或新创建未同步），调用单个查询接口确认
    queryRobotFromServer(accid, completion: completion)
  }

  /// 服务端返回以下错误码时，仍视为机器人账号（这些错误码均表示服务端已将该账号识别为机器人体系内的账号）
  private static let robotRelatedErrorCodes: Set<Int> = [
    102_404, // ai机器人账号不存在（已删除但仍属于机器人类型）
    102_302, // ai机器人token无效
    102_309, // AI机器人账号绑定码不存在
    102_310, // AI机器人账号不属于当前用户
  ]

  /// 调用 getUserAIBot 接口查询单个机器人，命中时同步更新缓存
  private func queryRobotFromServer(_ accid: String, completion: @escaping (Bool) -> Void) {
    let params = V2NIMGetUserAIBotParams()
    params.accid = accid
    repo.getUserAIBot(params) { [weak self] bot, error in
      DispatchQueue.main.async {
        if let bot = bot {
          // 成功返回 bot 对象：更新缓存
          self?.botCache[bot.accid] = bot
          completion(true)
        } else if let nsError = error as? NSError,
                  NEAIRobotManager.robotRelatedErrorCodes.contains(nsError.code) {
          // 服务端返回机器人相关错误码：虽然未返回 bot 对象，但该账号属于机器人体系
          self?.confirmedRobotAccids.insert(accid)
          completion(true)
        } else {
          // 其他错误或无错误无 bot：确认不是机器人
          completion(false)
        }
      }
    }
  }

  /// 如果缓存从未被加载过（isCacheLoaded == false 且未在拉取中），则主动触发一次后台拉取
  private func triggerLoadIfNeeded() {
    guard !isCacheLoaded, !isLoading else { return }
    loadAll { err in
      if let err = err {
        NEALog.errorLog(NEAIRobotManager.className(), desc: "triggerLoad error: \(err.localizedDescription)")
      }
    }
  }
}

// MARK: - NEIMKitClientListener：登录主数据同步完成后自动加载缓存

extension NEAIRobotManager: NEIMKitClientListener {
  public func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    // 主数据同步完成时，自动全量加载机器人缓存
    if type == .DATA_SYNC_TYPE_MAIN, state == .DATA_SYNC_STATE_COMPLETED {
      loadAll { err in
        if let err = err {
          NEALog.errorLog(NEAIRobotManager.className(), desc: "loadAll error: \(err.localizedDescription)")
        }
      }
    }
  }

  /// 账号切换（退出登录）时清空机器人缓存，防止旧账号机器人 accid 残留
  /// 导致新账号中普通用户被误判为机器人（isRobot 返回 true）
  public func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      botCache = [:]
      confirmedRobotAccids = []
      isCacheLoaded = false
    }
  }
}
