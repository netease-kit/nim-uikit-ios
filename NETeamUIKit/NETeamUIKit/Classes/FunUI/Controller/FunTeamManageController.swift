//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunTeamManageController: NEBaseTeamManageController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: FunTeamSettingLabelArrowCell.self,
      SettingCellType.SettingSwitchCell.rawValue: FunTeamSettingSwitchCell.self,
      SettingCellType.SettingSelectCell.rawValue: FunTeamSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
  }

  override open func reloadSectionData() {
    viewmodel.sectionData.forEach { setionModel in
      setionModel.cellModels.forEach { cellModel in
        cellModel.cornerType = .none
        if cellModel.rowHeight > 70 {
          cellModel.rowHeight = 78
        } else {
          cellModel.rowHeight = 56
        }
      }
    }
  }

  override open func getFooterView() -> UIView? {
    let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64.0))
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    footer.addSubview(button)
    button.backgroundColor = .white
    button.clipsToBounds = true
    button.setTitleColor(NEConstant.hexRGB(0xE6605C), for: .normal)
    button.titleLabel?.font = NEConstant.defaultTextFont(16.0)
    button.setTitle(localizable("transfer_owner"), for: .normal)
    button.addTarget(self, action: #selector(transferOwner), for: .touchUpInside)
    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: footer.leftAnchor, constant: 0),
      button.rightAnchor.constraint(equalTo: footer.rightAnchor, constant: 0),
      button.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
      button.heightAnchor.constraint(equalToConstant: 56),
    ])
    return footer
  }

  override open func didManagerClick() {
    let controller = FunTeamManagerListController()
    controller.teamId = viewmodel.teamInfoModel?.team?.teamId
    navigationController?.pushViewController(controller, animated: true)
  }
}
