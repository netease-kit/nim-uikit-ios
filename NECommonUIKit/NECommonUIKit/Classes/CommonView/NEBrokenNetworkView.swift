
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBrokenNetworkView: UIView {
  /// 错误提示图片
  public lazy var errorIconView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = coreLoader.loadImage("error")
    imageView.isHidden = true
    return imageView
  }()

  /// 网络错误标签
  public lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = UIColor(hexString: "#FC596A")
    label.textAlignment = .left
    label.text = commonLocalizable("network_error")
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor(hexString: "#FEE3E6")
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func commonUI() {
    addSubview(errorIconView)
    NSLayoutConstraint.activate([
      errorIconView.leftAnchor.constraint(equalTo: leftAnchor, constant: 30),
      errorIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      errorIconView.widthAnchor.constraint(equalToConstant: 20),
      errorIconView.heightAnchor.constraint(equalToConstant: 20),
    ])

    addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: errorIconView.rightAnchor, constant: 18),
      contentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      contentLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
    ])
  }
}
