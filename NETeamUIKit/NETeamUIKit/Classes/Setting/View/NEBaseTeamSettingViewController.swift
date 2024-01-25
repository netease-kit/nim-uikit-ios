
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamSettingViewController: NEBaseViewController, UICollectionViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource,
  UITableViewDelegate, TeamSettingViewModelDelegate {
  public let viewmodel = TeamSettingViewModel()

  public var teamId: String?

  public var addBtnWidth: NSLayoutConstraint?

  public var addBtnLeftMargin: NSLayoutConstraint?

  public var teamSettingType: TeamSettingType = .Discuss

  public var isSeniorDiscuss = false // 是否是高级群扩展的讨论组

  var className = "TeamSettingViewController"

  public var cellClassDic = [Int: NEBaseTeamSettingCell.Type]()

  public lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
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

  public lazy var teamHeader: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(16.0)
    return imageView
  }()

  public lazy var teamNameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = NEConstant.hexRGB(0x333333)
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  public lazy var memberCountLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = NEConstant.hexRGB(0x999999)
    label.accessibilityIdentifier = "id.count"
    return label
  }()

  public lazy var userinfoCollection: UICollectionView = {
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

  public lazy var addBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.add"
    return button
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let model = viewmodel.teamInfoModel {
      if let url = model.team?.avatarUrl, !url.isEmpty {
        teamHeader.sd_setImage(with: URL(string: url))
      }
      if let name = model.team?.teamName {
        teamNameLabel.text = name
      }
    }
  }

  override open func viewDidLoad() {
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
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else {
            weakSelf?.showToast(localizable("team_not_exist"))
          }
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
          if let type = weakSelf?.teamSettingType {
            weakSelf?.viewmodel.teamSettingType = type
          }
          weakSelf?.reloadSectionData()
          weakSelf?.contentTable.tableHeaderView = weakSelf?.getHeaderView()
          weakSelf?.contentTable.tableFooterView = weakSelf?.getFooterView()
          weakSelf?.contentTable.reloadData()
          weakSelf?.didRefreshUserinfoCollection()
          weakSelf?.checkoutAddShowOrHide()
        }
      }
    }
    // Do any additional setup after loading the view.
    setupUI()

    NotificationCenter.default.addObserver(self, selector: #selector(didRefreshUserinfoCollection), name: NENotificationName.updateFriendInfo, object: nil)
  }

  open func reloadSectionData() {}

  open func didRefreshUserinfoCollection() {
    userinfoCollection.reloadData()
  }

  open func setupUI() {
    view.backgroundColor = .ne_lightBackgroundColor
    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    cellClassDic.forEach { (key: Int, value: NEBaseTeamSettingCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
    if let pan = navigationController?.interactivePopGestureRecognizer {
      contentTable.panGestureRecognizer.require(toFail: pan)
    }
  }

  open func getHeaderView() -> UIView {
    UIView()
  }

  open func getFooterView() -> UIView? {
    nil
  }

  open func getBottomText() -> String? {
    if teamSettingType == .Discuss {
      return localizable("leave_discuss")
    } else if teamSettingType == .Senior {
      return viewmodel.isOwner() ? localizable("dismiss_team") : localizable("leave_team")
    }
    return nil
  }

  open func setupUserInfoCollection(_ cornerView: UIView) {}

  // MARK: objc 方法

  open func addUser() {
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

    param["limit"] = inviteNumberLimit - filters.count
    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  open func removeTeamForMyself() {
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
  }

  open func leaveDiscuss() {
    weak var weakSelf = self
    if isSeniorDiscuss == true, viewmodel.isOwner() {
      view.makeToastActivity(.center)
      viewmodel.transferTeamOwner { error in
        weakSelf?.view.hideToastActivity()
        if let err = error as? NSError {
          weakSelf?.didError(err)
        } else {
          NotificationCenter.default.post(name: NotificationName.popGroupChatVC, object: nil)
        }
      }
      return
    }
    leaveTeam()
  }

  open func toInfoView() {}

  open func toMemberList() {
    let memberController = NEBaseTeamMembersController(teamId: viewmodel.teamInfoModel?.team?.teamId)
    navigationController?.pushViewController(memberController, animated: true)
  }

  // MARK: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    print("numberOfItemsInSection ", viewmodel.teamInfoModel?.users.count as Any)
    return viewmodel.teamInfoModel?.users.count ?? 0
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    .zero
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didSelectItemAt indexPath: IndexPath) {
    if let member = viewmodel.teamInfoModel?.users[indexPath.row],
       let nimUser = member.nimUser {
      if IMKitClient.instance.isMySelf(nimUser.userId) {
        Router.shared.use(
          MeSettingRouter,
          parameters: ["nav": navigationController as Any],
          closure: nil
        )
      } else {
        if let uid = nimUser.userId {
          Router.shared.use(
            ContactUserInfoPageRouter,
            parameters: ["nav": navigationController as Any, "uid": uid],
            closure: nil
          )
        }
      }
    }
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewmodel.sectionData.count > section {
      let model = viewmodel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    viewmodel.sectionData.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if viewmodel.sectionData.count > section {
      let model = viewmodel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    let header = UIView()
    header.backgroundColor = .ne_lightBackgroundColor
    return header
  }

  open func tableView(_ tableView: UITableView,
                      heightForFooterInSection section: Int) -> CGFloat {
    if section == viewmodel.sectionData.count - 1 {
      return 12.0
    }
    return 0
  }

  func didAddUserAndRefreshUI(_ accids: [String], _ tid: String) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    viewmodel.inviterUsers(accids, tid) { error, members in
      if let err = error {
        weakSelf?.view.hideToastActivity()
        if err.code == noNetworkCode {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        print("add users success : ", members as Any)
        if let ms = members, let model = weakSelf?.viewmodel.teamInfoModel {
          weakSelf?.viewmodel.repo.splitGroupMember(ms, model) { error, team in
            weakSelf?.view.hideToastActivity()
            if let err = error as? NSError {
              weakSelf?.didError(err)
            } else {
              weakSelf?.refreshMemberCount()
              weakSelf?.didRefreshUserinfoCollection()
              weakSelf?.checkoutAddShowOrHide()
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
      if let err = error as? NSError {
        weakSelf?.didError(err)
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
        if let err = error as? NSError {
          weakSelf?.didError(err)
        } else {
          NotificationCenter.default.post(name: NotificationName.popGroupChatVC, object: nil)
        }
      }
    }
  }

  func refreshMemberCount() {
    if let count = viewmodel.teamInfoModel?.team?.memberNumber {
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
        if let err = error as? NSError {
          self?.didError(err)
        } else {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self?.viewmodel.getTeamInfo(tid) { _ in
              if self?.viewmodel.teamInfoModel?.team?.memberNumber == 1,
                 self?.viewmodel.isOwner() == true {
                self?.dismissTeam()
              } else {
                NotificationCenter.default.post(name: NotificationName.popGroupChatVC, object: nil)
              }
            }
          }
        }
      }
    }
  }

  func didClickMark() {
    if let tid = teamId {
      let session = NIMSession(tid, type: .team)
      Router.shared.use(PushPinMessageVCRouter, parameters: ["nav": navigationController as Any, "session": session as Any], closure: nil)
    }
  }

  func didError(_ error: NSError) {
    if error.code == noNetworkCode {
      showToast(commonLocalizable("network_error"))
    } else {
      showToast(localizable("failed_operation"))
    }
  }

  func didNeedRefreshUI() {
    contentTable.reloadData()
    refreshMemberCount()
    didRefreshUserinfoCollection()
    checkoutAddShowOrHide()
  }

  open func didClickTeamManage() {}

  open func checkoutAddShowOrHide() {}

  func updateInviteModeOwnerAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    weakSelf?.view.makeToastActivity(.center)
    weakSelf?.viewmodel.repo.updateInviteMode(.manager, weakSelf?.teamId ?? "") { error in
      NELog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error as? NSError {
        weakSelf?.didError(err)
      } else {
        weakSelf?.viewmodel.teamInfoModel?.team?.inviteMode = .manager
        model.subTitle = localizable("team_owner")
        weakSelf?.contentTable.reloadData()
      }
    }
  }

  func updateInviteModeAllAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    weakSelf?.view.makeToastActivity(.center)
    weakSelf?.viewmodel.repo.updateInviteMode(.all, weakSelf?.teamId ?? "") { error in
      NELog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error as? NSError {
        weakSelf?.didError(err)
      } else {
        weakSelf?.viewmodel.teamInfoModel?.team?.inviteMode = .all
        model.subTitle = localizable("team_all")
        weakSelf?.contentTable.reloadData()
      }
    }
  }

  open func didChangeInviteModeClick(_ model: SettingCellModel) {
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

    let ownerActionButton = UIAlertAction(title: localizable("team_owner"), style: .default) { _ in
      weakSelf?.updateInviteModeOwnerAction(model)
    }
    ownerActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    ownerActionButton.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(ownerActionButton)

    let allActionButton = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.updateInviteModeAllAction(model)
    }

    allActionButton.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    allActionButton.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(allActionButton)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  func updateTeamInfoOwnerAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    weakSelf?.view.makeToastActivity(.center)
    weakSelf?.viewmodel.repo
      .updateTeamInfoPrivilege(.manager, weakSelf?.teamId ?? "") { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error as? NSError {
          weakSelf?.didError(err)
        } else {
          weakSelf?.viewmodel.teamInfoModel?.team?.updateInfoMode = .manager
          model.subTitle = localizable("team_owner")
          weakSelf?.contentTable.reloadData()
        }
      }
  }

  func updateTeamInfoAllAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    weakSelf?.view.makeToastActivity(.center)
    weakSelf?.viewmodel.repo
      .updateTeamInfoPrivilege(.all, weakSelf?.teamId ?? "") { error in
        NELog.infoLog(
          ModuleName + " " + self.className(),
          desc: "CALLBACK updateTeamInfoPrivilege " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error as? NSError {
          weakSelf?.didError(err)
        } else {
          weakSelf?.viewmodel.teamInfoModel?.team?.updateInfoMode = .all
          model.subTitle = localizable("team_all")
          weakSelf?.contentTable.reloadData()
        }
      }
  }

  open func didUpdateTeamInfoClick(_ model: SettingCellModel) {
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
      weakSelf?.updateTeamInfoOwnerAction(model)
    }
    manager.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    manager.accessibilityIdentifier = "id.teamOwner"
    actionSheetController.addAction(manager)

    let all = UIAlertAction(title: localizable("team_all"), style: .default) { _ in
      weakSelf?.updateTeamInfoAllAction(model)
    }
    all.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    all.accessibilityIdentifier = "id.teamAllMember"
    actionSheetController.addAction(all)

    navigationController?.present(actionSheetController, animated: true, completion: nil)
  }

  open func didClickChangeNick() {}

  open func didClickHistoryMessage() {}

  open func getManaterUsers() -> [TeamMemberInfoModel] {
    var members = [TeamMemberInfoModel]()
    viewmodel.teamInfoModel?.users.forEach { model in
      if model.teamMember?.type == .manager {
        members.append(model)
      }
    }
    return members
  }
}
