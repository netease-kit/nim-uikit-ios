
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamSettingViewController: NETeamBaseViewController, UICollectionViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource,
  UITableViewDelegate, TeamSettingViewModelDelegate {
  /// 数据管理类
  public let viewModel = TeamSettingViewModel()
  /// 群id
  public var teamId: String?

  public var addButtonWidth: NSLayoutConstraint?

  public var addButtonLeftMargin: NSLayoutConstraint?

  /// 群类型
  public var teamSettingType: TeamSettingType = .Senior

  /// 是否是高级群扩展的讨论组
  public var isSeniorDiscuss = false

  /// 是否正在请求数据
  var isRequestingData = false

  var className = "TeamSettingViewController"

  public var cellClassDic = [Int: NEBaseTeamSettingCell.Type]()

  public lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  public lazy var teamHeaderView: TeamDetailHeaderView = {
    let imageView = TeamDetailHeaderView(avatarWH: 42)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.teamNameLabel.font = NEConstant.defaultTextFont(16.0)
    imageView.teamNameLabel.textColor = .ne_darkText
    imageView.lineView.isHidden = true
    return imageView
  }()

  public lazy var memberLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0x333333)
    label.font = NEConstant.defaultTextFont(16.0)
    label.accessibilityIdentifier = "id.member"
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

  public lazy var userinfoCollectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumLineSpacing = 0
    flowLayout.minimumInteritemSpacing = 0
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.isScrollEnabled = false
    return collectionView
  }()

  public lazy var addButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.add"
    return button
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let model = viewModel.teamInfoModel {
      teamHeaderView.setData(model.team, false)
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("setting")
    weak var weakSelf = self
    viewModel.delegate = self
    navigationView.moreButton.isHidden = true
    setupUI()
    if let tid = teamId {
      if NETeamUserManager.shared.getTeamInfo() == nil {
        NETeamUserManager.shared.loadData(tid)
      }

      viewModel.getCurrentMember(IMKitClient.instance.account(), tid) { member, error in
        if let currentMember = member {
          weakSelf?.requestSettingData(tid, currentMember)
        } else {
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          }
        }
      }
    } else {
      showToast("team id is nil")
    }
  }

  open func reloadSectionData() {}

  open func didRefreshUserinfoCollection() {
    userinfoCollectionView.reloadData()
  }

  /// 初始化
  open func setupUI() {
    viewModel.getData()
    view.backgroundColor = .ne_lightBackgroundColor
    view.addSubview(contentTableView)
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    for (key, value) in cellClassDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
    }
    if let pan = navigationController?.interactivePopGestureRecognizer {
      contentTableView.panGestureRecognizer.require(toFail: pan)
    }

    resetupUI()
  }

  /// 设置群设置顶部视图展示内容
  open func setTeamHeaderInfo() {
    teamHeaderView.setData(viewModel.teamInfoModel?.team, false)
  }

  /// 获取群设置数据
  open func requestSettingData(_ tid: String, _ member: V2NIMTeamMember) {
    weak var weakSelf = self
    viewModel.getTeamWithMembers(tid) { error in
      NEALog.infoLog(
        ModuleName + " " + self.className,
        desc: "CALLBACK getTeamInfo " + (error?.localizedDescription ?? "no error")
      )
      if let err = error {
        if err.code == protocolSendFailed {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == teamNotExistCode {
          weakSelf?.showToast(commonLocalizable("team_not_exist"))
        } else {
          weakSelf?.showToast(err.localizedDescription)
        }
      } else {
        if let type = weakSelf?.viewModel.teamInfoModel?.team?.teamType {
          if type == .TEAM_TYPE_NORMAL {
            if let custom = weakSelf?.viewModel.teamInfoModel?.team?.serverExtension, custom.contains(discussTeamKey) {
              weakSelf?.teamSettingType = .Discuss
              weakSelf?.isSeniorDiscuss = true
            } else {
              weakSelf?.teamSettingType = .Senior
            }
          }
        }
        if let type = weakSelf?.teamSettingType {
          weakSelf?.viewModel.teamSettingType = type
        }
        weakSelf?.resetupUI()

        weakSelf?.viewModel.getAllTeamMemberInfos(tid, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { error in
          NEALog.infoLog(weakSelf?.className() ?? "", desc: "CALLBACK getAllTeamMemberInfos \(error?.localizedDescription ?? "no error")")
        }
      }
    }
  }

  /// 有数据返回之后重新刷新UI
  open func resetupUI() {
    reloadSectionData()
    checkoutAddShowOrHide()
    contentTableView.tableHeaderView = getHeaderView()
    contentTableView.tableFooterView = getFooterView()
    contentTableView.reloadData()
    didRefreshUserinfoCollection()
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
      return viewModel.isOwner() ? localizable("dismiss_team") : localizable("leave_team")
    }
    return nil
  }

  open func setupUserInfoCollection(_ cornerView: UIView) {}

  open func addUser() {
    if isRequestingData {
      return
    }
    isRequestingData = true

    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("addUser weak self ", weakSelf as Any)
      if let accids = param["accids"] as? [String],
         let tid = weakSelf?.viewModel.teamInfoModel?.team?.teamId,
         let beInviteMode = weakSelf?.viewModel.teamInfoModel?.team?.agreeMode,
         let type = weakSelf?.viewModel.teamInfoModel?.team?.teamType {
        if beInviteMode == .TEAM_AGREE_MODE_NO_AUTH || type == .TEAM_TYPE_NORMAL {
          weakSelf?.didAddUser(accids, tid)
        }
      }
    }

    var param = [String: Any]()
    param["nav"] = navigationController as Any
    var filters = Set<String>()

    showToast(localizable("requesting"))
    NETeamUserManager.shared.getAllTeamMembers(viewModel.teamInfoModel?.team?.teamId ?? "", .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { [weak self] _ in
      self?.isRequestingData = false
      if let models = NETeamUserManager.shared.getAllTeamMembers() {
        for model in models {
          filters.insert(model.accountId)
        }

        if !filters.isEmpty {
          param["filters"] = filters
        }

        param["limit"] = (self?.viewModel.teamInfoModel?.team?.memberLimit ?? inviteNumberLimit + filters.count) - filters.count

        if IMKitConfigCenter.shared.enableAIUser {
          Router.shared.use(ContactFusionSelectRouter, parameters: param, closure: nil)
        } else {
          Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
        }
      }
    }
  }

  /// 退出/解散群聊
  open func removeTeamForMyself() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    weak var weakSelf = self
    if teamSettingType == .Senior {
      showAlert(message: viewModel.isOwner() ? localizable("dissolute_team_chat") : localizable("quit_team_chat")) {
        if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
          weakSelf?.showToast(commonLocalizable("network_error"))
          return
        }
        if weakSelf?.viewModel.isOwner() == true {
          weakSelf?.dismissTeam()
        } else {
          weakSelf?.leaveTeam()
        }
      }
    } else if teamSettingType == .Discuss {
      showAlert(message: localizable("quit_discuss_chat")) {
        if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
          weakSelf?.showToast(commonLocalizable("network_error"))
          return
        }
        weakSelf?.leaveDiscuss()
      }
    }
  }

  /// 离开讨论组
  open func leaveDiscuss() {
    weak var weakSelf = self
    if isSeniorDiscuss == true, viewModel.isOwner() {
      view.makeToastActivity(.center)
      viewModel.transferTeamOwner { error in
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

  /// 跳转成员列表
  open func toMemberList() {
    let memberController = NEBaseTeamMembersController(teamId: viewModel.teamInfoModel?.team?.teamId)
    navigationController?.pushViewController(memberController, animated: true)
  }

  // MARK: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    viewModel.teamInfoModel?.users.count ?? 0
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
    if let member = viewModel.teamInfoModel?.users[indexPath.row],
       let nimUser = member.nimUser {
      if IMKitClient.instance.isMe(nimUser.user?.accountId) {
        Router.shared.use(
          MeSettingRouter,
          parameters: ["nav": navigationController as Any],
          closure: nil
        )
      } else {
        if let uid = nimUser.user?.accountId {
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
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.sectionData.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
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
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      if !model.cellModels.isEmpty {
        return 12.0
      }
    }
    return 0
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }

  open func tableView(_ tableView: UITableView,
                      heightForFooterInSection section: Int) -> CGFloat {
    if section == viewModel.sectionData.count - 1 {
      return 12.0
    }
    return 0
  }

  /// 添加好友
  open func didAddUser(_ accids: [String], _ tid: String) {
    weak var weakSelf = self
    view.makeToastActivity(.center)

    viewModel.inviteUsers(accids, tid) { error, members in
      if let err = error {
        weakSelf?.view.hideToastActivity()
        if err.code == protocolSendFailed {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else if err.code == noPermissionInviteCode {
          weakSelf?.showToast(localizable("no_permission_tip"))
        } else {
          weakSelf?.showToast(commonLocalizable("failed_operation"))
        }
      } else {
        print("add users success : ", members as Any)
        weakSelf?.view.hideToastActivity()
      }
    }
  }

  /// 解散群聊
  open func dismissTeam() {
    if let tid = teamId {
      weak var weakSelf = self
      view.makeToastActivity(.center)
      viewModel.dismissTeam(tid) { error in
        NEALog.infoLog(
          ModuleName + " " + self.className,
          desc: "CALLBACK dismissTeam " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.didError(err)
        } else {
          NotificationCenter.default.post(name: NotificationName.popGroupChatVC, object: nil)
        }
      }
    }
  }

  /// 刷新群成员个数
  open func refreshMemberCount() {
    if let count = viewModel.teamInfoModel?.team?.memberCount {
      memberCountLabel.text = "\(count)"
    }
  }

  /// 离开群聊
  open func leaveTeam() {
    if let tid = teamId {
      view.makeToastActivity(.center)
      viewModel.leaveTeam(tid) { [weak self] error in
        NEALog.infoLog(
          ModuleName + " " + (self?.className ?? "TeamSettingViewController"),
          desc: "CALLBACK quitTeam " + (error?.localizedDescription ?? "no error")
        )
        self?.view.hideToastActivity()
        if let err = error {
          self?.didError(err)
        } else {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self?.viewModel.getTeamWithMembers(tid) { _ in
              if self?.viewModel.teamInfoModel?.team?.memberCount == 1,
                 self?.viewModel.isOwner() == true {
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

  open func didClickMark() {
    if let tid = teamId {
      let conversationId = V2NIMConversationIdUtil.teamConversationId(tid)
      Router.shared.use(PushPinMessageVCRouter, parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any], closure: nil)
    }
  }

  open func didError(_ error: NSError) {
    if error.code == protocolSendFailed {
      showToast(commonLocalizable("network_error"))
    } else {
      showToast(commonLocalizable("failed_operation"))
    }
  }

  open func didShowNoNetworkToast() {
    showToast(commonLocalizable("network_error"))
  }

  /// 通知页面刷新回调
  open func didNeedRefreshUI() {
    setTeamHeaderInfo()
    refreshMemberCount()
    checkoutAddShowOrHide()
    reloadSectionData()
    contentTableView.reloadData()
    didRefreshUserinfoCollection()
  }

  open func didClickTeamManage() {}

  open func checkoutAddShowOrHide() {}

  open func updateInviteModeOwnerAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    weakSelf?.view.makeToastActivity(.center)
    weakSelf?.viewModel.teamRepo.updateInviteMode(weakSelf?.teamId ?? "", .TEAM_TYPE_NORMAL, .TEAM_INVITE_MODE_MANAGER) { error, team in
      NEALog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        weakSelf?.didError(err)
      } else {
        weakSelf?.viewModel.teamInfoModel?.team = team
        model.subTitle = localizable("team_owner")
        weakSelf?.contentTableView.reloadData()
      }
    }
  }

  open func updateInviteModeAllAction(_ model: SettingCellModel) {
    weak var weakSelf = self
    weakSelf?.view.makeToastActivity(.center)
    weakSelf?.viewModel.teamRepo.updateInviteMode(weakSelf?.teamId ?? "", .TEAM_TYPE_NORMAL, .TEAM_INVITE_MODE_ALL) { error, team in
      NEALog.infoLog(
        ModuleName + " " + self.className(),
        desc: "CALLBACK updateInviteMode " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.view.hideToastActivity()
      if let err = error {
        weakSelf?.didError(err)
      } else {
        weakSelf?.viewModel.teamInfoModel?.team = team
        model.subTitle = localizable("team_all")
        weakSelf?.contentTableView.reloadData()
      }
    }
  }

  open func didClickChangeNick() {}

  open func didClickHistoryMessage() {}

  open func getManagerUsers() -> [NETeamMemberInfoModel] {
    var members = [NETeamMemberInfoModel]()
    viewModel.teamInfoModel?.users.forEach { model in
      if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
        members.append(model)
      }
    }
    return members
  }

  override open func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)
    if IMKitConfigCenter.shared.enableOnlineStatus {
      if parent == nil {
        viewModel.clear()
      }
    }
  }
}
