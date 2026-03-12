//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

class NEHistorySearchMonthHeaderView: UICollectionReusableView {
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 16)
    label.textColor = .ne_lightText
    return label
  }()

  lazy var separatorView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hexString: "#E5E5E5")
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    for item in [separatorView, titleLabel] {
      item.translatesAutoresizingMaskIntoConstraints = false
      addSubview(item)
    }

    NSLayoutConstraint.activate([
      separatorView.topAnchor.constraint(equalTo: topAnchor),
      separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
      separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
      separatorView.heightAnchor.constraint(equalToConstant: 0.5),

      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])
  }

  func configure(title: String) {
    titleLabel.text = title
  }
}
