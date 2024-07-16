// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

/// 已读未读页面 - ViewModel
@objcMembers
open class ReadViewModel: NSObject {
  public let chatRepo = ChatRepo.shared
  public var readUsers = [NETeamMemberInfoModel]()
  public var unReadUsers = [NETeamMemberInfoModel]()

  override public init() {
    super.init()
  }

  /// 获取群消息已读回执状态详情
  /// - Parameters:
  ///   - message: 群消息
  ///   - teamId: 群 id
  ///   - completion: 完成回调
  public func getTeamMessageReceiptDetail(_ message: V2NIMMessage, _ teamId: String, _ completion: @escaping (Error?) -> Void) {
    chatRepo.getTeamMessageReceiptDetail(message: message, memberAccountIds: []) { [weak self] readReceiptDetail, error in
      guard let readReceiptDetail = readReceiptDetail else {
        completion(error)
        return
      }

      let group = DispatchGroup()
      if let error = error {
        completion(error)
        return
      }

      // 加载用户信息
      let loadUserIds = readReceiptDetail.readAccountList + readReceiptDetail.unreadAccountList
      group.enter()
      NETeamUserManager.shared.getTeamMembers(accountIds: loadUserIds) {
        // 已读用户
        for userId in readReceiptDetail.readAccountList {
          let memberInfo = NETeamMemberInfoModel()
          memberInfo.teamMember = NETeamUserManager.shared.getTeamMemberInfo(userId)
          memberInfo.nimUser = ChatMessageHelper.getUserFromCache(userId)
          self?.readUsers.append(memberInfo)
        }

        // 未读用户
        for userId in readReceiptDetail.unreadAccountList {
          let memberInfo = NETeamMemberInfoModel()
          memberInfo.teamMember = NETeamUserManager.shared.getTeamMemberInfo(userId)
          memberInfo.nimUser = ChatMessageHelper.getUserFromCache(userId)
          self?.unReadUsers.append(memberInfo)
        }

        group.leave()
      }

      group.notify(queue: .main) {
        completion(nil)
      }
    }
  }
}
