// Copyright (c) 2022 NetEase, Inc. All rights reserved.

import NEChatKit
import UIKit

@objc public protocol NEMessageReactionViewDelegate: NSObjectProtocol {
  func reactionView(_ view: NEMessageReactionView, didSelectIndex index: Int)
}

/// Compact, wrapping presentation of message reactions. The view owns no SDK
/// state; it receives immutable groups and reports user intent through a
/// delegate so every chat surface can reuse the same manager.
@objcMembers
public final class NEMessageReactionView: UIView {
  public weak var delegate: NEMessageReactionViewDelegate?
  private var groups: [NEMessageReactionGroup] = []
  private var buttons: [UIButton] = []
  private let addButton = UIButton(type: .system)
  private var isOutgoing = false

  /// Whether the view currently has an enabled aggregate snapshot to render.
  public private(set) var isEnabledForDisplay = false

  private let itemHeight: CGFloat = 26
  private let itemSpacing: CGFloat = 4
  private let verticalPadding: CGFloat = 0
  private let addButtonWidth: CGFloat = 26

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupAddButton()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupAddButton()
  }

  private func setupAddButton() {
    backgroundColor = .clear
    // UIButton(type: .system) reserves 10pt of horizontal content inset on
    // the simulator. QChat's add capsule is exactly 26pt wide, including the
    // 16pt asset, so make the measured size match the rendered geometry.
    addButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    addButton.setImage(UIImage.ne_imageNamed(name: "reaction_add_emoji"), for: .normal)
    addButton.layer.cornerRadius = itemHeight / 2
    addButton.tag = 0
    addButton.accessibilityLabel = "Add reaction"
    addButton.accessibilityIdentifier = "id.messageReaction.add"
    addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    addSubview(addButton)
  }

  public func configure(groups: [NEMessageReactionGroup], enabled: Bool = true) {
    configure(groups: groups, enabled: enabled, isOutgoing: false)
  }

  /// Configures the message-side capsules. `isOutgoing` only controls the
  /// direction surface; the selected state still comes from each group.
  public func configure(groups: [NEMessageReactionGroup],
                        enabled: Bool = true,
                        isOutgoing: Bool) {
    self.groups = groups
    self.isOutgoing = isOutgoing
    buttons.forEach { $0.removeFromSuperview() }
    buttons.removeAll()
    for group in groups {
      let button = ReactionCapsuleButton(group: group)
      button.tag = group.index
      button.accessibilityLabel = "\(group.emoji.accessibilityDescription), \(group.count)"
      button.accessibilityIdentifier = "id.messageReaction.\(group.index)"
      button.layer.cornerRadius = itemHeight / 2
      button.layer.borderWidth = 0.5
      button.layer.borderColor = UIColor.ne_chatReactionBorder.cgColor
      button.backgroundColor = reactionBackgroundColor
      button.countLabel.textColor = group.isMine ? UIColor.ne_normalTheme : UIColor.ne_greyText
      button.countLabel.font = group.isMine
        ? .systemFont(ofSize: 12, weight: .semibold)
        : .systemFont(ofSize: 12, weight: .medium)
      button.addTarget(self, action: #selector(groupTapped(_:)), for: .touchUpInside)
      addSubview(button)
      buttons.append(button)
    }
    isHidden = !enabled || groups.isEmpty
    isEnabledForDisplay = enabled && !groups.isEmpty
    // An empty snapshot has no reaction surface at all; the add affordance is
    // shown only once at least one aggregate exists, matching the zero-height
    // empty-state contract.
    addButton.isHidden = !enabled || groups.isEmpty
    addButton.layer.borderWidth = 0.5
    addButton.layer.borderColor = UIColor.ne_chatReactionBorder.cgColor
    addButton.backgroundColor = reactionBackgroundColor
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  public override var intrinsicContentSize: CGSize {
    guard !isHidden else { return CGSize(width: UIView.noIntrinsicMetric, height: 0) }
    let width = bounds.width > 1 ? bounds.width : naturalWidth
    return CGSize(width: naturalWidth, height: height(forWidth: width))
  }

  /// The width of the widest row when the capsules are laid out without a
  /// parent constraint. Parents can use this value when building a natural
  /// width message/reaction combination.
  public var naturalWidth: CGFloat {
    var current: CGFloat = 0
    for button in [addButton] + buttons where !button.isHidden {
      let itemWidth = buttonWidth(for: button, availableWidth: CGFloat.greatestFiniteMagnitude)
      current += itemWidth + itemSpacing
    }
    return max(0, current - (current > 0 ? itemSpacing : 0))
  }

  /// Returns the widest row after wrapping in `maxWidth`. This is deliberately
  /// separate from `bounds.width`: the parent message bubble must use the
  /// measured row width instead of forcing the reaction collection to fill it.
  public func layoutWidth(forMaxWidth maxWidth: CGFloat) -> CGFloat {
    guard !isHidden, maxWidth > 0 else { return 0 }
    let availableWidth = max(maxWidth, 1)
    var x: CGFloat = 0
    var widest: CGFloat = 0
    for button in [addButton] + buttons where !button.isHidden {
      let itemWidth = min(buttonWidth(for: button, availableWidth: availableWidth), availableWidth)
      if x > 0, x + itemWidth > availableWidth {
        widest = max(widest, x - itemSpacing)
        x = 0
      }
      x += itemWidth + itemSpacing
    }
    return min(max(widest, max(0, x - itemSpacing)), availableWidth)
  }

  /// Calculates the number of rows needed by the current capsules. The
  /// width is supplied by the message bubble after Auto Layout resolves it.
  public func height(forWidth width: CGFloat) -> CGFloat {
    let availableWidth = max(width, 1)
    var x: CGFloat = 0
    var rows = 1
    for button in [addButton] + buttons where !button.isHidden {
      let itemWidth = min(buttonWidth(for: button, availableWidth: availableWidth), availableWidth)
      if x > 0, x + itemWidth > availableWidth {
        rows += 1
        x = 0
      }
      x += itemWidth + itemSpacing
    }
    return CGFloat(rows) * itemHeight + CGFloat(max(0, rows - 1)) * itemSpacing + verticalPadding * 2
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let availableWidth = max(bounds.width, 1)
    var x: CGFloat = 0
    var y: CGFloat = verticalPadding
    for button in [addButton] + buttons where !button.isHidden {
      let itemWidth = min(buttonWidth(for: button, availableWidth: availableWidth), availableWidth)
      if x > 0, x + itemWidth > availableWidth {
        x = 0
        y += itemHeight + itemSpacing
      }
      button.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
      x += itemWidth + itemSpacing
    }
  }

  private func buttonWidth(for button: UIButton, availableWidth: CGFloat) -> CGFloat {
    if button === addButton {
      return addButtonWidth
    }
    return button.sizeThatFits(CGSize(width: availableWidth, height: itemHeight)).width
  }

  private var reactionBackgroundColor: UIColor {
    isOutgoing
      ? UIColor.ne_chatReactionSendBackground
      : UIColor.ne_chatReactionReceiveBackground
  }

  @objc private func groupTapped(_ sender: UIButton) {
    delegate?.reactionView(self, didSelectIndex: sender.tag)
  }

  @objc private func addTapped() {
    delegate?.reactionView(self, didSelectIndex: 0)
  }
}

/// UIButton is kept as the public interaction surface so existing delegate
/// and accessibility contracts remain unchanged. Its private subviews give
/// Reaction capsules deterministic sizing independent of UIKit button style.
private final class ReactionCapsuleButton: UIButton {
  let iconView = UIImageView()
  let countLabel = UILabel()
  private let iconSize: CGFloat = 20
  private let contentSpacing: CGFloat = 6
  // Keep the capsule from feeling cramped while matching the OC/SwiftUI rows.
  private let horizontalInset: CGFloat = 10
  private let countHeight: CGFloat = 15

  init(group: NEMessageReactionGroup) {
    super.init(frame: .zero)
    iconView.image = UIImage.ne_imageNamed(name: group.emoji.resourceName)
    iconView.contentMode = .scaleAspectFit
    iconView.isUserInteractionEnabled = false
    countLabel.text = ReactionCapsuleButton.countText(group.count)
    countLabel.textAlignment = .right
    countLabel.adjustsFontSizeToFitWidth = true
    countLabel.minimumScaleFactor = 0.8
    countLabel.isUserInteractionEnabled = false
    addSubview(iconView)
    addSubview(countLabel)
    setTitle(nil, for: .normal)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let countWidth = countLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                      height: countHeight)).width
    return CGSize(width: horizontalInset * 2 + iconSize + contentSpacing + ceil(countWidth),
                  height: 26)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let countWidth = countLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                      height: countHeight)).width
    let renderedIconWidth = iconView.image == nil ? 0 : iconSize
    let renderedSpacing = renderedIconWidth > 0 ? contentSpacing : 0
    let iconX = renderedIconWidth > 0 ? horizontalInset : 0
    iconView.isHidden = renderedIconWidth == 0
    iconView.frame = CGRect(x: iconX,
                            y: (bounds.height - iconSize) / 2,
                            width: renderedIconWidth,
                            height: iconSize)
    let labelX = iconX + renderedIconWidth + renderedSpacing
    countLabel.frame = CGRect(x: labelX,
                              y: bounds.height - countHeight - 2,
                              width: max(8, min(ceil(countWidth), bounds.width - labelX - horizontalInset)),
                              height: countHeight)
  }

  private static func countText(_ count: Int) -> String {
    if count > 999_999 { return "\(count / 1_000_000)m" }
    if count > 999 { return "\(count / 1000)k" }
    return "\(count)"
  }
}
