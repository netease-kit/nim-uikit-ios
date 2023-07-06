//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public class CustomTopView: UIView {
  override public init(frame: CGRect) {
    super.init(frame: frame)
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
//        addGestureRecognizer(tap)
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.addTarget(self, action: #selector(tapView), for: .touchUpInside)
    btn.backgroundColor = .red
    addSubview(btn)
    NSLayoutConstraint.activate([
      btn.topAnchor.constraint(equalTo: topAnchor),
      btn.leftAnchor.constraint(equalTo: leftAnchor),
      btn.rightAnchor.constraint(equalTo: rightAnchor),
      btn.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func tapView() {}
}
