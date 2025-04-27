//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunLanguageCell: NEBaseLanguageCell {
  override open func setupLanguageCellUI() {
    super.setupLanguageCellUI()
    contentView.addSubview(languageLabel)
    NSLayoutConstraint.activate([
      languageLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 40),
      languageLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      languageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      languageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(selectedImageView)
    NSLayoutConstraint.activate([
      selectedImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -40),
      selectedImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectedImageView.widthAnchor.constraint(equalToConstant: 16),
      selectedImageView.heightAnchor.constraint(equalToConstant: 16),
    ])

    contentView.backgroundColor = .clear
  }

  override open func configureData(_ model: NElanguageCellModel) {
    if model.isSelect == true {
      fillColor = UIColor(hexString: "#F5F8FF")
    } else {
      fillColor = UIColor.white
    }
    super.configureData(model)
  }
}
