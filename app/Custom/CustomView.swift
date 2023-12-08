// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class CustomView: UIView {
  public let btn = UIButton()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.addTarget(self, action: #selector(tapView), for: .touchUpInside)
    btn.setTitle("按钮", for: .normal)
    btn.backgroundColor = .red
    addSubview(btn)
    NSLayoutConstraint.activate([
      btn.topAnchor.constraint(equalTo: topAnchor),
      btn.bottomAnchor.constraint(equalTo: bottomAnchor),
      btn.widthAnchor.constraint(equalToConstant: 200),
      btn.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func tapView() {
    print("点击了自定义按钮")
  }
}
