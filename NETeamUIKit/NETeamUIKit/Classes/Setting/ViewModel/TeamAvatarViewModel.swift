//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class TeamAvatarViewModel: NSObject {
  /// 群API单例
  let teamRepo = TeamRepo.shared
  /// 当前用户群成员对象
  var currentTeamMember: V2NIMTeamMember?

  /// 获取当前用户群信息
  /// - Parameter teamId 群id
  func getCurrentUserTeamMember(_ teamId: String?, _ completion: @escaping (NSError?) -> Void) {
    if let tid = teamId {
      let currentUserAccid = IMKitClient.instance.account()
      teamRepo.getTeamMember(tid, .TEAM_TYPE_NORMAL, currentUserAccid) { member, error in
        self.currentTeamMember = member
        completion(error)
      }
    }
  }

  ///  更新群组头像
  /// - Parameter url: 群组头像Url
  /// - Parameter teamId : 群组ID
  /// - Parameter antispamConfig: 反垃圾配置
  /// - Parameter completion: 完成后的回调
  public func updateTeamAvatar(_ url: String,
                               _ teamId: String,
                               _ antispamConfig: V2NIMAntispamConfig?,
                               _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", url:\(url)")
    teamRepo.updateTeamIcon(teamId, .TEAM_TYPE_NORMAL, url) { error in
      completion(error)
    }
  }

  /// 创建文件上传任务
  ///  - Parameter filePath  文件路径
  ///  - Parameter sceneName 场景名
  public func createTask(_ filePath: String,
                         _ sceneName: String? = nil) -> V2NIMUploadFileTask {
    ResourceRepo.shared.createUploadFileTask(filePath, sceneName)
  }

  /// 上传文件
  ///   - Parameter filepath: 上传文件路径
  ///   - Parameter progress: 进度回调
  ///   - Parameter completion: 完成回调
  public func uploadImageFile(_ fileTask: V2NIMUploadFileTask,
                              _ progress: ((Float) -> Void)?,
                              _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", taskId:\(fileTask.taskId)")
    ResourceRepo.shared.upload(fileTask, progress, completion)
  }
}
