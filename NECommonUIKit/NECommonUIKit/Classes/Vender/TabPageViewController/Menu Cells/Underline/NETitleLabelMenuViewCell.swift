// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Basic style of cell
/// - center text
/// - emphasize text to focus color
public class NETitleLabelMenuViewCell: NEPagingMenuViewCell {
  ///  The text color when selecred
  public var focusColor = NEPagingKitConfig.focusColor {
    didSet {
      if isSelected {
        imageView.tintColor = focusColor
        titleLabel.textColor = focusColor
      }
    }
  }

  /// The normal text color.
  public var normalColor = NEPagingKitConfig.normalColor {
    didSet {
      if !isSelected {
        imageView.tintColor = normalColor
        titleLabel.textColor = normalColor
      }
    }
  }

  public var labelWidth: CGFloat {
    return stackView.bounds.width
  }

  public let titleLabel = { () -> UILabel in
    let label = UILabel()
    label.font = NEPagingKitConfig.menuTitleFont
    label.backgroundColor = .clear
    label.textAlignment = .center
    return label
  }()

  let imageView = { () -> UIImageView in
    let imageView = UIImageView()
    imageView.isHidden = true
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  public func setImage(_ image: UIImage?) {
    if let image = image {
      imageView.image = image
      imageView.isHidden = false
    } else {
      imageView.image = image
      imageView.isHidden = true
    }
  }

  let stackView = UIStackView()

  public var spacing: CGFloat {
    get {
      stackView.spacing
    }
    set {
      stackView.spacing = newValue
    }
  }

  public func calcIntermediateLabelSize(with currentCell: NETitleLabelMenuViewCell, percent: CGFloat) -> CGFloat {
    let diff = (labelWidth - currentCell.labelWidth) * abs(percent)
    return currentCell.labelWidth + diff
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  func setup() {
    backgroundColor = .clear
    stackView.axis = .horizontal
    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(titleLabel)
    stackView.spacing = 4
    addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addConstraints([
      anchorLabel(from: stackView, to: self, attribute: .top),
      anchorLabel(from: stackView, to: self, attribute: .leading, .greaterThanOrEqual),
      anchorLabel(from: self, to: stackView, attribute: .trailing, .greaterThanOrEqual),
      anchorLabel(from: self, to: stackView, attribute: .bottom),
      anchorLabel(from: stackView, to: self, 0, attribute: .centerX),
    ])
  }

  override public var isSelected: Bool {
    didSet {
      if isSelected {
        imageView.tintColor = focusColor
        titleLabel.textColor = focusColor
      } else {
        imageView.tintColor = normalColor
        titleLabel.textColor = normalColor
      }
    }
  }

  /// syntax sugar of NSLayoutConstraint for titleLabel (Because this library supports iOS8, it cannnot use NSLayoutAnchor.)
  private func anchorLabel(from fromItem: Any, to toItem: Any, _ constant: CGFloat = 8, attribute: NSLayoutConstraint.Attribute, _ relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
    return NSLayoutConstraint(
      item: fromItem,
      attribute: attribute,
      relatedBy: relatedBy,
      toItem: toItem,
      attribute: attribute,
      multiplier: 1,
      constant: constant
    )
  }
}
