// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEPagingView: UIView {
  // MARK: Public Properties

  /// 横向欢动列表
  public let collectionView: UICollectionView
  public let pageView: UIView
  public var options: NEPagingOptions {
    didSet {
      heightConstraint?.constant = options.menuHeight
      collectionView.backgroundColor = options.menuBackgroundColor
    }
  }

  // MARK: Private Properties

  private var heightConstraint: NSLayoutConstraint?

  // MARK: Initializers

  public init(options: NEPagingOptions, collectionView: UICollectionView, pageView: UIView) {
    self.options = options
    self.collectionView = collectionView
    self.pageView = pageView
    super.init(frame: .zero)
  }

  public required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public Methods

  open func configure() {
    collectionView.backgroundColor = options.menuBackgroundColor
    addSubview(pageView)
    addSubview(collectionView)
    setupConstraints()
  }

  /// 初始化约束
  open func setupConstraints() {
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    pageView.translatesAutoresizingMaskIntoConstraints = false

    let metrics = [
      "height": options.menuHeight,
    ]

    let views = [
      "collectionView": collectionView,
      "pageView": pageView,
    ]

    let formatOptions = NSLayoutConstraint.FormatOptions()

    let horizontalCollectionViewContraints = NSLayoutConstraint.constraints(
      withVisualFormat: "H:|[collectionView]|",
      options: formatOptions,
      metrics: metrics,
      views: views
    )

    let horizontalPagingContentViewContraints = NSLayoutConstraint.constraints(
      withVisualFormat: "H:|[pageView]|",
      options: formatOptions,
      metrics: metrics,
      views: views
    )

    let verticalConstraintsFormat: String
    switch options.menuPosition {
    case .top:
      verticalConstraintsFormat = "V:|[collectionView(==height)][pageView]|"
    case .bottom:
      verticalConstraintsFormat = "V:|[pageView][collectionView(==height)]|"
    }

    let verticalContraints = NSLayoutConstraint.constraints(
      withVisualFormat: verticalConstraintsFormat,
      options: formatOptions,
      metrics: metrics,
      views: views
    )

    addConstraints(horizontalCollectionViewContraints)
    addConstraints(horizontalPagingContentViewContraints)
    addConstraints(verticalContraints)

    for constraint in verticalContraints {
      if constraint.firstAttribute == NSLayoutConstraint.Attribute.height {
        heightConstraint = constraint
      }
    }
  }
}
