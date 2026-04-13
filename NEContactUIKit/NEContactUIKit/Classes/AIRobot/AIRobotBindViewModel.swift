// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class AIRobotBindViewModel: NSObject {
  /// 机器人列表（按 createTime 倒序）
  public var bots = [V2NIMUserAIBot]()

  /// 上次绑定过的 Bot accid（由外部通过扫码信息解析后传入，nil 表示首次扫码）
  public var previousBoundAccid: String?

  /// 获取机器人完整列表（自动分页拉取，按创建时间倒序）
  open func loadBots(_ completion: @escaping (NSError?) -> Void) {
    fetchPage(pageToken: nil, accumulated: [], completion: completion)
  }

  /// 递归分页拉取（用值传递代替 inout，避免跨异步闭包问题）
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
        // 全部拉取完毕，更新 Manager 缓存，按 createTime 倒序排列后更新列表
        NEAIRobotManager.shared.replaceAll(bots: merged)
        self.bots = NEAIRobotManager.shared.sortedBots
        completion(nil)
      }
    }
  }

  /// 绑定机器人到扫码结果
  /// - Parameter bot: 选中的机器人（提供 accid 与 token）
  /// - Parameter qrCode: 扫码得到的二维码 UUID（有效期 300s）
  /// - Parameter completion: 结果回调
  open func bindBot(_ bot: V2NIMUserAIBot, qrCode: String, _ completion: @escaping (NSError?) -> Void) {
    AIRepo.shared.bindUserAIBot(accid: bot.accid, token: bot.token ?? "", qrCode: qrCode) { error in
      completion(error)
    }
  }
}
