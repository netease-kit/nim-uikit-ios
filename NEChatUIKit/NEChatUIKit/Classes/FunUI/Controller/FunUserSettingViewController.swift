// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunUserSettingViewController: NEBaseUserSettingViewController {
  override public init(userId: String) {
    super.init(userId: userId)
    cellClassDic = [
      UserSettingType.SwitchType.rawValue: FunUserSettingSwitchCell.self,
      UserSettingType.SelectType.rawValue: FunUserSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    viewmodel.cellDatas.forEach { cellModel in
      cellModel.cornerType = .none
    }
  }

  override func setupUI() {
    super.setupUI()
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
    userHeader.layer.cornerRadius = 4.0
    addBtn.setImage(coreLoader.loadImage("fun_setting_add"), for: .normal)
    contentTable.rowHeight = 56
  }

  override open func headerView() -> UIView {
    let header = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 117))
    header.backgroundColor = .clear
    let cornerBack = UIView()
    cornerBack.backgroundColor = .white
    cornerBack.translatesAutoresizingMaskIntoConstraints = false
    header.addSubview(cornerBack)
    NSLayoutConstraint.activate([
      cornerBack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8),
      cornerBack.leftAnchor.constraint(equalTo: header.leftAnchor),
      cornerBack.rightAnchor.constraint(equalTo: header.rightAnchor),
      cornerBack.heightAnchor.constraint(equalToConstant: 109.0),
    ])

    cornerBack.addSubview(userHeader)

    let tap = UITapGestureRecognizer()
    userHeader.addGestureRecognizer(tap)
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1

    if let url = viewmodel.userInfo?.userInfo?.avatarUrl, !url.isEmpty {
      userHeader.sd_setImage(with: URL(string: url), completed: nil)
      userHeader.setTitle("")
      userHeader.backgroundColor = .clear
    } else if let name = viewmodel.userInfo?.shortName(showAlias: false, count: 2) {
      userHeader.sd_setImage(with: nil)
      userHeader.setTitle(name)
      userHeader.backgroundColor = UIColor.colorWithString(string: viewmodel.userInfo?.userId)
    }

    nameLabel.text = viewmodel.userInfo?.showName()
    cornerBack.addSubview(nameLabel)

    if IMKitClient.instance.getConfigCenter().teamEnable {
      NSLayoutConstraint.activate([
        userHeader.leftAnchor.constraint(equalTo: cornerBack.leftAnchor, constant: 22),
        userHeader.topAnchor.constraint(equalTo: cornerBack.topAnchor, constant: 22),
        userHeader.widthAnchor.constraint(equalToConstant: 50),
        userHeader.heightAnchor.constraint(equalToConstant: 50),
      ])

      nameLabel.font = NEConstant.defaultTextFont(12)
      nameLabel.textAlignment = .center
      NSLayoutConstraint.activate([
        nameLabel.topAnchor.constraint(equalTo: userHeader.bottomAnchor, constant: 3.0),
        nameLabel.centerXAnchor.constraint(equalTo: userHeader.centerXAnchor),
        nameLabel.widthAnchor.constraint(equalTo: userHeader.widthAnchor),
      ])

      addBtn.addTarget(self, action: #selector(createDiscuss), for: .touchUpInside)
      cornerBack.addSubview(addBtn)
      NSLayoutConstraint.activate([
        addBtn.leftAnchor.constraint(equalTo: userHeader.rightAnchor, constant: 20.0),
        addBtn.topAnchor.constraint(equalTo: userHeader.topAnchor),
        addBtn.widthAnchor.constraint(equalToConstant: 50.0),
        addBtn.heightAnchor.constraint(equalToConstant: 50.0),
      ])
    } else {
      NSLayoutConstraint.activate([
        userHeader.leftAnchor.constraint(equalTo: cornerBack.leftAnchor, constant: 16),
        userHeader.centerYAnchor.constraint(equalTo: cornerBack.centerYAnchor),
        userHeader.widthAnchor.constraint(equalToConstant: 60),
        userHeader.heightAnchor.constraint(equalToConstant: 60),
      ])

      nameLabel.font = NEConstant.defaultTextFont(16)
      nameLabel.textAlignment = .left
      NSLayoutConstraint.activate([
        nameLabel.leftAnchor.constraint(equalTo: userHeader.rightAnchor, constant: 16.0),
        nameLabel.rightAnchor.constraint(equalTo: cornerBack.rightAnchor),
        nameLabel.centerYAnchor.constraint(equalTo: userHeader.centerYAnchor),
      ])
    }

    return header
  }

  override open func filterStackViewController() -> [UIViewController]? {
    navigationController?.viewControllers.filter {
      if $0.isKind(of: FunP2PChatViewController.self) || $0
        .isKind(of: FunUserSettingViewController.self) {
        return false
      }
      return true
    }
  }

  override func getPinMessageViewController(session: NIMSession) -> NEBasePinMessageViewController {
    FunPinMessageViewController(session: session)
  }
}
