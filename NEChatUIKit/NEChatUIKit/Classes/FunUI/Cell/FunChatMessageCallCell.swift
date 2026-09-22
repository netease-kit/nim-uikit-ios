// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageCallCell: FunChatMessageBaseCell {
  public lazy var contentLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = messageTextFont
    label.textAlignment = .center
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.chatMessageCallText"
    return label
  }()

  public lazy var contentLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = messageTextFont
    label.textAlignment = .center
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.chatMessageCallText"
    return label
  }()

  public lazy var callBodyBackgroundViewLeft: UIView = makeCallBodyBackgroundView()
  public lazy var callBodyBackgroundViewRight: UIView = makeCallBodyBackgroundView()

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(callBodyBackgroundViewLeft)
    NSLayoutConstraint.activate([
      callBodyBackgroundViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor,
                                                       constant: funMargin + 4),
      callBodyBackgroundViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor,
                                                      constant: 4),
      callBodyBackgroundViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor,
                                                        constant: -4),
      callBodyBackgroundViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor,
                                                         constant: -4),
    ])
    bubbleImageLeft.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.centerYAnchor.constraint(equalTo: bubbleImageLeft.centerYAnchor),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(callBodyBackgroundViewRight)
    NSLayoutConstraint.activate([
      callBodyBackgroundViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor,
                                                        constant: 4),
      callBodyBackgroundViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor,
                                                       constant: 4),
      callBodyBackgroundViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor,
                                                         constant: -(funMargin + 4)),
      callBodyBackgroundViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor,
                                                          constant: -4),
    ])
    bubbleImageRight.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -(chat_content_margin + funMargin)),
      contentLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
      contentLabelRight.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
    ])

    activityView.removeFromSuperview()
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentLabelLeft.isHidden = showRight
    contentLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let contentLabel = isSend ? contentLabelRight : contentLabelLeft
    if let m = model as? MessageCallRecordModel {
      contentLabel.attributedText = m.attributeStr
    }
    updateCallBodyBackgrounds()
  }

  override open func reactionTopSpacing(for model: MessageContentModel) -> CGFloat {
    model.type == .rtcCallRecord ? 0 : super.reactionTopSpacing(for: model)
  }

  override open func reactionBottomSpacing(for model: MessageContentModel) -> CGFloat {
    model.type == .rtcCallRecord
      ? NEBaseChatMessageCell.reactionBottomPadding
      : super.reactionBottomSpacing(for: model)
  }

  private func makeCallBodyBackgroundView() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    view.layer.cornerRadius = 4
    return view
  }

  private func updateCallBodyBackgrounds() {
    updateCallBodyBackground(callBodyBackgroundViewLeft,
                             displayed: reactionViewLeft.isEnabledForDisplay,
                             color: UIColor.ne_chatReactionReceiveBackground)
    updateCallBodyBackground(callBodyBackgroundViewRight,
                             displayed: reactionViewRight.isEnabledForDisplay,
                             color: UIColor.ne_chatReactionContentBackground)
  }

  private func updateCallBodyBackground(_ view: UIView,
                                        displayed: Bool,
                                        color: UIColor) {
    view.isHidden = !displayed
    view.backgroundColor = displayed ? color : .clear
    view.layer.borderWidth = displayed ? 0.5 : 0
    view.layer.borderColor = displayed
      ? UIColor.ne_chatReactionBorder.cgColor
      : UIColor.clear.cgColor
  }
}
