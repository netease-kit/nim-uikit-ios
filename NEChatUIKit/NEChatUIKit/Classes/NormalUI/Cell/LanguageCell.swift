//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class LanguageCell: NEBaseLanguageCell {
  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override open func setupLanguageCellUI() {
    super.setupLanguageCellUI()
    contentView.addSubview(languageLabel)
    NSLayoutConstraint.activate([
      languageLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      languageLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      languageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      languageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(selectedImageView)
    NSLayoutConstraint.activate([
      selectedImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      selectedImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectedImageView.widthAnchor.constraint(equalToConstant: 16),
      selectedImageView.heightAnchor.constraint(equalToConstant: 16),
    ])
  }
}
