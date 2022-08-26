
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatTimeTableViewCell: UITableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.addSubview(timeLable)
    NSLayoutConstraint.activate([
      timeLable.topAnchor.constraint(equalTo: contentView.topAnchor),
      timeLable.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      timeLable.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      timeLable.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var messageFrame: QChatMessageFrame? {
    didSet {
      timeLable.text = messageFrame?.time
    }
  }

  private lazy var timeLable: UILabel = {
    let label = UILabel()
    label.font = DefaultTextFont(12)
    label.textColor = UIColor.ne_emptyTitleColor
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
}
