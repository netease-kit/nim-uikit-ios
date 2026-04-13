// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class RobotNicknameEditController: NEBaseRobotNicknameEditController {
  override open func setupTextFieldContainerStyle() {
    // Normal 皮肤与 NEBaseContactAliasViewController 保持一致，无额外圆角
  }

  override open func saveButtonColor() -> UIColor { .normalContactThemeColor }
}
