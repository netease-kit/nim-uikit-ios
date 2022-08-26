
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM

protocol QChatPermissionSettingCellDelegate: AnyObject {
  func didSelected(cell: QChatPermissionSettingCell?, model: RoleStatusInfo?)
}

class QChatPermissionSettingCell: QChatCornerCell {
  public weak var delegate: QChatPermissionSettingCellDelegate?
  private var model: RoleStatusInfoExt?
  private var button: UIButton?
  private var titleLabel = UILabel()
  private var enable: Bool {
    get {
      (buttons.first?.isUserInteractionEnabled) != nil
    }
    set {
      for button in buttons {
        button.isUserInteractionEnabled = newValue
      }
    }
  }

  private var index: Int {
    get {
      selectedIndex
    }
    set {
      selectedIndex = newValue
      button = buttons[selectedIndex]
      button?.isSelected = true
    }
  }

  private var selectedIndex = -1
  private var buttons = [CornerButton]()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.textColor = .ne_darkText
    titleLabel.text = "删除"
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 35),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    let denyButton = CornerButton(frame: .zero)
    denyButton.color = .white
    denyButton.selectedColor = UIColor.red
    denyButton.tag = 0 + 10
    denyButton.setImage(UIImage.ne_imageNamed(name: "deny"), for: .normal)
    denyButton.setImage(UIImage.ne_imageNamed(name: "denySelected"), for: .selected)
    denyButton.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
    denyButton.cornerType = CornerType.topLeft.union(CornerType.bottomLeft)
    buttons.append(denyButton)

    let midButton = CornerButton(frame: .zero)
    midButton.tag = 1 + 10
    midButton.color = .white
    midButton.selectedColor = UIColor.ne_borderColor
    midButton.setImage(UIImage.ne_imageNamed(name: "extend"), for: .normal)
    midButton.setImage(UIImage.ne_imageNamed(name: "extendSelected"), for: .selected)
    midButton.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
    buttons.append(midButton)

    let allowButton = CornerButton(frame: .zero)
    allowButton.tag = 2 + 10
    allowButton.color = .white
    allowButton.selectedColor = UIColor.ne_greenColor
    allowButton.setImage(UIImage.ne_imageNamed(name: "allow"), for: .normal)
    allowButton.setImage(UIImage.ne_imageNamed(name: "allowSeleted"), for: .selected)
    allowButton.cornerType = CornerType.topRight.union(CornerType.bottomRight)
    allowButton.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
    buttons.append(allowButton)

    contentView.addSubview(allowButton)
    NSLayoutConstraint.activate([
      allowButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      allowButton.widthAnchor.constraint(equalToConstant: 32),
      allowButton.heightAnchor.constraint(equalToConstant: 26),
      allowButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    contentView.addSubview(midButton)
    NSLayoutConstraint.activate([
      midButton.rightAnchor.constraint(equalTo: allowButton.leftAnchor, constant: 0),
      midButton.widthAnchor.constraint(equalToConstant: 32),
      midButton.heightAnchor.constraint(equalToConstant: 26),
      midButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    contentView.addSubview(denyButton)
    NSLayoutConstraint.activate([
      denyButton.rightAnchor.constraint(equalTo: midButton.leftAnchor, constant: 0),
      denyButton.widthAnchor.constraint(equalToConstant: 32),
      denyButton.heightAnchor.constraint(equalToConstant: 26),
      denyButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      denyButton.leftAnchor.constraint(equalTo: titleLabel.rightAnchor),
    ])
  }

  public func updateModel(model: RoleStatusInfoExt?) {
    self.model = model
    titleLabel.text = model?.title
    index = (model?.status?.status.rawValue ?? 0) + 1
  }

  @objc func buttonEvent(sender: CornerButton) {
    if sender.tag - 10 == selectedIndex {
      return
    }
    selectedIndex = sender.tag - 10
    if let type = model?.status?.type {
      let update = RoleStatusInfo(
        type: type,
        status: status(rawValue: selectedIndex - 1) ?? .Extend
      )
      delegate?.didSelected(cell: self, model: update)
    }
  }

  public func selectedSuccess(success: Bool) {
    if success {
      if let button = button {
        button.isSelected = !button.isSelected
      }
      if selectedIndex >= 0, selectedIndex < buttons.count {
        let new = buttons[selectedIndex]
        new.isSelected = !new.isSelected
        button = new
      }
      model?.status?.status = status(rawValue: selectedIndex - 1) ?? .Extend
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
