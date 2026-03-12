//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NIMSDK
import SDWebImage
import UIKit

class NEHistorySearchMediaTableSectionHeader: UITableViewHeaderFooterView {
  let titleLabel = UILabel()

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .ne_darkText

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
    ])
  }

  func configure(with title: String) {
    titleLabel.text = title
  }
}
