// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class NEOverlayFocusView: UIView {
  public var contentBackgroundColor: UIColor? {
    set {
      contentView.backgroundColor = newValue
    }
    get {
      return contentView.backgroundColor
    }
  }

  let contentView = UIView()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    addConstraints()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    addConstraints()
  }

  override public func layoutSubviews() {
    super.layoutSubviews()
    contentView.layer.cornerRadius = contentView.bounds.height / 2
  }

  private func addConstraints() {
    contentView.backgroundColor = .lightGray
    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    let trailingConstraint = NSLayoutConstraint(
      item: self,
      attribute: .trailing,
      relatedBy: .equal,
      toItem: contentView,
      attribute: .trailing,
      multiplier: 1,
      constant: 8
    )
    let leadingConstraint = NSLayoutConstraint(
      item: contentView,
      attribute: .leading,
      relatedBy: .equal,
      toItem: self,
      attribute: .leading,
      multiplier: 1,
      constant: 8
    )
    let centerConstraint = NSLayoutConstraint(
      item: self,
      attribute: .centerY,
      relatedBy: .equal,
      toItem: contentView,
      attribute: .centerY,
      multiplier: 1,
      constant: 0
    )
    let hightConstraint = NSLayoutConstraint(
      item: contentView,
      attribute: .height,
      relatedBy: .equal,
      toItem: nil,
      attribute: .height,
      multiplier: 1,
      constant: 32
    )

    addConstraints([centerConstraint, trailingConstraint, leadingConstraint])
    contentView.addConstraint(hightConstraint)
  }
}
