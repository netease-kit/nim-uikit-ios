
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ContactSectionView: UITableViewHeaderFooterView {
  public lazy var backView: UIView = {
    let backView = UIView()
    backView.translatesAutoresizingMaskIntoConstraints = false
    return backView
  }()

  public lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.backgroundColor = .clear
    titleLabel.textColor = ContactUIConfig.shared.contactProperties.indexTitleColor ?? UIColor.ne_emptyTitleColor
    titleLabel.font = UIFont.systemFont(ofSize: 14.0)
    return titleLabel
  }()

  public lazy var line: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    return line
  }()

  override public init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    backgroundColor = .clear

    addSubview(backView)
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      backView.topAnchor.constraint(equalTo: topAnchor),
      backView.bottomAnchor.constraint(equalTo: bottomAnchor),
      backView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
    ])

    backView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 20),
      titleLabel.topAnchor.constraint(equalTo: backView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
      titleLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: 20),
    ])

    backView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      line.heightAnchor.constraint(equalToConstant: 1.0),
      line.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: 0),
      line.rightAnchor.constraint(equalTo: backView.rightAnchor),
    ])
  }
}
