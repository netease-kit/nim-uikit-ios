
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitCoreIM

public class ValiationMessageConfig {}

public class ValidationMessageViewController: ContactBaseViewController {
  let viewModel = ValidationMessageViewModel()

  let tableView = UITableView()
  private let tag = "ValidationMessageViewController"

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    title = localizable("验证消息")
    // viewModel.getValidationMessage()
    setupUI()
    weak var weakSelf = self
    viewModel.getValidationMessage {
      weakSelf?.tableView.reloadData()
    }

    viewModel.dataRefresh = {
      weakSelf?.tableView.reloadData()
    }
  }

  func setupUI() {
    let clearItem = UIBarButtonItem(
      title: "清空",
      style: .done,
      target: self,
      action: #selector(clearMessage)
    )
    clearItem.tintColor = UIColor(hexString: "666666")
    navigationItem.rightBarButtonItem = clearItem

    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(
      SystemNotificationCell.self,
      forCellReuseIdentifier: "\(SystemNotificationCell.self)"
    )
  }

  @objc func clearMessage() {
    weak var weakSelf = self
    showAlert(message: "是否要清除所有验证消息？") {
      weakSelf?.viewModel.clearAllNoti {
        weakSelf?.tableView.reloadData()
      }
    }
  }
}

extension ValidationMessageViewController: UITableViewDelegate, UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.datas.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let noti = viewModel.datas[indexPath.row]
    let reuseIdentifier = "\(SystemNotificationCell.self)"
    let cell = tableView.dequeueReusableCell(
      withIdentifier: reuseIdentifier,
      for: indexPath
    ) as! SystemNotificationCell
    cell.delegate = self
    cell.confige(noti)
    return cell
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    60
  }
}

extension ValidationMessageViewController: SystemNotificationCellDelegate {
  func onAccept(_ notifiModel: XNotification) {
    weak var weakSelf = self
    guard let teamId = notifiModel.targetID, let invitorId = notifiModel.sourceID else {
      return
    }

    if notifiModel.type == .teamInvite {
      viewModel.acceptInviteWithTeam(teamId, invitorId) { error in
        if error != nil {
          NELog.infoLog(self.tag, desc: "❌acceptInviteWithTeam failed,error = \(error!)")
        } else {
          notifiModel.handleStatus = .HandleTypeOk
          notifiModel.imNotification?.handleStatus = 1
          weakSelf?.tableView.reloadData()
        }
      }
    } else if notifiModel.type == .addFriendRequest {
      viewModel.agreeRequest(invitorId) { error in
        if error != nil {
          NELog.infoLog(self.tag, desc: "❌agreeRequest failed,error = \(error!)")
        } else {
          notifiModel.handleStatus = .HandleTypeOk
          notifiModel.imNotification?.handleStatus = 1
          weakSelf?.tableView.reloadData()
        }
      }
    }
  }

  func onRefuse(_ notifiModel: XNotification) {
    weak var weakSelf = self
    guard let teamId = notifiModel.targetID, let invitorId = notifiModel.sourceID else {
      return
    }

    if notifiModel.type == .teamInvite {
      weakSelf?.viewModel.rejectInviteWithTeam(teamId, invitorId) { error in
        if error != nil {
          NELog.infoLog(self.tag, desc: "❌rejectInviteWithTeam failed,error = \(error!)")
        } else {
          notifiModel.handleStatus = .HandleTypeNo
          notifiModel.imNotification?.handleStatus = 2
          weakSelf?.tableView.reloadData()
        }
      }
    } else if notifiModel.type == .addFriendRequest {
      viewModel.refuseRequest(invitorId) { error in
        if error != nil {
          NELog.infoLog(self.tag, desc: "❌agreeRequest failed,error = \(error!)")
        } else {
          notifiModel.handleStatus = .HandleTypeNo
          notifiModel.imNotification?.handleStatus = 2
          weakSelf?.tableView.reloadData()
        }
      }
    }
  }
}
