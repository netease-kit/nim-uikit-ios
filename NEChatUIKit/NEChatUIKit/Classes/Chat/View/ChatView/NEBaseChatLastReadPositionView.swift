// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class NEBaseChatLastReadPositionView: UIView {
  public lazy var positionImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.image = .ne_imageNamed(name: "chat_jump_to_new")
    imageView.transform = CGAffineTransform(rotationAngle: .pi)
    imageView.tintColor = accentColor
    return imageView
  }()

  public lazy var messageCountLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(
      for: DefaultTextFont(14)
    )
    label.adjustsFontForContentSizeCategory = true
    label.textColor = accentColor
    label.lineBreakMode = .byTruncatingTail
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return label
  }()

  public lazy var activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.color = accentColor
    indicator.hidesWhenStopped = true
    return indicator
  }()

  public var accentColor: UIColor = .ne_normalTheme {
    didSet {
      positionImageView.tintColor = accentColor
      messageCountLabel.textColor = accentColor
      activityIndicator.color = accentColor
    }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  open func setupUI() {
    backgroundColor = .white
    layer.cornerRadius = 20
    layer.borderWidth = 1
    layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
    clipsToBounds = true

    addSubview(positionImageView)
    addSubview(messageCountLabel)
    addSubview(activityIndicator)
    NSLayoutConstraint.activate([
      positionImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      positionImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      positionImageView.widthAnchor.constraint(equalToConstant: 16),
      positionImageView.heightAnchor.constraint(equalToConstant: 16),
      messageCountLabel.leadingAnchor.constraint(equalTo: positionImageView.trailingAnchor, constant: 4),
      messageCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
      messageCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      activityIndicator.centerXAnchor.constraint(equalTo: positionImageView.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: positionImageView.centerYAnchor),
    ])

    isAccessibilityElement = true
    accessibilityTraits = .button
    accessibilityIdentifier = "id.chatLastReadPosition"
    accessibilityHint = chatLocalizable("last_read_position_accessibility_hint")
  }

  open func update(snapshot: NELastReadPositionSnapshot, locating: Bool) {
    let text: String
    if snapshot.isOverflow {
      text = chatLocalizable("last_read_position_overflow")
    } else {
      text = String(
        format: chatLocalizable("last_read_position_count"),
        snapshot.displayCount
      )
    }
    messageCountLabel.text = text
    accessibilityLabel = text
    isUserInteractionEnabled = !locating
    accessibilityTraits = locating ? [.button, .notEnabled] : .button
    positionImageView.isHidden = locating
    if locating {
      activityIndicator.startAnimating()
    } else {
      activityIndicator.stopAnimating()
    }
  }
}
