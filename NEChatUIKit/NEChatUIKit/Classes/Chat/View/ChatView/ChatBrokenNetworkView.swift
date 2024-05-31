
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatBrokenNetworkView: UIView {
  /// 内容文本
  private lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(14)
    label.textColor = HexRGB(0xFC596A)
    label.textAlignment = .center
    label.text = commonLocalizable("network_error")
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func commonUI() {
    backgroundColor = HexRGB(0xFEE3E6)
    addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
      contentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      contentLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
    ])
  }
}
