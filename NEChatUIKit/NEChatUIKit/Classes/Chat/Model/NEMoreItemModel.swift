
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public enum NEMoreActionType: NSInteger {
  case takePicture = 1
  case location
  case rtc
  case game
  case file
  case remind
  case photo
  case translate
  case other = 100
}

@objc
@objcMembers
open class NEMoreItemModel: NSObject {
  // 单元图标
  public var image: UIImage?

  // 单元名称
  public var title: String?

  // 对应的单元类型
  public var type: NEMoreActionType?

  // 代理类
  public weak var customDelegate: AnyObject?

  // 动态事件
  public var action: Selector?

  // 自定义图标
  public var customImage: UIImage?
}
