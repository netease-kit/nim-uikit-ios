// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objc
protocol BlackListCellDelegate: AnyObject {
  func removeUser(account: String?, index: Int)
}

@objcMembers
open class NEBaseBlackListCell: NEBaseTeamTableViewCell {
  weak var delegate: BlackListCellDelegate?
  var index = 0
  private var model: NEUserWithFriend?
  var button = UIButton()

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
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
    delegate?.removeUser(account: model?.user?.accountId, index: index)
  }

  override open func setModel(_ model: Any) {
    guard let user = model as? NEUserWithFriend else {
      return
    }
    self.model = user

    // title
    titleLabel.text = user.showName()

    // avatar
    if let imageUrl = user.user?.avatar, !imageUrl.isEmpty {
      nameLabel.text = ""
      avatarImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
      avatarImageView.backgroundColor = .clear
    } else {
      nameLabel.text = user.shortName(count: 2)
      avatarImageView.image = nil
      avatarImageView.backgroundColor = UIColor.colorWithString(string: user.user?.accountId)
    }
  }
}
