// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseTeamJoinActionViewController: NEContactBaseViewController {
  public let viewModel = TeamJoinActionViewModel()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    title = commonLocalizable("team_group")
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    title = commonLocalizable("team_group")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.removeFromSuperview()
    topConstant = 0

    setupUI()
    viewModel.delegate = self
    loadData()

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewModel.setTeamJoinActionRead()
    tableviewReload()
  }

  /// 返回上一级页面
  override open func backEvent() {
    super.backEvent()
    viewModel.setTeamJoinActionRead()
  }

  /// 进入后台，清空未读
  override open func appEnterBackground() {
    super.appEnterBackground()
    viewModel.setTeamJoinActionRead()
    tableviewReload()
  }

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }

    return tableView
  }()

  /// 加载数据
  open func loadData() {
    viewModel.loadTeamJoinActionList(true) { [weak self] error in
      if let err = error {
        NEALog.errorLog(ModuleName + " " + NEBaseAddApplicationViewController.className(), desc: "loadApplicationList CALLBACK error: \(err.localizedDescription)")
      } else {
        self?.emptyView.isHidden = (self?.viewModel.teamJoinActions.count ?? 0) > 0
      }
    }
  }

  /// 控件初始化
  open func setupUI() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.setText(localizable("no_team_join_action"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  /// 清空入群申请
  override open func toSetting() {
    guard view.isVisibleInWindow else {
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    showAlert(message: localizable("clear_all_team_join_action")) { [weak self] in
      self?.viewModel.clearNotification { error in
        self?.emptyView.isHidden = (self?.viewModel.teamJoinActions.count ?? 0) > 0
        self?.tableView.reloadData()
      }
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension NEBaseTeamJoinActionViewController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.teamJoinActions.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    66
  }
}

// MARK: - TeamJoinActionViewModelDelegate

extension NEBaseTeamJoinActionViewController: TeamJoinActionViewModelDelegate {
  open func tableviewReload() {
    tableView.reloadData()
    emptyView.isHidden = !viewModel.teamJoinActions.isEmpty
  }
}

// MARK: - SystemNotificationCellDelegate

extension NEBaseTeamJoinActionViewController: SystemNotificationCellDelegate {
  /// 同意入群申请
  /// - Parameter notifiModel: 申请模型
  open func onAccept(action: NETeamJoinAction) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    weak var weakSelf = self
    let info = action.nimTeamJoinAction

    viewModel.agreeRequest(action: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseTeamJoinActionViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
          return
        case teamNotExistCode:
          weakSelf?.showToast(commonLocalizable("team_not_exist"))
        case teamMemberNotExist:
          weakSelf?.showToast(localizable("verification_processed"))
        case alreadyInTeamCode:
          weakSelf?.showToast(localizable("already_in_the_team"))
        case invitationExpiredCode:
          weakSelf?.showToast(localizable("invitation_expired"))
        case noPermissionOperationCode:
          weakSelf?.showToast(localizable("no_permission_tip"))
        case teamMemberLimitExceededCode:
          weakSelf?.showToast(localizable("team_member_limit_exceeded"))
        case joinedTeamLimitExceededCode:
          weakSelf?.showToast(localizable("joined_team_limit_exceeded"))
        default:
          weakSelf?.showToast(commonLocalizable("failed_operation"))
          return
        }

        weakSelf?.viewModel.changeTeamJoinActionStatus(info, .TEAM_JOIN_ACTION_STATUS_EXPIRED)
        weakSelf?.tableviewReload()
      } else {
        weakSelf?.tableviewReload()
      }
    }
  }

  /// 拒绝入群申请
  /// - Parameter notifiModel: 申请模型
  open func onRefuse(action: NETeamJoinAction) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    weak var weakSelf = self
    let info = action.nimTeamJoinAction

    viewModel.refuseRequest(action: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseTeamJoinActionViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
          return
        case teamNotExistCode:
          weakSelf?.showToast(commonLocalizable("team_not_exist"))
        case teamMemberNotExist:
          weakSelf?.showToast(localizable("verification_processed"))
        case alreadyInTeamCode:
          weakSelf?.showToast(localizable("already_in_the_team"))
        case invitationExpiredCode:
          weakSelf?.showToast(localizable("invitation_expired"))
        case noPermissionOperationCode:
          weakSelf?.showToast(localizable("no_permission_tip"))
        case teamMemberLimitExceededCode:
          weakSelf?.showToast(localizable("team_member_limit_exceeded"))
        case joinedTeamLimitExceededCode:
          weakSelf?.showToast(localizable("joined_team_limit_exceeded"))
        default:
          weakSelf?.showToast(commonLocalizable("failed_operation"))
          return
        }

        weakSelf?.viewModel.changeTeamJoinActionStatus(info, .TEAM_JOIN_ACTION_STATUS_EXPIRED)
        weakSelf?.tableviewReload()
      } else {
        weakSelf?.tableviewReload()
      }
    }
  }
}
