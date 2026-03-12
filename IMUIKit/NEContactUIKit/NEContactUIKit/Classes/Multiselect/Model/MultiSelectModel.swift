
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

// 转发选择页面数据模型
@objcMembers
open class MultiSelectModel: NSObject {
  // 会话id
  public var conversationId: String?
  // 会话名称
  public var name: String?
  // 会话头像
  public var avatar: String?
  // 是否已选中
  public var isSelected = false

  // 会话人数，用于展示群人数（单聊默认为 0，群聊为群人数）
  public var memberCount: Int = 0

  // 扩展字段
  public var localExtension: [String: Any]?
}
