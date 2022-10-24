
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import Foundation
import NECoreKit

@objcMembers
public class ContactTableViewCell: ContactBaseViewCell, ContactCellDataProtrol {
  public lazy var arrow: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "arrowRight"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .center
    return imageView
  }()

  lazy var redAngleView: RedAngleLabel = {
    let label = RedAngleLabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = .white
    label.text = "1"
    label.backgroundColor = UIColor(hexString: "F24957")
    label.textInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
    label.layer.cornerRadius = 9
    label.clipsToBounds = true
    label.isHidden = true
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
    initSubviewsLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    // circle avatar head image with name suffix string
    setupCommonCircleHeader()

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(arrow)
    NSLayoutConstraint.activate([
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrow.widthAnchor.constraint(equalToConstant: 15),
      arrow.topAnchor.constraint(equalTo: contentView.topAnchor),
      arrow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(redAngleView)
    NSLayoutConstraint.activate([
      redAngleView.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
      redAngleView.rightAnchor.constraint(equalTo: arrow.leftAnchor, constant: -10),
    ])
  }

  func initSubviewsLayout() {
    if NEKitContactConfig.shared.ui.avatarType == .rectangle {
      avatarImage.layer.cornerRadius = NEKitContactConfig.shared.ui.avatarCornerRadius
    } else if NEKitContactConfig.shared.ui.avatarType == .cycle {
      avatarImage.layer.cornerRadius = 18.0
    }
  }

  func setConfig() {
    titleLabel.font = NEKitContactConfig.shared.ui.titleFont
    titleLabel.textColor = NEKitContactConfig.shared.ui.titleColor
    nameLabel.font = UIFont.systemFont(ofSize: 14.0)
    nameLabel.textColor = UIColor.white
  }

  public func setModel(_ model: ContactInfo) {
    guard let user = model.user else {
      return
    }
    setConfig()

    if model.contactCellType == 2 {
      // person
      titleLabel.text = user.showName()
      nameLabel.text = user.shortName(count: 2)

//            self.nameLabel.backgroundColor = UIColor(hexString: user.userId!)
      if let imageUrl = user.userInfo?.avatarUrl {
        nameLabel.isHidden = true
        avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
      } else {
        nameLabel.isHidden = false
        avatarImage.image = nil
      }
      arrow.isHidden = true

    } else {
      nameLabel.text = ""
      titleLabel.text = user.alias
      avatarImage.image = UIImage.ne_imageNamed(name: user.userInfo?.avatarUrl)
      avatarImage.backgroundColor = model.headerBackColor
      arrow.isHidden = false
    }
  }
}
