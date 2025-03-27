// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
open class FunTeamMemberCell: NEBaseTeamMemberCell {
  public var dividerLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funTeamMemberDividerLine
    return view
  }()

  override open func setupUI() {
    contentView.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 40),
      headerView.heightAnchor.constraint(equalToConstant: 40),
    ])
    headerView.layer.cornerRadius = 4.0

    contentView.addSubview(ownerLabel)
    ownerWidth = ownerLabel.widthAnchor.constraint(equalToConstant: 48.0)
    NSLayoutConstraint.activate([
      ownerLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: NEAppLanguageUtil.getCurrentLanguage() == .english ? -76 : -56),
      ownerLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ownerLabel.heightAnchor.constraint(equalToConstant: 25.0),
      ownerWidth!,
    ])

    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 14.0),
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabel.rightAnchor.constraint(equalTo: ownerLabel.leftAnchor, constant: -14),
    ])
    setOwnerStyle()

    contentView.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    contentView.addSubview(removeLabel)
    removeLabel.textColor = .funTeamRemoveLabelColor
    NSLayoutConstraint.activate([
      removeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      removeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
    ])

    setupRemoveButton()
  }

  open func setOwnerStyle() {
    ownerLabel.textColor = UIColor.funTeamThemeColor
    ownerLabel.backgroundColor = UIColor.funTeamThemeColor.withAlphaComponent(0.1)
    ownerLabel.layer.borderColor = UIColor.funTeamThemeColor.cgColor
    ownerWidth?.constant = NEAppLanguageUtil.getCurrentLanguage() == .english ? 80 : 48
  }

  open func setManagerStyle() {
    ownerLabel.textColor = UIColor.funTeamMangerLabelTextColor
    ownerLabel.backgroundColor = UIColor.funTeamManagerLabelBorderColor.withAlphaComponent(0.1)
    ownerLabel.layer.borderColor = UIColor.funTeamManagerLabelBorderColor.cgColor
    ownerWidth?.constant = 60
  }
}
