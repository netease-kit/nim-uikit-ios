
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public enum RightStyle: Int {
  case none = 0
  case indicate
  case delete
}

@objcMembers
open class ChatStateCell: ChatCornerCell {
  private var style: RightStyle = .none
  public var rightImageView = UIImageView()
  var rightImageMargin: NSLayoutConstraint?
  public var rightStyle: RightStyle {
    get {
      style
    }
    set {
      style = newValue
      switch style {
      case .none:
        rightImageView.image = nil
      case .indicate:
        rightImageView.image = UIImage.ne_imageNamed(name: "arrowRight")
      case .delete:
        rightImageView.image = UIImage.ne_imageNamed(name: "delete")
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  /// UI 初始化
  open func setupUI() {
    rightImageView.contentMode = .center
    rightImageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(rightImageView)
    rightImageMargin = rightImageView.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -36
    )
    rightImageMargin?.isActive = true
    NSLayoutConstraint.activate([
      rightImageView.widthAnchor.constraint(equalToConstant: 20),
      rightImageView.heightAnchor.constraint(equalToConstant: 20),
      rightImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
}
