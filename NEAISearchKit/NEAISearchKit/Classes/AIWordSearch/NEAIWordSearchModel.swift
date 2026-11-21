
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit

@objcMembers
open class NEAIWordSearchModel: NSObject {
  var content: NSAttributedString?
  private(set) var height: CGFloat = 0
  /// 文案可用的最大宽度（= 当前列宽 − 左右各 20），用于换行与行高测量。
  private(set) var maxTextWidth: CGFloat = 0

  /// - Parameter maxTextWidth: 当前列内可用宽度；<= 0 时回退整窗宽度。
  ///   双栏展开时结果面板只占右列（约 558pt），不能再用整窗宽度测量。
  init(_ content: NSAttributedString?, maxTextWidth: CGFloat = 0) {
    self.content = content
    self.maxTextWidth = maxTextWidth > 0 ? maxTextWidth : NEConstant.screenWidth - 40
    super.init()
    measure()
  }

  /// 列宽变化后重新测量行高（折叠/展开、进入/离开右列）。
  func updateMaxTextWidth(_ width: CGFloat) {
    guard width > 0, abs(width - maxTextWidth) > 0.5 else { return }
    maxTextWidth = width
    measure()
  }

  private func measure() {
    let textSize = NSAttributedString.getRealLabelSize(
      content, textFont,
      CGSize(width: max(1, maxTextWidth), height: CGFloat.greatestFiniteMagnitude)
    )
    height = ceil(textSize.height)
  }
}
