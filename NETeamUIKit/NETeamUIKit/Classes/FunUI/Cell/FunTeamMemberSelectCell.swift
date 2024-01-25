//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class FunTeamMemberSelectCell: NEBaseTeamMemberSelectCell {
  public var dividerLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .funTeamLineBorderColor
    return view
  }()

  override func setupUI() {
    super.setupUI()
    addSubview(dividerLine)
    headerView.layer.cornerRadius = 4.0
    checkImageView.highlightedImage = coreLoader.loadImage("fun_select")
    NSLayoutConstraint.activate([
      checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      checkImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      checkImageView.widthAnchor.constraint(equalToConstant: 22),
      checkImageView.heightAnchor.constraint(equalToConstant: 22),
    ])

    NSLayoutConstraint.activate([
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 54),
      headerView.widthAnchor.constraint(equalToConstant: 40),
      headerView.heightAnchor.constraint(equalToConstant: 40),
    ])

    NSLayoutConstraint.activate([
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 105),
      nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: headerView.leftAnchor),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
