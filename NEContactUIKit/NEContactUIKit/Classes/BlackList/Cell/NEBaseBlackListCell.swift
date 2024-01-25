// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit

@objc
protocol BlackListCellDelegate: AnyObject {
  func removeUser(account: String?, index: Int)
}

@objcMembers
open class NEBaseBlackListCell: NEBaseTeamTableViewCell {
  weak var delegate: BlackListCellDelegate?
  var index = 0
  private var model: NEKitUser?
  var button = UIButton()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func commonUI() {
    super.commonUI()
    button.layer.borderWidth = 1
    button.layer.cornerRadius = 4
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.contentMode = .center
    button.clipsToBounds = true
    button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
    button.setTitle(localizable("remove_black"), for: .normal)
    button.accessibilityIdentifier = "id.relieve"
    contentView.addSubview(button)
    NSLayoutConstraint.activate([
      button.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      button.widthAnchor.constraint(equalToConstant: 60),
      button.heightAnchor.constraint(equalToConstant: 32),
      button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    contentView.updateLayoutConstraint(firstItem: titleLabel, seconedItem: contentView, attribute: .right, constant: -80)
  }

  func buttonEvent(sender: UIButton) {
    delegate?.removeUser(account: model?.userId, index: index)
  }

  override open func setModel(_ model: Any) {
    guard let user = model as? NEKitUser else {
      return
    }
    self.model = user

    // title
    titleLabel.text = user.showName()

    // avatar
    if let imageUrl = user.userInfo?.avatarUrl, !imageUrl.isEmpty {
      nameLabel.text = ""
      avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
      avatarImage.backgroundColor = .clear
    } else {
      nameLabel.text = user.shortName(showAlias: false, count: 2)
      avatarImage.image = nil
      avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
    }
  }

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()
}
