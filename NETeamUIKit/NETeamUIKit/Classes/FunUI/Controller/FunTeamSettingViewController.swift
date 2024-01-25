// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamSettingViewController: NEBaseTeamSettingViewController {
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
    fatalError("init(coder:) has not been implemented")
  }

  override open func reloadSectionData() {
    viewmodel.sectionData.forEach { setionModel in
      setionModel.cellModels.forEach { cellModel in
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
    teamHeader.layer.cornerRadius = 4.0
    addBtn.setImage(coreLoader.loadImage("fun_add"), for: .normal)
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
  }

  override open func getHeaderView() -> UIView {
    let back = UIView()
    back.frame = CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: 188)
    let cornerView = UIView()
    back.addSubview(cornerView)
    cornerView.backgroundColor = .white
    cornerView.clipsToBounds = true
    cornerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      cornerView.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 0),
      cornerView.rightAnchor.constraint(equalTo: back.rightAnchor, constant: 0),
      cornerView.topAnchor.constraint(equalTo: back.topAnchor),
      cornerView.bottomAnchor.constraint(equalTo: back.bottomAnchor),
    ])

    cornerView.addSubview(teamHeader)
    NSLayoutConstraint.activate([
      teamHeader.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16),
      teamHeader.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 16),
      teamHeader.widthAnchor.constraint(equalToConstant: 50),
      teamHeader.heightAnchor.constraint(equalToConstant: 50),
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
      teamNameLabel.leftAnchor.constraint(equalTo: teamHeader.rightAnchor, constant: 16),
      teamNameLabel.centerYAnchor.constraint(equalTo: teamHeader.centerYAnchor),
      teamNameLabel.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -50),
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
      line.leftAnchor.constraint(equalTo: teamHeader.leftAnchor, constant: 0),
      line.topAnchor.constraint(equalTo: teamHeader.bottomAnchor, constant: 16.0),
    ])

    let memberLabel = UILabel()
    cornerView.addSubview(memberLabel)
    memberLabel.translatesAutoresizingMaskIntoConstraints = false
    memberLabel.textColor = NEConstant.hexRGB(0x333333)
    memberLabel.font = NEConstant.defaultTextFont(16.0)
    cornerView.addSubview(memberLabel)
    NSLayoutConstraint.activate([
      memberLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      memberLabel.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 16),
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
      memberArrow.rightAnchor.constraint(equalTo: arrow.rightAnchor, constant: 0),
      memberArrow.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
    ])

    let memberListBtn = UIButton()
    cornerView.addSubview(memberListBtn)
    memberListBtn.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      memberListBtn.leftAnchor.constraint(equalTo: memberLabel.leftAnchor),
      memberListBtn.rightAnchor.constraint(equalTo: memberArrow.rightAnchor),
      memberListBtn.centerYAnchor.constraint(equalTo: memberLabel.centerYAnchor),
      memberListBtn.heightAnchor.constraint(equalToConstant: 50),
    ])
    memberListBtn.addTarget(self, action: #selector(toMemberList), for: .touchUpInside)

    cornerView.addSubview(memberCountLabel)
    NSLayoutConstraint.activate([
      memberCountLabel.rightAnchor.constraint(equalTo: memberArrow.leftAnchor, constant: -8),
      memberCountLabel.centerYAnchor.constraint(equalTo: memberArrow.centerYAnchor),
    ])
    memberCountLabel.text = "\(viewmodel.teamInfoModel?.team?.memberNumber ?? 0)"

    cornerView.addSubview(addBtn)
    addBtnWidth = addBtn.widthAnchor.constraint(equalToConstant: 36)
    addBtnWidth?.isActive = true
    addBtnLeftMargin = addBtn.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16.0)
    NSLayoutConstraint.activate([
      addBtnLeftMargin!,
      addBtn.topAnchor.constraint(equalTo: memberListBtn.bottomAnchor, constant: 0),
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
    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: footer.leftAnchor, constant: 0),
      button.rightAnchor.constraint(equalTo: footer.rightAnchor, constant: 0),
      button.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
      button.heightAnchor.constraint(equalToConstant: 56),
    ])
    return footer
  }

  override open func setupUserInfoCollection(_ cornerView: UIView) {
    cornerView.addSubview(userinfoCollection)
    NSLayoutConstraint.activate([
      userinfoCollection.leftAnchor.constraint(equalTo: addBtn.rightAnchor, constant: 16),
      userinfoCollection.centerYAnchor.constraint(equalTo: addBtn.centerYAnchor),
      userinfoCollection.rightAnchor.constraint(
        equalTo: cornerView.rightAnchor,
        constant: -16
      ),
      userinfoCollection.heightAnchor.constraint(equalToConstant: 36),
    ])

    userinfoCollection.register(
      FunTeamUserCell.self,
      forCellWithReuseIdentifier: "\(FunTeamUserCell.self)"
    )
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

  // MARK: objc 方法

  override open func toInfoView() {
    let info = FunTeamInfoViewController(team: viewmodel.teamInfoModel?.team)
    navigationController?.pushViewController(info, animated: true)
  }

  override open func didClickChangeNick() {
    let nick = FunTeamNameViewController()
    nick.type = .NickName
    nick.team = viewmodel.teamInfoModel?.team
    nick.teamMember = viewmodel.memberInTeam
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
      parameters: ["nav": navigationController as Any, "teamId": tid],
      closure: nil
    )
  }

  override open func didClickTeamManage() {
    let manageTeam = FunTeamManageController()
    manageTeam.managerUsers = getManaterUsers()
    manageTeam.viewmodel.teamInfoModel = viewmodel.teamInfoModel
    navigationController?.pushViewController(manageTeam, animated: true)
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(FunTeamUserCell.self)",
      for: indexPath
    ) as? FunTeamUserCell {
      if let user = viewmodel.teamInfoModel?.users[indexPath.row] {
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
    let memberController = FunTeamMembersController(teamId: viewmodel.teamInfoModel?.team?.teamId)
    navigationController?.pushViewController(memberController, animated: true)
  }
}
