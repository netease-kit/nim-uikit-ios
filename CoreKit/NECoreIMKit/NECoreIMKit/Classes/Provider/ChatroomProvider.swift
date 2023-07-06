// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class ChatroomProvider: NSObject {
  public static let shared = ChatroomProvider()

  override private init() {}

  /// 添加通知对象
  /// - Parameter delegate: 通知对象
  public func addDelegate(delegate: NIMChatroomManagerDelegate) {
    NIMSDK.shared().chatroomManager.add(delegate)
  }

  /// 移除通知对象
  /// - Parameter delegate: 通知对象
  public func removeDelegate(delegate: NIMChatroomManagerDelegate) {
    NIMSDK.shared().chatroomManager.remove(delegate)
  }

  /// 进入聊天室
  /// - Parameters:
  ///   - request: 进入聊天室请求
  ///   - completion: 进入完成后的回调
  public func enterChatroom(request: NIMChatroomEnterRequest, completion: NIMChatroomEnterHandler?) {
    NIMSDK.shared().chatroomManager.enterChatroom(request, completion: completion)
  }

  /// 离开聊天室
  /// - Parameters:
  ///   - roomId: 聊天室ID
  ///   - completion: 离开聊天室的回调
  public func exitChatroom(roomId: String, completion: NIMChatroomHandler?) {
    NIMSDK.shared().chatroomManager.exitChatroom(roomId, completion: completion)
  }

  /// 更新标签
  /// - Parameters:
  ///   - tags: 标签
  ///   - completion: 请求完成回调
  public func updateTags(tags: NIMChatroomTagsUpdate, completion: NIMChatroomHandler?) {
    NIMSDK.shared().chatroomManager.updateTags(tags, completion: completion)
  }

  /// 获取聊天室成员
  /// - Parameters:
  ///   - request: 获取成员请求
  ///   - completion: 请求完成回调
  public func fetchChatroomMembers(request: NIMChatroomMemberRequest, completion: NIMChatroomMembersHandler?) {
    NIMSDK.shared().chatroomManager.fetchChatroomMembers(request, completion: completion)
  }

  /// 修改自己在聊天室内的个人信息
  /// - Parameters:
  ///   - request: 个人信息更新请求
  ///   - completion: 修改完成后的回调
  public func updateMyChatroomMemberInfo(request: NIMChatroomMemberInfoUpdateRequest, completion: NIMChatroomHandler?) {
    NIMSDK.shared().chatroomManager.updateMyChatroomMemberInfo(request, completion: completion)
  }
}
