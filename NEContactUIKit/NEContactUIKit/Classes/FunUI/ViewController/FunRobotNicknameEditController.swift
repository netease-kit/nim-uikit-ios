// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class FunRobotNicknameEditController: NEBaseRobotNicknameEditController {
  override open func setupTextFieldContainerStyle() {
    // Fun 皮肤与其他 Fun 页面保持一致，无额外圆角
  }

  override open func saveButtonColor() -> UIColor { .funContactThemeColor }
}
