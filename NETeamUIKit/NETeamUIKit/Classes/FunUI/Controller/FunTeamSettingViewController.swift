// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamSettingViewController: NEBaseTeamSettingViewController {
  /// 顶部背景视图
  lazy var backView: UIView = {
    let backView = UIView()
    backView.frame = CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: 188)
    return backView
  }()

  /// 圆角视图
  lazy var cornerView: UIView = {
    let cornerView = UIView()
    return cornerView
  }()

  /// 群信息跳转下一级页面指示箭头
  lazy var arrowImageView: UIImageView = {
    let arrowImageView = UIImageView()
    arrowImageView.translatesAutoresizingMaskIntoConstraints = false
    arrowImageView.image = coreLoader.loadImage("arrowRight")
    return arrowImageView
  }()

  /// 分隔线
  lazy var dividerLineView: UIView = {
    let dividerLineView = UIView()
    dividerLineView.translatesAutoresizingMaskIntoConstraints = false
    dividerLineView.backgroundColor = NEConstant.hexRGB(0xF5F8FC)
    return dividerLineView
  }()

  /// 成员列表跳转下一级页面指示箭头
  public var memberArrowImageView: UIImageView = {
    let memberArrowImageView = UIImageView()
    memberArrowImageView.translatesAutoresizingMaskIntoConstraints = false
    memberArrowImageView.image = coreLoader.loadImage("arrowRight")
    return memberArrowImageView
  }()

  /// 群成员列表按钮
  public var memberListButton: UIButton = {
    let memberListButton = UIButton()
    memberListButton.translatesAutoresizingMaskIntoConstraints = false
    return memberListButton
  }()

  /// 群信息页面跳转按钮
  public var infoButton: UIButton = {
    let infoButton = UIButton()
    infoButton.translatesAutoresizingMaskIntoConstraints = false
    return infoButton
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "FunTeamSettingViewController"
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: FunTeamArrowSettingCell.self,
      SettingCellType.SettingSwitchCell.rawValue: FunTeamSettingSwitchCell.self,
      SettingCellType.SettingSelectCell.rawValue: FunTeamSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func reloadSectionData() {
    for setionModel in viewModel.sectionData {
      for cellModel in setionModel.cellModels {
        cellModel.cornerType = .none
        if cellModel.type == SettingCellType.SettingSelectCell.rawValue {
          cellModel.rowHeight = 78
        } else if cellModel.type == SettingCellType.SettingArrowCell.rawValue || cellModel.type == SettingCellType.SettingSwitchCell.rawValue {
          cellModel.rowHeight = 56
        }
      }
    }
  }

  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = .funTeamBackgroundColor
    teamHeaderView.layer.cornerRadius = 4.0
    addButton.setImage(coreLoader.loadImage("fun_add"), for: .normal)
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
  }

  /// 获取顶部
  override open func getHeaderView() -> UIView {
    backView.addSubview(cornerView)
    cornerView.backgroundColor = .white
    cornerView.clipsToBounds = true
    cornerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      cornerView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 0),
      cornerView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: 0),
      cornerView.topAnchor.constraint(equalTo: backView.topAnchor),
      cornerView.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
    ])

    cornerView.addSubview(teamHeaderView)
    NSLayoutConstraint.activate([
      teamHeaderView.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16),
      teamHeaderView.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 16),
      teamHeaderView.widthAnchor.constraint(equalToConstant: 50),
      teamHeaderView.heightAnchor.constraint(equalToConstant: 50),
    ])

    setTeamHeaderInfo()

    cornerView.addSubview(teamNameLabel)
    NSLayoutConstraint.activate([
      teamNameLabel.leftAnchor.constraint(equalTo: teamHeaderView.rightAnchor, constant: 16),
      teamNameLabel.centerYAnchor.constraint(equalTo: teamHeaderView.centerYAnchor),
      teamNameLabel.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -50),
    ])

    cornerView.addSubview(arrowImageView)
    NSLayoutConstraint.activate([
      arrowImageView.centerYAnchor.constraint(equalTo: teamHeaderView.centerYAnchor),
      arrowImageView.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -16),
    ])

    cornerView.addSubview(dividerLineView)
    NSLayoutConstraint.activate([
      dividerLineView.heightAnchor.constraint(equalToConstant: 1.0),
      dividerLineView.rightAnchor.constraint(equalTo: cornerView.rightAnchor),
      dividerLineView.leftAnchor.constraint(equalTo: teamHeaderView.leftAnchor, constant: 0),
      dividerLineView.topAnchor.constraint(equalTo: teamHeaderView.bottomAnchor, constant: 16.0),
    ])

    cornerView.addSubview(memberLabel)
    NSLayoutConstraint.activate([
      memberLabel.leftAnchor.constraint(equalTo: dividerLineView.leftAnchor),
      memberLabel.topAnchor.constraint(equalTo: dividerLineView.bottomAnchor, constant: 16),
    ])

    if teamSettingType == .Senior {
      memberLabel.text = localizable("group_memmber")
    } else {
      memberLabel.text = localizable("discuss_mebmer")
    }

    cornerView.addSubview(memberArrowImageView)
    NSLayoutConstraint.activate([
      memberArrowImageView.rightAnchor.constraint(equalTo: arrowImageView.rightAnchor, constant: 0),
      memberArrowImageView.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
    ])

    cornerView.addSubview(memberListButton)
    NSLayoutConstraint.activate([
      memberListButton.leftAnchor.constraint(equalTo: memberLabel.leftAnchor),
      memberListButton.rightAnchor.constraint(equalTo: memberArrowImageView.rightAnchor),
      memberListButton.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
      memberListButton.heightAnchor.constraint(equalToConstant: 50),
    ])
    memberListButton.addTarget(self, action: #selector(toMemberList), for: .touchUpInside)

    cornerView.addSubview(memberCountLabel)
    NSLayoutConstraint.activate([
      memberCountLabel.rightAnchor.constraint(equalTo: memberArrowImageView.leftAnchor, constant: -8),
      memberCountLabel.centerYAnchor.constraint(equalTo: memberArrowImageView.centerYAnchor),
    ])
    memberCountLabel.text = "\(viewModel.teamInfoModel?.team?.memberCount ?? 0)"

    cornerView.addSubview(addButton)
    addButtonWidth = addButton.widthAnchor.constraint(equalToConstant: 36)
    addButtonWidth?.isActive = true
    addButtonLeftMargin = addButton.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16.0)
    NSLayoutConstraint.activate([
      addButtonLeftMargin!,
      addButton.topAnchor.constraint(equalTo: memberListButton.bottomAnchor, constant: 0),
    ])
    addButton.addTarget(self, action: #selector(addUser), for: .touchUpInside)

    if viewModel.isNormalTeam() == false, viewModel.isOwner() == false,
       let inviteMode = viewModel.teamInfoModel?.team?.inviteMode, let member = viewModel.memberInTeam, inviteMode == .TEAM_INVITE_MODE_MANAGER, member.memberRole != .TEAM_MEMBER_ROLE_MANAGER {
      addButtonWidth?.constant = 0
      addButton.isHidden = true
    }

    setupUserInfoCollection(cornerView)

    cornerView.addSubview(infoButton)
    NSLayoutConstraint.activate([
      infoButton.leftAnchor.constraint(equalTo: teamHeaderView.leftAnchor),
      infoButton.topAnchor.constraint(equalTo: teamHeaderView.topAnchor),
      infoButton.bottomAnchor.constraint(equalTo: teamHeaderView.bottomAnchor),
      infoButton.rightAnchor.constraint(equalTo: arrowImageView.rightAnchor),
    ])
    infoButton.addTarget(self, action: #selector(toInfoView), for: .touchUpInside)

    return backView
  }

  override open func getFooterView() -> UIView? {
    guard let title = getBottomText() else {
      return nil
    }
    let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64.0))
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    footerView.addSubview(button)
    button.backgroundColor = .white
    button.clipsToBounds = true
    button.setTitleColor(NEConstant.hexRGB(0xE6605C), for: .normal)
    button.titleLabel?.font = NEConstant.defaultTextFont(16.0)
    button.setTitle(title, for: .normal)
    button.addTarget(self, action: #selector(removeTeamForMyself), for: .touchUpInside)
    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 0),
      button.rightAnchor.constraint(equalTo: footerView.rightAnchor, constant: 0),
      button.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 12),
      button.heightAnchor.constraint(equalToConstant: 56),
    ])
    return footerView
  }

  override open func setupUserInfoCollection(_ cornerView: UIView) {
    cornerView.addSubview(userinfoCollectionView)
    NSLayoutConstraint.activate([
      userinfoCollectionView.leftAnchor.constraint(equalTo: addButton.rightAnchor, constant: 16),
      userinfoCollectionView.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
      userinfoCollectionView.rightAnchor.constraint(
        equalTo: cornerView.rightAnchor,
        constant: -16
      ),
      userinfoCollectionView.heightAnchor.constraint(equalToConstant: 36),
    ])

    userinfoCollectionView.register(
      FunTeamUserCell.self,
      forCellWithReuseIdentifier: "\(FunTeamUserCell.self)"
    )
  }

  override open func checkoutAddShowOrHide() {
    if viewModel.isNormalTeam() == false, viewModel.isOwner() == false,
       let inviteMode = viewModel.teamInfoModel?.team?.inviteMode, inviteMode == .TEAM_INVITE_MODE_MANAGER {
      if let member = viewModel.memberInTeam, member.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
        addButton.isHidden = false
        addButtonWidth?.constant = 36.0
        addButtonLeftMargin?.constant = 16
        checkMemberCountLimit()
      } else {
        addButton.isHidden = true
        addButtonWidth?.constant = 0
        addButtonLeftMargin?.constant = 0
      }
    } else {
      checkMemberCountLimit()
    }
  }

  func checkMemberCountLimit() {
    if viewModel.teamInfoModel?.team?.memberLimit == viewModel.teamInfoModel?.team?.memberCount {
      addButton.isHidden = true
      addButtonWidth?.constant = 0
      addButtonLeftMargin?.constant = 0
    } else {
      addButton.isHidden = false
      addButtonWidth?.constant = 36.0
      addButtonLeftMargin?.constant = 16
    }
  }

  override open func toInfoView() {
    let info = FunTeamInfoViewController(team: viewModel.teamInfoModel?.team)
    navigationController?.pushViewController(info, animated: true)
  }

  override open func didClickChangeNick() {
    let nick = FunTeamNameViewController()
    nick.type = .NickName
    nick.team = viewModel.teamInfoModel?.team
    nick.teamMember = viewModel.memberInTeam
    navigationController?.pushViewController(nick, animated: true)
  }

  override open func didChangeInviteModeClick(_ model: SettingCellModel) {
    weak var weakSelf = self

    let allAction = NECustomAlertAction(title: localizable("team_all")) {
      weakSelf?.updateInviteModeAllAction(model)
    }

    let ownerAction = NECustomAlertAction(title: localizable("team_owner")) {
      weakSelf?.updateInviteModeOwnerAction(model)
    }

    showCustomActionSheet([ownerAction, allAction])
  }

  override open func didUpdateTeamInfoClick(_ model: SettingCellModel) {
    weak var weakSelf = self

    let allAction = NECustomAlertAction(title: localizable("team_all")) {
      weakSelf?.updateTeamInfoAllAction(model)
    }

    let ownerAction = NECustomAlertAction(title: localizable("team_owner")) {
      weakSelf?.updateTeamInfoOwnerAction(model)
    }

    showCustomActionSheet([ownerAction, allAction])
  }

  override open func didClickHistoryMessage() {
    guard let tid = teamId else {
      return
    }
    Router.shared.use(
      SearchMessageRouter,
      parameters: ["nav": navigationController as Any, "teamId": tid, "teamInfo": viewModel.teamInfoModel as Any],
      closure: nil
    )
  }

  override open func didClickTeamManage() {
    let manageTeam = FunTeamManagerController()
    manageTeam.viewModel.teamInfoModel = viewModel.teamInfoModel
    navigationController?.pushViewController(manageTeam, animated: true)
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(FunTeamUserCell.self)",
      for: indexPath
    ) as? FunTeamUserCell {
      if let user = viewModel.teamInfoModel?.users[indexPath.row] {
        cell.user = user
      }
      return cell
    }
    return UICollectionViewCell()
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    if indexPath.row == 0 {
      return CGSize(width: 36, height: 36)
    }
    return CGSize(width: 36 + 16, height: 36)
  }

  override open func toMemberList() {
    let memberController = FunTeamMembersController(teamId: viewModel.teamInfoModel?.team?.teamId)
    navigationController?.pushViewController(memberController, animated: true)
  }
}
