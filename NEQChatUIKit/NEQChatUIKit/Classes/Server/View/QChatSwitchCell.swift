
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol QChatSwitchCellDelegate: AnyObject {
  func didChangeSwitchValue(_ cell: QChatSwitchCell)
}

class QChatSwitchCell: QChatCornerCell {
  weak var delegate: QChatSwitchCellDelegate?

  var qSwitch: UISwitch = {
    let q = UISwitch()
    q.translatesAutoresizingMaskIntoConstraints = false
    q.onTintColor = .ne_blueText
    return q
  }()

  var permissionLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_darkText
    label.font = DefaultTextFont(16)
    return label
  }()

  var model: PermissionCellModel? {
    didSet {
      permissionLabel.text = model?.showName

      if let type = model?.cornerType {
        cornerType = type
      }
      if let value = model?.hasPermission {
        qSwitch.isOn = value
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
    setupUI()
  }

  func setupUI() {
    contentView.addSubview(qSwitch)
    NSLayoutConstraint.activate([
      qSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      qSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
    qSwitch.addTarget(self, action: #selector(valueChange(_:)), for: .valueChanged)

    contentView.addSubview(permissionLabel)
    NSLayoutConstraint.activate([
      permissionLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      permissionLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -95),
      permissionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  @objc func valueChange(_ s: UISwitch) {
    model?.hasPermission = s.isOn
    delegate?.didChangeSwitchValue(self)
    /*
     if s.isOn == true {
         if let key = model?.permissionKey {
             print("add key : ", key)
             model?.permission?.changeMap[key] = true
         }
     }else {
         if let key = model?.permissionKey {
             print("rm key : ", key)
             model?.permission?.changeMap[key] = false
         }
     }*/
    print("change maps : ", model?.permission?.changeMap as Any)
  }
}
