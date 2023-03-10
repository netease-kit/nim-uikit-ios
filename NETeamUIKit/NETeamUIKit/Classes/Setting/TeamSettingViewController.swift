
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonUIKit
import NECoreIMKit
import NIMSDK

@objc
public enum TeamSettingType: Int {
  case Discuss = 0
  case Senior = 1
}

@objcMembers
public class TeamSettingViewController: NEBaseViewController, UICollectionViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource,
  UITableViewDelegate {
  public let viewmodel = TeamSettingViewModel()

  public var teamId: String?

  var addBtnWidth: NSLayoutConstraint?

  public var teamSettingType: TeamSettingType = .Discuss

  public var isSeniorDiscuss = false // 是否是高级群扩展的讨论组

  private let className = "TeamSettingViewController"

  public var cellClassDic = [
    SettingCellType.SettingArrowCell.rawValue: TeamArrowSettingCell.self,
    SettingCellType.SettingSwitchCell.rawValue: TeamSettingSwitchCell.self,
    SettingCellType.SettingSelectCell.rawValue: TeamSettingSelectCell.self,
  ]

  lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    table
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  lazy var teamHeader: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(16.0)
    imageView.layer.cornerRadius = 21.0
    return imageView
  }()

  lazy var teamNameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = NEConstant.hexRGB(0x333333)
    return label
  }()

  lazy var memberCountLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = NEConstant.hexRGB(0x999999)
    return label
  }()

  lazy var userinfoCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .horizontal
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    return collection
  }()

  lazy var addBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("add"), for: .normal)
    return button
  }()

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let model = viewmodel.teamInfoModel {
      if let url = model.team?.avatarUrl {
        teamHeader.sd_setImage(with: URL(string: url))
      }
      if let name = model.team?.teamName {
        teamNameLabel.text = name
      }
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    title = localizable("setting")
    weak var weakSelf = self
    viewmodel.delegate = self
    if let tid = teamId {
      viewmodel.getTeamInfo(tid) { error in
        NELog.infoLog(
          ModuleName + " " + self.className,
          desc: "CALLBACK getTeamInfo " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          if let type = weakSelf?.viewmodel.teamInfoModel?.team?.type {
            if type == .normal {
              weakSelf?.teamSettingType = .Discuss
            } else if type == .advanced {
              if let custom = weakSelf?.viewmodel.teamInfoModel?.team?.clientCustomInfo, custom.contains(discussTeamKey) {
                weakSelf?.teamSettingType = .Discuss
                weakSelf?.isSeniorDiscuss = true
              } else {
                weakSelf?.teamSettingType = .Senior
              }
            }
          }
          weakSelf?.contentTable.tableHeaderView = weakSelf?.getHeaderView()
          weakSelf?.contentTable.tableFooterView = weakSelf?.getFooterView()
          weakSelf?.contentTable.reloadData()
          weakSelf?.userinfoCollection.reloadData()
        }
      }
    }
    // Do any additional setup after loading the view.
    setupUI()
  }

  func setupUI() {
    view.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    cellClassDic.forEach { (key: Int, value: BaseTeamSettingCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  func getHeaderView() -> UIView {
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
    if let url = viewmodel.teamInfoModel?.team?.avatarUrl {
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
    NSLayoutConstraint.activate([
      addBtn.leftAnchor.constraint(equalTo: line.leftAnchor),
      addBtn.topAnchor.constraint(equalTo: memberLabel.bottomAnchor, constant: 12),
    ])
    addBtn.addTarget(self, action: #selector(addUser), for: .touchUpInside)

    if viewmodel.isNormalTeam() == false, viewmodel.isOwner() == false,
       let inviteMode = viewmodel.teamInfoModel?.team?.inviteMode, inviteMode == .manager {
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

  func getFooterView() -> UIView? {
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

  func getBottomText() -> String? {
    if teamSettingType == .Discuss {
      return localizable("leave_discuss")
    } else if teamSettingType == .Senior {
      return viewmodel.isOwner() ? localizable("dismiss_team") : localizable("leave_team")
    }
    return nil
  }

  func setupUserInfoCollection(_ cornerView: UIView) {
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

  func addUser() {
    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("addUser weak self ", weakSelf as Any)
      if let accids = param["accids"] as? [String],
         let tid = self.viewmodel.teamInfoModel?.team?.teamId,
         let beInviteMode = self.viewmodel.teamInfoModel?.team?.beInviteMode,
         let type = self.viewmodel.teamInfoModel?.team?.type {
        if beInviteMode == .noAuth || type == .normal {
          self.didAddUserAndRefreshUI(accids, tid)
        } else {
          self.didAddUser(accids, tid)
        }
      }
    }
    var param = [String: Any]()
    param["nav"] = navigationController as Any
    var filters = Set<String>()
    viewmodel.teamInfoModel?.users.forEach { model in
      if let uid = model.nimUser?.userId {
        filters.insert(uid)
      }
    }
    if filters.count > 0 {
      param["filters"] = filters
    }

    param["limit"] = 200 - filters.count
    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  func removeTeamForMyself() {
    weak var weakSelf = self
    if teamSettingType == .Senior {
      showAlert(message: viewmodel.isOwner() ? localizable("dissolute_team_chat") : localizable("quit_team_chat")) {
        if weakSelf?.viewmodel.isOwner() == true {
          weakSelf?.dismissTeam()
        } else {
          weakSelf?.leaveTeam()
        }
      }
    } else if teamSettingType == .Discuss {
      showAlert(message: localizable("quit_discuss_chat")) {
        weakSelf?.leaveDiscuss()
      }
    }
    /*
     if viewmodel.isOwner(), let type = viewmodel.teamInfoModel?.team?.type, type == .advanced {
       showAlert(message: localizable("dissolute_team_chat")) {
         weakSelf?.dismissTeam()
       }
     } else {
       if let type = viewmodel.teamInfoModel?.team?.type {
           if let custom = viewmodel.teamInfoModel?.team?.clientCustomInfo, type == .normal || (type == .advanced && custom.contains(discussTeamKey)) {
             showAlert(message: localizable("quit_discuss_chat")) {
               weakSelf?.leveaTeam()
             }
           }else if type == .advanced {
           showAlert(message: localizable("quit_team_chat")) {
             weakSelf?.leveaTeam()
           }
         }
       }
     } */
  }

  func leaveDiscuss() {
    weak var weakSelf = self
    if isSeniorDiscuss == true, viewmodel.isOwner() {
      view.makeToastActivity(.center)
      viewmodel.transferTeamOwner { error in
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
          return
        }
        weakSelf?.navigationController?.popViewController(animated: true)
      }
      return
    }
    leaveTeam()
  }

  func toInfoView() {
    let info = TeamInfoViewController()
    info.team = viewmodel.teamInfoModel?.team
    navigationController?.pushViewController(info, animated: true)
  }

  func toMemberList() {
    let memberController = TeamMembersController()
    memberController.datas = viewmodel.teamInfoModel?.users
    if teamSettingType == .Senior {
      memberController.isSenior = true
    }
    memberController.ownerId = viewmodel.teamInfoModel?.team?.owner
    navigationController?.pushViewController(memberController, animated: true)
  }

  // MARK: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout

  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    print("numberOfItemsInSection ", viewmodel.teamInfoModel?.users.count as Any)
    return viewmodel.teamInfoModel?.users.count ?? 0
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(TeamUserCell.self)",
      for: indexPath
    ) as? TeamUserCell {
      if let user = viewmodel.teamInfoModel?.users[indexPath.row] {
        cell.user = user
      }
      return cell
    }
    return UICollectionViewCell()
  }

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 47.0, height: 32)
  }

  public func collectionView(_ collectionView: UICollectionView,
                             didSelectItemAt indexPath: IndexPath) {
    if let member = viewmodel.teamInfoModel?.users[indexPath.row],
       let nimUser = member.nimUser {
      if IMKitEngine.instance.isMySelf(nimUser.userId) {
        Router.shared.use(
          MeSettingRouter,
          parameters: ["nav": navigationController as Any],
          closure: nil
        )
      } else {
        Router.shared.use(
          ContactUserInfoPageRouter,
          parameters: ["nav": navigationController as Any, "user": nimUser],
          closure: nil
        )
      }
    }
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewmodel.sectionData.count > section {
      let model = viewmodel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    viewmodel.sectionData.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? BaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    if viewmodel.sectionData.count > section {
      let model = viewmodel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    let header = UIView()
    header.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    return header
  }

  public func tableView(_ tableView: UITableView,
                        heightForFooterInSection section: Int) -> CGFloat {
    if section == viewmodel.sectionData.count - 1 {
      return 12.0
    }
    return 0
  }
}

extension TeamSettingViewController {
  func didAddUserAndRefreshUI(_ accids: [String], _ tid: String) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo.inviteUser(accids, tid, nil, nil) { error, members in
      if let err = error {
        weakSelf?.view.hideToastActivity()
        weakSelf?.showToast(err.localizedDescription)
      } else {
        print("add users success : ", members as Any)
        if let ms = members, let model = weakSelf?.viewmodel.teamInfoModel {
          weakSelf?.viewmodel.repo.splitGroupMember(ms, model) { error, team in
            weakSelf?.view.hideToastActivity()
            if let e = error {
              weakSelf?.showToast(e.localizedDescription)
            } else {
              weakSelf?.refreshMemberCount()
              weakSelf?.userinfoCollection.reloadData()
            }
          }
        } else {
          weakSelf?.view.hideToastActivity()
        }
      }
    }
  }

  func didAddUser(_ accids: [String], _ tid: String) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.repo.inviteUser(accids, tid, nil, nil) { error, members in
      NELog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK inviteUser " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        weakSelf?.showToast(err.localizedDescription)
      } else {
        weakSelf?.showToast(localizable("invite_has_send"))
      }
    }
  }

  func dismissTeam() {
    if let tid = teamId {
      weak var weakSelf = self
      view.makeToastActivity(.center)
      viewmodel.dismissTeam(tid) { error in
        NELog.infoLog(
          ModuleName + " " + self.className,
          desc: "CALLBACK dismissTeam " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  func refreshMemberCount() {
    if let count = viewmodel.teamInfoModel?.users.count {
      memberCountLabel.text = "\(count)"
    }
  }

  func leaveTeam() {
    if let tid = teamId {
      view.makeToastActivity(.center)
      viewmodel.quitTeam(tid) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.className ?? "TeamSettingViewController"),
          desc: "CALLBACK quitTeam " + (error?.localizedDescription ?? "no error")
        )
        self?.view.hideToastActivity()
        if let err = error {
          self?.showToast(err.localizedDescription)
        } else {
          let session = NIMSession(tid, type: .team)
          if let stickInfo = self?.viewmodel.getTopSessionInfo(session) {
            self?.viewmodel.removeStickTop(params: stickInfo) { err, _ in
              NELog.infoLog(
                ModuleName + " " + (self?.className ?? "TeamSettingViewController"),
                desc: "CALLBACK removeStickTop " + (error?.localizedDescription ?? "no error")
              )
            }
          }
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }
}

extension TeamSettingViewController: TeamSettingViewModelDelegate {
  func didError(_ error: Error) {
    showToast(error.localizedDescription)
  }

  func didNeedRefreshUI() {
    contentTable.reloadData()
    refreshMemberCount()
    userinfoCollection.reloadData()
  }

  func didChangeInviteModeClick(_ model: SettingCellModel) {
    weak var weakSelf = self

    let actionSheetController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelActionButton = UIAlertAction(title: localizable("cancel"), style: .cancel) { _ in
      print("Cancel")
    }
    cancelActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    actionSheetController.addAction(cancelActionButton)

    let manager = UIAlertAction(title: localizable("team_owner"), style: .default) { _ in
      weakSelf?.view.makeToastActivity(.center)
      weakSelf?.viewmodel.repo.updateInviteMode(.manager, weakSelf?.teamId ?? "") { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.viewmodel.teamInfoModel?.team?.inviteMode = .manager
          model.subTitle = localizable("team_owner")
          weakSelf?.contentTable.reloadData()
        }
      }
    }
    manager.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    actionSheetController.addAction(manager)

    let deleteActionButton = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.view.makeToastActivity(.center)
      weakSelf?.viewmodel.repo.updateInviteMode(.all, weakSelf?.teamId ?? "") { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.viewmodel.teamInfoModel?.team?.inviteMode = .all
          model.subTitle = localizable("team_all")
          weakSelf?.contentTable.reloadData()
        }
      }
    }

    deleteActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    actionSheetController.addAction(deleteActionButton)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  func didUpdateTeamInfoClick(_ model: SettingCellModel) {
    let actionSheetController = UIAlertController(
      title: localizable("remind"),
      message: nil,
      preferredStyle: .actionSheet
    )
    weak var weakSelf = self
    let cancelActionButton = UIAlertAction(title: localizable("cancel"), style: .cancel) { _ in
      print("Cancel")
    }
    actionSheetController.addAction(cancelActionButton)

    let manager = UIAlertAction(title: localizable("team_owner"), style: .default) { _ in
      weakSelf?.view.makeToastActivity(.center)
      weakSelf?.viewmodel.repo
        .updateTeamInfoPrivilege(.manager, weakSelf?.teamId ?? "") { error in
          NELog.infoLog(
            ModuleName + " " + self.className(),
            desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
          )
          weakSelf?.view.hideToastActivity()
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          } else {
            weakSelf?.viewmodel.teamInfoModel?.team?.updateInfoMode = .manager
            model.subTitle = localizable("team_owner")
            weakSelf?.contentTable.reloadData()
          }
        }
    }
    actionSheetController.addAction(manager)

    let all = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.view.makeToastActivity(.center)
      weakSelf?.viewmodel.repo
        .updateTeamInfoPrivilege(.all, weakSelf?.teamId ?? "") { error in
          NELog.infoLog(
            ModuleName + " " + self.className(),
            desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
          )
          weakSelf?.view.hideToastActivity()
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          } else {
            weakSelf?.viewmodel.teamInfoModel?.team?.updateInfoMode = .all
            model.subTitle = localizable("team_all")
            weakSelf?.contentTable.reloadData()
          }
        }
    }
    actionSheetController.addAction(all)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  func didClickChangeNick() {
    let nick = TeamNameViewController()
    nick.type = .NickName
    nick.team = viewmodel.teamInfoModel?.team
    nick.teamMember = viewmodel.memberInTeam
    navigationController?.pushViewController(nick, animated: true)
  }

  func didClickHistoryMessage() {
    guard let tid = teamId else {
      return
    }
    Router.shared.use(
      SearchMessageRouter,
      parameters: ["nav": navigationController as Any, "teamId": tid],
      closure: nil
    )
  }
}
