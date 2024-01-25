
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

// protocol OperationCellDelegate: AnyObject {
//    func didSelected(_ cell: OperationCell, _ model: OperationItem?)
// }

@objcMembers
open class OperationCell: UICollectionViewCell {
  public var imageView = UIImageView()
  public var label = UILabel()
//    public weak var delegate: OperationCellDelegate?
  public var model: OperationItem? {
    didSet {
      imageView.image = UIImage.ne_imageNamed(name: model?.imageName)
      label.text = model?.text
    }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    contentView.accessibilityIdentifier = "id.menuCell"

    imageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    imageView.contentMode = .center
    imageView.accessibilityIdentifier = "id.menuIcon"
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      imageView.widthAnchor.constraint(equalToConstant: 18),
      imageView.heightAnchor.constraint(equalToConstant: 18),
    ])

    label.font = UIFont.systemFont(ofSize: 14)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.menuTitle"
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
      label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: 18),
    ])
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent))
//        self.contentView.addGestureRecognizer(tap)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

//    @objc func tapEvent(tap: UITapGestureRecognizer) {
//        self.delegate?.didSelected(self, model)
//    }
}
