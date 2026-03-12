// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingTitleCell: NEPagingCell {
  public let titleLabel = UILabel(frame: .zero)
  private var viewModel: NEPagingTitleCellViewModel?

  private lazy var horizontalConstraints: [NSLayoutConstraint] = NSLayoutConstraint.constraints(
    withVisualFormat: "H:|[label]|",
    options: NSLayoutConstraint.FormatOptions(),
    metrics: nil,
    views: ["label": titleLabel]
  )

  private lazy var verticalConstraints: [NSLayoutConstraint] = NSLayoutConstraint.constraints(
    withVisualFormat: "V:|[label]|",
    options: NSLayoutConstraint.FormatOptions(),
    metrics: nil,
    views: ["label": titleLabel]
  )

  override open var isSelected: Bool {
    didSet {
      configureTitleLabel()
    }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  override open func setPagingItem(_ pagingItem: NEPagingItem, selected: Bool, options: NEPagingOptions) {
    if let titleItem = pagingItem as? NEPagingIndexItem {
      viewModel = NEPagingTitleCellViewModel(
        title: titleItem.title,
        selected: selected,
        options: options
      )
    }
    configureTitleLabel()
    configureAccessibility()
  }

  open func configure() {
    contentView.addSubview(titleLabel)
    contentView.isAccessibilityElement = true
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    contentView.addConstraints(horizontalConstraints)
    contentView.addConstraints(verticalConstraints)
  }

  open func configureTitleLabel() {
    guard let viewModel = viewModel else { return }
    titleLabel.text = viewModel.title
    titleLabel.textAlignment = .center

    if viewModel.selected {
      titleLabel.font = viewModel.selectedFont
      titleLabel.textColor = viewModel.selectedTextColor
      backgroundColor = viewModel.selectedBackgroundColor
    } else {
      titleLabel.font = viewModel.font
      titleLabel.textColor = viewModel.textColor
      backgroundColor = viewModel.backgroundColor
    }

    horizontalConstraints.forEach { $0.constant = viewModel.labelSpacing }
  }

  open func configureAccessibility() {
    accessibilityIdentifier = viewModel?.title
    contentView.accessibilityLabel = viewModel?.title
    contentView.accessibilityTraits = viewModel?.selected ?? false ? [.tabBar, .selected] : .tabBar
  }

  override open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    guard let viewModel = viewModel else { return }
    if let attributes = layoutAttributes as? NEPagingCellLayoutAttributes {
      titleLabel.textColor = UIColor.interpolate(
        from: viewModel.textColor,
        to: viewModel.selectedTextColor,
        with: attributes.progress
      )

      backgroundColor = UIColor.interpolate(
        from: viewModel.backgroundColor,
        to: viewModel.selectedBackgroundColor,
        with: attributes.progress
      )
    }
  }
}
