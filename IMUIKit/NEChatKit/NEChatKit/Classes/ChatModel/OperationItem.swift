// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public enum OperationType: Int {
  // 消息长按选项
  case copy = 1 // 复制
  case reply // 回复
  case forward // 转发
  case pin // 标记
  case removePin // 取消标记
  case multiSelect // 多选
  case collection // 收藏
  case delete // 删除
  case recall // 撤回
  case top // 置顶
  case untop // 取消置顶
  case plugin // 插件注入
  case voiceToText // 转文字
  case earpiece // 听筒
  case speaker // 扬声器

  // 搜索聊天记录选项
  case searchTeamMember // 群成员
  case searchImage // 图片
  case searchVideo // 视频
  case searchDate // 日期
  case searchFile // 文件

  // 消息翻译
  case translate // 翻译原文
  case hideTranslation // 隐藏译文
}

@objcMembers
open class OperationItem: NSObject {
  public var text: String = ""
  public var imageName: String = ""
  public var type: OperationType?
  public var image: UIImage?
  public var onClick: ((UIViewController?) -> Void)?
}
