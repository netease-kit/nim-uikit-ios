// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license.

import UIKit

/// Geometry for one message surface. Customers can override a model's
/// `applyViewport` to measure custom content without consulting screen globals.
@objcMembers
public final class NEChatViewport: NSObject {
  public let contentWidth: CGFloat
  public let maximumBubbleWidth: CGFloat
  public let maximumTextWidth: CGFloat
  public let maximumAudioWidth: CGFloat

  public init(contentWidth: CGFloat) {
    let width = contentWidth.isFinite && contentWidth > 0 ? contentWidth : kScreenWidth
    self.contentWidth = width
    maximumBubbleWidth = max(32, width - 156)
    maximumTextWidth = max(16, maximumBubbleWidth - 2 * chat_content_margin)
    maximumAudioWidth = min(maximumBubbleWidth, width <= 325 ? 230 : 265)
    super.init()
  }
}
