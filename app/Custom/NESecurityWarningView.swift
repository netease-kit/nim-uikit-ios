//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

open class NESecurityWarningView: UIView {
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    addSubview(backView)
    NSLayoutConstraint.activate([
      backView.topAnchor.constraint(equalTo: topAnchor),
      backView.bottomAnchor.constraint(equalTo: bottomAnchor),
      backView.leftAnchor.constraint(equalTo: leftAnchor),
      backView.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }

  public lazy var backView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#FFF5E1")

    view.addSubview(warningLabel)
    NSLayoutConstraint.activate([
      warningLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
      warningLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
      warningLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      warningLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
    ])
    return view
  }()

  public lazy var warningLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "#EB9718")
    label.font = .systemFont(ofSize: 14)
    label.text = localizable("security_warning")
    label.textAlignment = .justified
    label.numberOfLines = 0
    label.accessibilityIdentifier = "id.securityWarning"
    return label
  }()
}
