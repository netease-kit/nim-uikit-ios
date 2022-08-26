
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatTextSelectionCell: QChatTextCell {
  var selectedImageView = UIImageView(image: UIImage.ne_imageNamed(name: "selection"))

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectedImageView.contentMode = .center
    selectedImageView.translatesAutoresizingMaskIntoConstraints = false
    selectedImageView.image = UIImage.ne_imageNamed(name: "Selection")
    contentView.addSubview(selectedImageView)
    NSLayoutConstraint.activate([
      selectedImageView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -36
      ),
      selectedImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      selectedImageView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: 0
      ),
      selectedImageView.widthAnchor.constraint(equalToConstant: 15),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func selected(selected: Bool) {
    selectedImageView.isHidden = !selected
  }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        selectedImageView.isHidden = !selected
//    }
}
