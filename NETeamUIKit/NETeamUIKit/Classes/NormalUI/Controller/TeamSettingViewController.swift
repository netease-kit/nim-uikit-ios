
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class TeamSettingViewController: NEBaseTeamSettingViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
    className = "TeamSettingViewController"
    cellClassDic = [
      SettingCellType.SettingArrowCell.rawValue: TeamArrowSettingCell.self,
      SettingCellType.SettingSwitchCell.rawValue: TeamSettingSwitchCell.self,
      SettingCellType.SettingSelectCell.rawValue: TeamSettingSelectCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupUI() {
    super.setupUI()
    teamHeader.layer.cornerRadius = 21.0
    addBtn.setImage(coreLoader.loadImage("add"), for: .normal)
  }

  override open func getHeaderView() -> UIView {
    let back = UIView()
    back.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 172)
    let cornerView = UIView()
    back.addSubview(cornerView)
    cornerView.backgroundColor = .white
    cornerView.clipsToBounds = true
    cornerView.translatesAutoresizingMaskIntoConstraints = false
    cornerView.layer.cornerRadius = 8.0
    NSLayoutConstraint.activate([
      cornerView.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 20),
      cornerView.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -20),
      cornerView.bottomAnchor.constraint(equalTo: back.bottomAnchor),
      cornerView.heightAnchor.constraint(equalToConstant: 160),
    ])

    cornerView.addSubview(teamHeader)
    NSLayoutConstraint.activate([
      teamHeader.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16),
      teamHeader.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 16),
      teamHeader.widthAnchor.constraint(equalToConstant: 42),
      teamHeader.heightAnchor.constraint(equalToConstant: 42),
    ])
    if let url = viewmodel.teamInfoModel?.team?.avatarUrl, !url.isEmpty {
      print("icon url : ", url)
      teamHeader.sd_setImage(with: URL(string: url), completed: nil)
    } else {
      if let tid = teamId {
        if let name = viewmodel.teamInfoModel?.team?.getShowName() {
          teamHeader.setTitle(name)
        }
        teamHeader.backgroundColor = UIColor.colorWithString(string: "\(tid)")
      }
    }

    teamNameLabel.text = viewmodel.teamInfoModel?.team?.getShowName()

    cornerView.addSubview(teamNameLabel)
    NSLayoutConstraint.activate([
      teamNameLabel.leftAnchor.constraint(equalTo: teamHeader.rightAnchor, constant: 11),
      teamNameLabel.centerYAnchor.constraint(equalTo: teamHeader.centerYAnchor),
      teamNameLabel.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -34),
    ])

    let arrow = UIImageView()
    arrow.translatesAutoresizingMaskIntoConstraints = false
    arrow.image = coreLoader.loadImage("arrowRight")
    cornerView.addSubview(arrow)
    NSLayoutConstraint.activate([
      arrow.centerYAnchor.constraint(equalTo: teamHeader.centerYAnchor),
      arrow.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -16),
    ])

    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = NEConstant.hexRGB(0xF5F8FC)
    cornerView.addSubview(line)
    NSLayoutConstraint.activate([
      line.heightAnchor.constraint(equalToConstant: 1.0),
      line.rightAnchor.constraint(equalTo: cornerView.rightAnchor),
      line.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16.0),
      line.topAnchor.constraint(equalTo: teamHeader.bottomAnchor, constant: 12.0),
    ])

    let memberLabel = UILabel()
    cornerView.addSubview(memberLabel)
    memberLabel.translatesAutoresizingMaskIntoConstraints = false
    memberLabel.textColor = NEConstant.hexRGB(0x333333)
    memberLabel.font = NEConstant.defaultTextFont(16.0)
    cornerView.addSubview(memberLabel)
    NSLayoutConstraint.activate([
      memberLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      memberLabel.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 12),
    ])

    if teamSettingType == .Senior {
      memberLabel.text = localizable("group_memmber")
    } else {
      memberLabel.text = localizable("discuss_mebmer")
    }

    let memberArrow = UIImageView()
    cornerView.addSubview(memberArrow)
    memberArrow.translatesAutoresizingMaskIntoConstraints = false
    memberArrow.image = coreLoader.loadImage("arrowRight")
    NSLayoutConstraint.activate([
      memberArrow.rightAnchor.constraint(equalTo: arrow.rightAnchor),
      memberArrow.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
    ])

    let memberListBtn = UIButton()
    memberListBtn.accessibilityIdentifier = "id.member"
    cornerView.addSubview(memberListBtn)
    memberListBtn.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      memberListBtn.leftAnchor.constraint(equalTo: memberLabel.leftAnchor),
      memberListBtn.rightAnchor.constraint(equalTo: memberArrow.rightAnchor),
      memberListBtn.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
      memberListBtn.heightAnchor.constraint(equalToConstant: 40),
    ])
    memberListBtn.addTarget(self, action: #selector(toMemberList), for: .touchUpInside)

    cornerView.addSubview(memberCountLabel)
    NSLayoutConstraint.activate([
      memberCountLabel.rightAnchor.constraint(equalTo: memberArrow.leftAnchor, constant: -2),
      memberCountLabel.centerYAnchor.constraint(equalTo: memberArrow.centerYAnchor),
    ])
    memberCountLabel.text = "\(viewmodel.teamInfoModel?.team?.memberNumber ?? 0)"

    cornerView.addSubview(addBtn)
    addBtnWidth = addBtn.widthAnchor.constraint(equalToConstant: 32)
    addBtnWidth?.isActive = true
    addBtnLeftMargin = addBtn.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16.0)
    NSLayoutConstraint.activate([
      addBtnLeftMargin!,
      addBtn.topAnchor.constraint(equalTo: memberLabel.bottomAnchor, constant: 12),
    ])
    addBtn.addTarget(self, action: #selector(addUser), for: .touchUpInside)

    if viewmodel.isNormalTeam() == false, viewmodel.isOwner() == false,
       let inviteMode = viewmodel.teamInfoModel?.team?.inviteMode, let member = viewmodel.memberInTeam, inviteMode == .manager, member.type != .manager {
      addBtnWidth?.constant = 0
      addBtn.isHidden = true
    }

    setupUserInfoCollection(cornerView)

    let infoBtn = UIButton()
    infoBtn.translatesAutoresizingMaskIntoConstraints = false
    cornerView.addSubview(infoBtn)
    NSLayoutConstraint.activate([
      infoBtn.leftAnchor.constraint(equalTo: teamHeader.leftAnchor),
      infoBtn.topAnchor.constraint(equalTo: teamHeader.topAnchor),
      infoBtn.bottomAnchor.constraint(equalTo: teamHeader.bottomAnchor),
      infoBtn.rightAnchor.constraint(equalTo: arrow.rightAnchor),
    ])
    infoBtn.addTarget(self, action: #selector(toInfoView), for: .touchUpInside)

    return back
  }

  override open func checkoutAddShowOrHide() {
    if viewmodel.isNormalTeam() == false, viewmodel.isOwner() == false,
       let inviteMode = viewmodel.teamInfoModel?.team?.inviteMode, inviteMode == .manager {
      if let member = viewmodel.memberInTeam, member.type == .manager {
        addBtn.isHidden = false
        addBtnWidth?.constant = 36.0
        addBtnLeftMargin?.constant = 16
        checkMemberCountLimit()
      } else {
        addBtn.isHidden = true
        addBtnWidth?.constant = 0
        addBtnLeftMargin?.constant = 0
      }
    } else {
      checkMemberCountLimit()
    }
  }

  func checkMemberCountLimit() {
    if viewmodel.teamInfoModel?.team?.level == viewmodel.teamInfoModel?.team?.memberNumber {
      addBtn.isHidden = true
      addBtnWidth?.constant = 0
      addBtnLeftMargin?.constant = 0
    } else {
      addBtn.isHidden = false
      addBtnWidth?.constant = 36.0
      addBtnLeftMargin?.constant = 16
    }
  }

  override open func getFooterView() -> UIView? {
    guard let title = getBottomText() else {
      return nil
    }
    let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64.0))
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    footer.addSubview(button)
    button.backgroundColor = .white
    button.clipsToBounds = true
    button.setTitleColor(NEConstant.hexRGB(0xE6605C), for: .normal)
    button.titleLabel?.font = NEConstant.defaultTextFont(16.0)
    button.setTitle(title, for: .normal)
    button.addTarget(self, action: #selector(removeTeamForMyself), for: .touchUpInside)
    button.layer.cornerRadius = 8.0
    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: footer.leftAnchor, constant: 20),
      button.rightAnchor.constraint(equalTo: footer.rightAnchor, constant: -20),
      button.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
      button.heightAnchor.constraint(equalToConstant: 40),
    ])
    return footer
  }

  override open func setupUserInfoCollection(_ cornerView: UIView) {
    cornerView.addSubview(userinfoCollection)
    NSLayoutConstraint.activate([
      userinfoCollection.leftAnchor.constraint(equalTo: addBtn.rightAnchor, constant: 15),
      userinfoCollection.centerYAnchor.constraint(equalTo: addBtn.centerYAnchor),
      userinfoCollection.rightAnchor.constraint(
        equalTo: cornerView.rightAnchor,
        constant: -15
      ),
      userinfoCollection.heightAnchor.constraint(equalToConstant: 32),
    ])

    userinfoCollection.register(
      TeamUserCell.self,
      forCellWithReuseIdentifier: "\(TeamUserCell.self)"
    )
  }

  // MARK: objc 方法

  override open func toInfoView() {
    let info = TeamInfoViewController(team: viewmodel.teamInfoModel?.team)
    navigationController?.pushViewController(info, animated: true)
  }

  override open func didClickChangeNick() {
    let nick = TeamNameViewController()
    nick.type = .NickName
    nick.team = viewmodel.teamInfoModel?.team
    nick.teamMember = viewmodel.memberInTeam
    navigationController?.pushViewController(nick, animated: true)
  }

  override open func didClickHistoryMessage() {
    guard let tid = teamId else {
      return
    }
    Router.shared.use(
      SearchMessageRouter,
      parameters: ["nav": navigationController as Any, "teamId": tid],
      closure: nil
    )
  }

  override open func didClickTeamManage() {
    let manageTeam = TeamManageController()
    manageTeam.managerUsers = getManaterUsers()
    manageTeam.viewmodel.teamInfoModel = viewmodel.teamInfoModel
    navigationController?.pushViewController(manageTeam, animated: true)
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(TeamUserCell.self)",
      for: indexPath
    ) as? TeamUserCell {
      if let user = viewmodel.teamInfoModel?.users[indexPath.row] {
        if let userId = user.nimUser?.userId, let nimUser = ChatUserCache.getUserInfo(userId) {
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
    let memberController = TeamMembersController(teamId: viewmodel.teamInfoModel?.team?.teamId)
    navigationController?.pushViewController(memberController, animated: true)
  }
}
