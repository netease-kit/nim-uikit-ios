// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class AIRobotViewModel: NSObject {
  /// 机器人数量上限（可在代码集成层覆写）
  public static var maxRobotCount: Int = 10

  /// 机器人列表数据源
  public var datas = [NEAIRobotModel]()

  /// 搜索结果
  public var searchDatas = [NEAIRobotModel]()

  /// 获取机器人完整列表（自动分页拉取）
  open func getRobots(_ completion: @escaping (NSError?) -> Void) {
    fetchPage(pageToken: nil, accumulated: [], completion: completion)
  }

  /// 递归分页拉取（值传递避免跨异步闭包的 inout 问题）
  private func fetchPage(pageToken: String?, accumulated: [V2NIMUserAIBot], completion: @escaping (NSError?) -> Void) {
    let params = V2NIMGetUserAIBotListParams()
    if let token = pageToken {
      params.pageToken = token
    }
    params.limit = 100

    AIRepo.shared.getUserAIBotList(params) { [weak self] result, error in
      guard let self = self else { return }
      if let error = error {
        completion(error)
        return
      }
      let merged = accumulated + (result?.bots ?? [])
      if result?.hasMore == true, let nextToken = result?.nextToken, !nextToken.isEmpty {
        // 还有更多页，继续递归拉取
        self.fetchPage(pageToken: nextToken, accumulated: merged, completion: completion)
      } else {
        // 全部拉取完毕，更新 Manager 缓存，转换为 Model 按创建时间倒序
        NEAIRobotManager.shared.replaceAll(bots: merged)
        self.datas = NEAIRobotManager.shared.sortedBots.map { bot in
          let model = NEAIRobotModel()
          model.bot = bot
          return model
        }
        completion(nil)
      }
    }
  }
}
