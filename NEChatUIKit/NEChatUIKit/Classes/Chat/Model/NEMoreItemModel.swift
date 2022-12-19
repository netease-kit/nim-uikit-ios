//
//  NEMoreItemModel.swift
//  NEChatUIKit

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public enum NEMoreActionType: Int {
  case takePicture = 1
  case location
  case rtc
  case game
  case file
  case remind
  case other
}

public class NEMoreItemModel: NSObject {
  // 单元图标
  var image: UIImage?

  // 单元名称
  var title: String?

  // 对应的单元类型
  var type: NEMoreActionType?
}
