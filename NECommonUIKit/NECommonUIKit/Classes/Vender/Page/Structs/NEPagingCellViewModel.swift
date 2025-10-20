// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

/// 滑动指示器数据模型
struct NEPagingTitleCellViewModel {
  let title: String?
  let font: UIFont
  let selectedFont: UIFont
  let textColor: UIColor
  let selectedTextColor: UIColor
  let backgroundColor: UIColor
  let selectedBackgroundColor: UIColor
  let selected: Bool
  let labelSpacing: CGFloat

  init(title: String?, selected: Bool, options: NEPagingOptions) {
    self.title = title
    font = options.font
    selectedFont = options.selectedFont
    textColor = options.textColor
    selectedTextColor = options.selectedTextColor
    backgroundColor = options.backgroundColor
    selectedBackgroundColor = options.selectedBackgroundColor
    self.selected = selected
    labelSpacing = options.menuItemLabelSpacing
  }
}
