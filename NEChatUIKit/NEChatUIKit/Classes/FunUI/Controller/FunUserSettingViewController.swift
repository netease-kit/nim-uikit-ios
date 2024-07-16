// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
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
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    for cellModel in viewModel.cellDatas {
      cellModel.cornerType = .none
    }
  }

  override func setupUI() {
    super.setupUI()
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
    userHeaderView.layer.cornerRadius = 4.0
    addButton.setImage(coreLoader.loadImage("fun_setting_add"), for: .normal)
    contentTable.rowHeight = 56
  }

  override open func headerView() -> UIView {
    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 117))
    headerView.backgroundColor = .clear
    let cornerBackView = UIView()
    cornerBackView.backgroundColor = .white
    cornerBackView.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(cornerBackView)
    NSLayoutConstraint.activate([
      cornerBackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
      cornerBackView.leftAnchor.constraint(equalTo: headerView.leftAnchor),
      cornerBackView.rightAnchor.constraint(equalTo: headerView.rightAnchor),
      cornerBackView.heightAnchor.constraint(equalToConstant: 109.0),
    ])

    cornerBackView.addSubview(userHeaderView)

    let tap = UITapGestureRecognizer()
    userHeaderView.addGestureRecognizer(tap)
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1

    if let url = viewModel.userInfo?.user?.avatar, !url.isEmpty {
      userHeaderView.sd_setImage(with: URL(string: url), completed: nil)
      userHeaderView.setTitle("")
      userHeaderView.backgroundColor = .clear
    } else if let name = viewModel.userInfo?.shortName(count: 2) {
      userHeaderView.sd_setImage(with: nil)
      userHeaderView.setTitle(name)
      userHeaderView.backgroundColor = UIColor.colorWithString(string: viewModel.userInfo?.user?.accountId)
    }

    nameLabel.text = viewModel.userInfo?.showName()
    cornerBackView.addSubview(nameLabel)

    if IMKitConfigCenter.shared.enableTeam {
      NSLayoutConstraint.activate([
        userHeaderView.leftAnchor.constraint(equalTo: cornerBackView.leftAnchor, constant: 22),
        userHeaderView.topAnchor.constraint(equalTo: cornerBackView.topAnchor, constant: 22),
        userHeaderView.widthAnchor.constraint(equalToConstant: 50),
        userHeaderView.heightAnchor.constraint(equalToConstant: 50),
      ])

      nameLabel.font = NEConstant.defaultTextFont(12)
      nameLabel.textAlignment = .center
      NSLayoutConstraint.activate([
        nameLabel.topAnchor.constraint(equalTo: userHeaderView.bottomAnchor, constant: 3.0),
        nameLabel.centerXAnchor.constraint(equalTo: userHeaderView.centerXAnchor),
        nameLabel.widthAnchor.constraint(equalTo: userHeaderView.widthAnchor),
      ])

      addButton.addTarget(self, action: #selector(createDiscuss), for: .touchUpInside)
      cornerBackView.addSubview(addButton)
      NSLayoutConstraint.activate([
        addButton.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 20.0),
        addButton.topAnchor.constraint(equalTo: userHeaderView.topAnchor),
        addButton.widthAnchor.constraint(equalToConstant: 50.0),
        addButton.heightAnchor.constraint(equalToConstant: 50.0),
      ])
    } else {
      NSLayoutConstraint.activate([
        userHeaderView.leftAnchor.constraint(equalTo: cornerBackView.leftAnchor, constant: 16),
        userHeaderView.centerYAnchor.constraint(equalTo: cornerBackView.centerYAnchor),
        userHeaderView.widthAnchor.constraint(equalToConstant: 60),
        userHeaderView.heightAnchor.constraint(equalToConstant: 60),
      ])

      nameLabel.font = NEConstant.defaultTextFont(16)
      nameLabel.textAlignment = .left
      NSLayoutConstraint.activate([
        nameLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 16.0),
        nameLabel.rightAnchor.constraint(equalTo: cornerBackView.rightAnchor),
        nameLabel.centerYAnchor.constraint(equalTo: userHeaderView.centerYAnchor),
      ])
    }

    return headerView
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

  override open func didLoadData() {
    viewModel.setFunType()
  }

  override func getPinMessageViewController(conversationId: String) -> NEBasePinMessageViewController {
    FunPinMessageViewController(conversationId: conversationId)
  }
}
