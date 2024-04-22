// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class CustomView: UIView {
  public let button = UIButton()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(tapView), for: .touchUpInside)
    button.setTitle("按钮", for: .normal)
    button.backgroundColor = .red
    addSubview(button)
    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: topAnchor),
      button.bottomAnchor.constraint(equalTo: bottomAnchor),
      button.widthAnchor.constraint(equalToConstant: 200),
      button.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  @objc func tapView() {
    print("点击了自定义按钮")
  }
}
