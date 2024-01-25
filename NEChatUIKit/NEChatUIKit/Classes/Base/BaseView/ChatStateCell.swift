
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
  public var rightImage = UIImageView()
  var rightImageMargin: NSLayoutConstraint?
  public var rightStyle: RightStyle {
    get {
      style
    }
    set {
      style = newValue
      switch style {
      case .none:
        rightImage.image = nil
      case .indicate:
        rightImage.image = UIImage.ne_imageNamed(name: "arrowRight")
      case .delete:
        rightImage.image = UIImage.ne_imageNamed(name: "delete")
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    rightImage.contentMode = .center
    rightImage.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(rightImage)
    rightImageMargin = rightImage.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -36
    )
    rightImageMargin?.isActive = true
    NSLayoutConstraint.activate([
      rightImage.widthAnchor.constraint(equalToConstant: 20),
      rightImage.heightAnchor.constraint(equalToConstant: 20),
      rightImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
