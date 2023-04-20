
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit

protocol TeamTableViewCellDelegate: AnyObject {
  func removeUser(account: String?, index: Int)
}

@objcMembers
class BlackListCell: TeamTableViewCell {
  weak var delegate: TeamTableViewCellDelegate?
  var index = 0
  private var model: User?
  var button = UIButton()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func commonUI() {
    super.commonUI()

    button.layer.borderWidth = 1
    button.layer.borderColor = UIColor(red: 0.2, green: 0.494, blue: 1, alpha: 1).cgColor
    button.layer.cornerRadius = 4
    button.setTitleColor(UIColor(red: 0.2, green: 0.494, blue: 1, alpha: 1), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.contentMode = .center
    button.clipsToBounds = true
    button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
    button.setTitle(localizable("remove_black"), for: .normal)
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

    titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -80).isActive = true
  }

  func buttonEvent(sender: UIButton) {
    delegate?.removeUser(account: model?.userId, index: index)
  }

  override public func setModel(_ model: Any) {
    guard let user = model as? User else {
      return
    }
    self.model = user
    avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
    // title
    titleLabel.text = user.showName()

    // avatar
    if let imageUrl = user.userInfo?.avatarUrl {
      nameLabel.text = ""
      avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
    } else {
      nameLabel.text = user.shortName(showAlias: false, count: 2)
      avatarImage.image = nil
    }
  }

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()
}
