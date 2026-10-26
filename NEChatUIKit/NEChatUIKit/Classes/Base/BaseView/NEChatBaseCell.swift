
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class NEChatBaseCell: UITableViewCell {
  /// Per-cell presentation limits; legacy constants remain untouched.
  public var chatViewport: NEChatViewport?
  public var chat_content_maxW: CGFloat { chatViewport?.maximumBubbleWidth ?? max(32, kScreenWidth - 156) }
  public var chat_text_maxW: CGFloat { chatViewport?.maximumTextWidth ?? max(16, kScreenWidth - 172) }
  public var audio_max_width: CGFloat { chatViewport?.maximumAudioWidth ?? (kScreenWidth <= 325 ? 230 : 265) }
  public var chatContainerWidth: CGFloat { chatViewport?.contentWidth ?? kScreenWidth }
  private var viewportWidthConstraints: [(NSLayoutConstraint, CGFloat)] = []

  /// Register a content-width cap once and update it on reuse/resize.
  public func messageWidthConstraint(_ anchor: NSLayoutDimension, inset: CGFloat = 0) -> NSLayoutConstraint {
    let constraint = anchor.constraint(lessThanOrEqualToConstant: max(16, chat_content_maxW - inset))
    viewportWidthConstraints.append((constraint, inset))
    return constraint
  }

  open func applyViewport(_ viewport: NEChatViewport?) {
    chatViewport = viewport
    for (constraint, inset) in viewportWidthConstraints {
      constraint.constant = max(16, chat_content_maxW - inset)
    }
  }

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func uploadProgress(_ progress: UInt) {}

  open func setModel(_ model: MessageContentModel) {}
  open func setModel(_ model: MessageContentModel, _ isSend: Bool = false) {}
}
