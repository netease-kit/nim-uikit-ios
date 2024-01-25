
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatBrokenNetworkView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    backgroundColor = HexRGB(0xFEE3E6)
    addSubview(content)
    NSLayoutConstraint.activate([
      content.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
      content.centerYAnchor.constraint(equalTo: centerYAnchor),
      content.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
    ])
  }

  private lazy var content: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(14)
    label.textColor = HexRGB(0xFC596A)
    label.textAlignment = .center
    label.text = commonLocalizable("network_error")
    return label
  }()
}
