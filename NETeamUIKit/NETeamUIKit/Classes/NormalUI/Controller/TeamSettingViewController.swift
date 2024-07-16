
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class TeamSettingViewController: NEBaseTeamSettingViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "TeamSettingViewController"
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: TeamArrowSettingCell.self,
      SettingCellType.SettingSwitchCell.rawValue: TeamSettingSwitchCell.self,
      SettingCellType.SettingSelectCell.rawValue: TeamSettingSelectCell.self,
    ]
  }

  /// 背景视图
  public lazy var backView: UIView = {
    let backView = UIView()
    backView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 172)
    return backView
  }()

  /// 圆角视图
  public lazy var cornerView: UIView = {
    let cornerView = UIView()
    cornerView.backgroundColor = .white
    cornerView.clipsToBounds = true
    cornerView.translatesAutoresizingMaskIntoConstraints = false
    cornerView.layer.cornerRadius = 8.0
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

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor

    teamHeaderView.layer.cornerRadius = 21.0
    addButton.setImage(coreLoader.loadImage("add"), for: .normal)
  }

  /// 获取顶部视图
  override open func getHeaderView() -> UIView {
    backView.addSubview(cornerView)
    NSLayoutConstraint.activate([
      cornerView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 20),
      cornerView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -20),
      cornerView.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
      cornerView.heightAnchor.constraint(equalToConstant: 160),
    ])

    cornerView.addSubview(teamHeaderView)
    NSLayoutConstraint.activate([
      teamHeaderView.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16),
      teamHeaderView.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 16),
      teamHeaderView.widthAnchor.constraint(equalToConstant: 42),
      teamHeaderView.heightAnchor.constraint(equalToConstant: 42),
    ])

    setTeamHeaderInfo()

    cornerView.addSubview(teamNameLabel)
    NSLayoutConstraint.activate([
      teamNameLabel.leftAnchor.constraint(equalTo: teamHeaderView.rightAnchor, constant: 11),
      teamNameLabel.centerYAnchor.constraint(equalTo: teamHeaderView.centerYAnchor),
      teamNameLabel.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -34),
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
      dividerLineView.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16.0),
      dividerLineView.topAnchor.constraint(equalTo: teamHeaderView.bottomAnchor, constant: 12.0),
    ])

    cornerView.addSubview(memberLabel)
    NSLayoutConstraint.activate([
      memberLabel.leftAnchor.constraint(equalTo: dividerLineView.leftAnchor),
      memberLabel.topAnchor.constraint(equalTo: dividerLineView.bottomAnchor, constant: 12),
    ])

    if teamSettingType == .Senior {
      memberLabel.text = localizable("group_memmber")
    } else {
      memberLabel.text = localizable("discuss_mebmer")
    }

    cornerView.addSubview(memberArrowImageView)
    NSLayoutConstraint.activate([
      memberArrowImageView.rightAnchor.constraint(equalTo: arrowImageView.rightAnchor),
      memberArrowImageView.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
    ])

    cornerView.addSubview(memberListButton)
    memberListButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      memberListButton.leftAnchor.constraint(equalTo: memberLabel.leftAnchor),
      memberListButton.rightAnchor.constraint(equalTo: memberArrowImageView.rightAnchor),
      memberListButton.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
      memberListButton.heightAnchor.constraint(equalToConstant: 40),
    ])
    memberListButton.addTarget(self, action: #selector(toMemberList), for: .touchUpInside)

    cornerView.addSubview(memberCountLabel)
    NSLayoutConstraint.activate([
      memberCountLabel.rightAnchor.constraint(equalTo: memberArrowImageView.leftAnchor, constant: -2),
      memberCountLabel.centerYAnchor.constraint(equalTo: memberArrowImageView.centerYAnchor),
    ])
    memberCountLabel.text = "\(viewModel.teamInfoModel?.team?.memberCount ?? 0)"

    cornerView.addSubview(addButton)
    addButtonWidth = addButton.widthAnchor.constraint(equalToConstant: 32)
    addButtonWidth?.isActive = true
    addButtonLeftMargin = addButton.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16.0)
    NSLayoutConstraint.activate([
      addButtonLeftMargin!,
      addButton.topAnchor.constraint(equalTo: memberLabel.bottomAnchor, constant: 12),
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
    button.layer.cornerRadius = 8.0
    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 20),
      button.rightAnchor.constraint(equalTo: footerView.rightAnchor, constant: -20),
      button.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 12),
      button.heightAnchor.constraint(equalToConstant: 40),
    ])
    return footerView
  }

  override open func setupUserInfoCollection(_ cornerView: UIView) {
    cornerView.addSubview(userinfoCollectionView)
    NSLayoutConstraint.activate([
      userinfoCollectionView.leftAnchor.constraint(equalTo: addButton.rightAnchor, constant: 15),
      userinfoCollectionView.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
      userinfoCollectionView.rightAnchor.constraint(
        equalTo: cornerView.rightAnchor,
        constant: -15
      ),
      userinfoCollectionView.heightAnchor.constraint(equalToConstant: 32),
    ])

    userinfoCollectionView.register(
      TeamUserCell.self,
      forCellWithReuseIdentifier: "\(TeamUserCell.self)"
    )
  }

  // MARK: objc 方法

  override open func toInfoView() {
    let info = TeamInfoViewController(team: viewModel.teamInfoModel?.team)
    navigationController?.pushViewController(info, animated: true)
  }

  override open func didClickChangeNick() {
    let nick = TeamNameViewController()
    nick.type = .NickName
    nick.team = viewModel.teamInfoModel?.team
    nick.teamMember = viewModel.memberInTeam
    navigationController?.pushViewController(nick, animated: true)
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
    let manageTeam = TeamManagerController()
    manageTeam.viewModel.teamInfoModel = viewModel.teamInfoModel
    navigationController?.pushViewController(manageTeam, animated: true)
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(TeamUserCell.self)",
      for: indexPath
    ) as? TeamUserCell {
      if let user = viewModel.teamInfoModel?.users[indexPath.row] {
        // 从缓存中获取用户信息
        if let userId = user.nimUser?.user?.accountId, let nimUser = NEFriendUserCache.shared.getFriendInfo(userId) {
          user.nimUser = nimUser
        }
        cell.user = user
      }
      return cell
    }
    return UICollectionViewCell()
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 47.0, height: 32)
  }

  override open func toMemberList() {
    let memberController = TeamMembersController(teamId: viewModel.teamInfoModel?.team?.teamId)
    navigationController?.pushViewController(memberController, animated: true)
  }
}
