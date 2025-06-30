
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 群详情界面 - 基类
@objcMembers
open class NEBaseTeamDetailViewController: NETeamBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  var team: V2NIMTeam?
  var className = "TeamDetailViewController"

  var data = [[TeamDetailItem]]()
  public let viewModel = TeamDetailViewModel()
  public var headerView = TeamDetailHeaderView()

  /// 使用 V2NIMTeam 初始化
  /// - Parameter nim_team: V2NIMTeam 对象
  public init(nim_team: V2NIMTeam) {
    super.init(nibName: nil, bundle: nil)
    team = nim_team
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 66
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  open func commonUI() {
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.moreButton.isHidden = true

    let headerBackView = UIView()
    headerBackView.translatesAutoresizingMaskIntoConstraints = false
    headerBackView.backgroundColor = .white

    headerBackView.addSubview(headerView)
    headerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: headerBackView.leftAnchor, constant: 20),
      headerView.topAnchor.constraint(equalTo: headerBackView.topAnchor, constant: 0),
      headerView.heightAnchor.constraint(equalToConstant: 113),
      headerView.rightAnchor.constraint(equalTo: headerBackView.rightAnchor, constant: -20),
    ])

    view.addSubview(headerBackView)
    NSLayoutConstraint.activate([
      headerBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      headerBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      headerBackView.heightAnchor.constraint(equalToConstant: 113),
      headerBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
    ])

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: headerBackView.bottomAnchor),
    ])

    tableView.register(TeamTextWithDetailCell.self, forCellReuseIdentifier: "\(TeamTextWithDetailCell.self)")
    tableView.register(TeamCenterTextCell.self, forCellReuseIdentifier: "\(TeamCenterTextCell.self)")
  }

  open func loadData() {
    guard let team = team else {
      return
    }

    let showOwner = !team.isDisscuss()
    headerView.setData(team, showOwner)
    data = [
      [
        TeamDetailItem(title: localizable("team_intr"),
                       detailTitle: team.intro,
                       value: false,
                       textColor: UIColor.darkText,
                       cellClass: TeamTextWithDetailCell.self),
      ],
    ]

    if team.isValidTeam {
      data.append([
        TeamDetailItem(title: commonLocalizable("chat"),
                       detailTitle: "",
                       value: false,
                       textColor: UIColor(hexString: "#337EFF"),
                       cellClass: TeamCenterTextCell.self),
      ])
    } else {
      data.append([
        TeamDetailItem(title: commonLocalizable("join_team"),
                       detailTitle: "",
                       value: false,
                       textColor: UIColor(hexString: "#337EFF"),
                       cellClass: TeamCenterTextCell.self),
      ])
    }

    tableView.tableHeaderView?.layoutIfNeeded()
    tableView.reloadData()
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    data.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    data[section].count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = data[indexPath.section][indexPath.row]
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(item.cellClass)",
      for: indexPath
    )

    if let c = cell as? TeamTextWithDetailCell {
      c.setModel(model: item)
      if item.title == localizable("team_intr") {
        c.detailTitleLabel.numberOfLines = 0
      }
      return c
    }

    if let c = cell as? TeamCenterTextCell {
      c.setModel(model: item)
      return c
    }
    return cell
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    0.1
  }

  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = UIColor.clear
    return headerView
  }

  open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    0.1
  }

  open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = UIColor.clear
    return headerView
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = data[indexPath.section][indexPath.row]

    if item.title == commonLocalizable("chat") {
      toChat()
    }

    if item.title == commonLocalizable("join_team") {
      joinTeam()
    }
  }

  open func toChat() {
    guard let teamId = team?.teamId else {
      return
    }

    let conversationId = V2NIMConversationIdUtil.teamConversationId(teamId)
    Router.shared.use(
      PushTeamChatVCRouter,
      parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any, "removeTeamVC": true],
      closure: nil
    )
  }

  open func joinTeam() {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    if let teamId = team?.teamId {
      viewModel.applyJoinTeam(teamId) { team, error in
        NEALog.infoLog(
          self.className,
          desc: "CALLBACK addFriend " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          NEALog.errorLog("TeamDetailViewController", desc: "applyJoinTeam failed :\(err)")
          if err.code == alreadyInTeamCode {
            weakSelf?.toChat()
          } else {
            weakSelf?.showToast(err.localizedDescription)
          }
          switch err.code {
          case protocolSendFailed:
            weakSelf?.showToast(commonLocalizable("network_error"))
          case teamNotExistCode:
            weakSelf?.showToast(commonLocalizable("team_not_exist"))
          case alreadyInTeamCode:
            weakSelf?.toChat()
          case teamMemberLimitExceededCode:
            weakSelf?.showToast(localizable("team_member_limit_exceeded"))
          case joinedTeamLimitExceededCode:
            weakSelf?.showToast(localizable("joined_team_limit_exceeded"))
          default:
            weakSelf?.showToast(err.localizedDescription)
          }
        } else {
          if team?.isValidTeam == true {
            weakSelf?.toChat()
            return
          }
          weakSelf?.showToast(localizable("send_team_join_apply"))
        }
      }
    }
  }
}
