//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class CustomSettingCellModel: SettingCellModel {
  public var placeholder = "请填写"

  public var customInputText: String?

  /// 输入内容对应SDK配置字段的key，便于自动解析映射
  public var inputKey = ""

  override init() {
    super.init()
    rowHeight = 100
  }
}
