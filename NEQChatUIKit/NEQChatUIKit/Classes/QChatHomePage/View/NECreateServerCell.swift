
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class NECreateServerCell: UITableViewCell {
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupSubviews()
  }

  var model: (image: String, title: String)? {
    didSet {
      headImageView.image = UIImage.ne_imageNamed(name: model?.image)
      content.text = model?.title
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    contentView.addSubview(serviceBgView)
    serviceBgView.addSubview(headImageView)
    serviceBgView.addSubview(content)
    serviceBgView.addSubview(arrowImageView)

    NSLayoutConstraint.activate([
      serviceBgView.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: kScreenInterval
      ),
      serviceBgView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -kScreenInterval
      ),
      serviceBgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      serviceBgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])

    NSLayoutConstraint.activate([
      headImageView.leftAnchor.constraint(equalTo: serviceBgView.leftAnchor, constant: 16),
      headImageView.centerYAnchor.constraint(equalTo: serviceBgView.centerYAnchor),
      headImageView.widthAnchor.constraint(equalToConstant: 36),
      headImageView.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      arrowImageView.centerYAnchor.constraint(equalTo: serviceBgView.centerYAnchor),
      arrowImageView.rightAnchor.constraint(
        equalTo: serviceBgView.rightAnchor,
        constant: -kScreenInterval
      ),
      arrowImageView.widthAnchor.constraint(equalToConstant: 5),
    ])

    NSLayoutConstraint.activate([
      content.leftAnchor.constraint(equalTo: headImageView.rightAnchor, constant: 16),
      content.centerYAnchor.constraint(equalTo: headImageView.centerYAnchor),
      content.rightAnchor.constraint(equalTo: arrowImageView.leftAnchor, constant: -16),
    ])
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  // MARK: lazyMethod

  private lazy var serviceBgView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = HexRGB(0xEFF1F4)
    view.layer.cornerRadius = 8
    return view
  }()

  private lazy var headImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var content: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(16)
    label.textColor = TextNormalColor
    return label
  }()

  private lazy var arrowImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "arrowRight"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
}
