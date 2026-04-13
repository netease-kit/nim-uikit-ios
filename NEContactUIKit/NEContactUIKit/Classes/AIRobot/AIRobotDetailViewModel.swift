// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

/// 机器人名片页功能项
public enum AIRobotDetailAction: Int {
  case edit = 0
  case viewConfig
  case refreshToken
  case chat
  case delete
}

@objcMembers
open class AIRobotDetailViewModel: NSObject {
  /// 当前机器人
  public var bot: V2NIMUserAIBot?

  /// 刷新后的 Token
  public var latestToken: String?

  init(bot: V2NIMUserAIBot) {
    self.bot = bot
  }

  // MARK: - 删除机器人

  open func deleteRobot(_ completion: @escaping (NSError?) -> Void) {
    guard let accid = bot?.accid else { return }
    let params = V2NIMDeleteUserAIBotParams()
    params.accid = accid
    AIRepo.shared.deleteUserAIBot(params) { error in
      completion(error)
    }
  }

  // MARK: - 刷新 Token

  open func refreshToken(_ completion: @escaping (String?, NSError?) -> Void) {
    guard let accid = bot?.accid else { return }
    let params = V2NIMRefreshUserAIBotTokenParams()
    params.accid = accid
    AIRepo.shared.refreshUserAIBotToken(params) { [weak self] result, error in
      if let token = result?.token {
        self?.latestToken = token
        completion(token, nil)
      } else {
        completion(nil, error)
      }
    }
  }
}
