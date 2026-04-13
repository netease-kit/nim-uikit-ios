// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class CreateAIRobotViewModel: NSObject {
  /// 机器人昵称（必填）
  public var name: String = ""

  /// 机器人 accid（自动生成，用户可修改；总长度 ≤ 32，格式 Bot_<UUID前28位>）
  public var accid: String = {
    let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    return "Bot_" + String(uuid.prefix(28))
  }()

  /// 机器人头像本地路径（可选，选图后赋值）
  public var avatarLocalPath: String?

  /// 创建成功后保存 bot 对象（用于跳转名片页）
  public var createdBot: V2NIMUserAIBot?

  /// 编辑成功后查询最新 bot，用于通知 Detail 页刷新
  open func fetchUpdatedBot(accid: String, _ completion: @escaping (V2NIMUserAIBot?) -> Void) {
    let params = V2NIMGetUserAIBotParams()
    params.accid = accid
    AIRepo.shared.getUserAIBot(params) { bot, _ in
      DispatchQueue.main.async { completion(bot) }
    }
  }

  /// 创建机器人
  /// - Parameter completion: 成功时回调，失败返回 error
  open func createRobot(_ completion: @escaping (NSError?) -> Void) {
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else {
      let error = NSError(domain: "NEContactUIKit", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: localizable("ai_robot_name") + "不能为空"])
      completion(error)
      return
    }

    if let path = avatarLocalPath, !path.isEmpty {
      weak var weakSelf = self
      let fileTask = ResourceRepo.shared.createUploadFileTask(path)
      ResourceRepo.shared.uploadFile(fileTask, nil) { url, error in
        if let error = error {
          completion(error)
          return
        }
        weakSelf?.doCreate(name: trimmedName, icon: url, completion: completion)
      }
    } else {
      doCreate(name: trimmedName, icon: nil, completion: completion)
    }
  }

  private func doCreate(name: String, icon: String?, completion: @escaping (NSError?) -> Void) {
    let params = V2NIMCreateUserAIBotParams()
    params.accid = accid
    params.name = name
    if let icon = icon, !icon.isEmpty {
      params.icon = icon
    }
    let accid = params.accid
    AIRepo.shared.createUserAIBot(params) { [weak self] token, error in
      if let error = error {
        completion(error)
        return
      }

      let queryParams = V2NIMGetUserAIBotParams()
      queryParams.accid = accid
      AIRepo.shared.getUserAIBot(queryParams) { bot, queryError in
        if let queryError = queryError {
          completion(queryError)
          return
        }
        self?.createdBot = bot
        completion(nil)
      }
    }
  }

  /// 更新机器人
  /// - Parameter accid: 被更新的机器人 accid
  /// - Parameter completion: 成功回调 nil，失败返回 error
  open func updateRobot(accid: String, _ completion: @escaping (NSError?) -> Void) {
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else {
      let error = NSError(domain: "NEContactUIKit", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: localizable("ai_robot_name") + "不能为空"])
      completion(error)
      return
    }

    if let path = avatarLocalPath, !path.isEmpty {
      weak var weakSelf = self
      let fileTask = ResourceRepo.shared.createUploadFileTask(path)
      ResourceRepo.shared.uploadFile(fileTask, nil) { url, error in
        if let error = error {
          completion(error)
          return
        }
        weakSelf?.doUpdate(accid: accid, name: trimmedName, icon: url, completion: completion)
      }
    } else {
      doUpdate(accid: accid, name: trimmedName, icon: nil, completion: completion)
    }
  }

  private func doUpdate(accid: String, name: String, icon: String?, completion: @escaping (NSError?) -> Void) {
    let params = V2NIMUpdateUserAIBotParams()
    params.accid = accid
    params.name = name
    params.icon = icon
    AIRepo.shared.updateUserAIBot(params, completion)
  }
}
