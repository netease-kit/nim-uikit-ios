// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseValidationMessageViewController: NEBaseContactViewController {
  public let viewModel = ValidationMessageViewModel()
  public let tableView = UITableView()
  var tag = "ValidationMessageViewController"

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadData()

    weak var weakSelf = self
    viewModel.dataRefresh = {
      weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.datas.count ?? 0) > 0
      weakSelf?.tableView.reloadData()
    }

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  // 返回上一级页面
  override open func backToPrevious() {
    super.backToPrevious()
    viewModel.clearNotiUnreadCount()
  }

  func appEnterBackground() {
    viewModel.clearNotiUnreadCount()
    loadData()
  }

  func loadData() {
    weak var weakSelf = self
    viewModel.getValidationMessage {
      NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"), desc: "✅ getValidationMessage SUCCESS")
      weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.datas.count ?? 0) > 0
      weakSelf?.tableView.reloadData()
    }
  }

  open func setupUI() {
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(clearMessage)
    )
    clearItem.tintColor = UIColor(hexString: "666666")
    var textAttributes = [NSAttributedString.Key: Any]()
    textAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    title = localizable("validation_message")
    navigationView.navTitle.text = title
    navigationView.setMoreButtonTitle(localizable("clear"))
    navigationView.moreButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(clearMessage))

    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.settingContent(content: localizable("no_validation_message"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  func clearMessage() {
    viewModel.clearAllNoti {
      NELog.infoLog(ModuleName + " " + self.tag, desc: "✅ clearAllNoti SUCCESS")
      tableView.reloadData()
      emptyView.isHidden = false
    }
  }

  open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    viewModel.clearNotiUnreadCount()
    return true
  }
}

extension NEBaseValidationMessageViewController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.datas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    60
  }
}

extension NEBaseValidationMessageViewController: SystemNotificationCellDelegate {
  open func changeValidationStatus(notifiModel: NENotification, notiStatus: NEHandleStatus) {
    var notifiModels = [NENotification]()
    if let msgList = notifiModel.msgList,
       msgList.count > 0 {
      for msg in msgList {
        notifiModels.append(msg)
      }
    }

    notifiModel.handleStatus = notiStatus
    notifiModel.imNotification?.handleStatus = notiStatus.rawValue
    viewModel.clearSingleNotifyUnreadCount(notification: notifiModel.imNotification!)
    for noti in notifiModels {
      noti.handleStatus = notiStatus
      noti.imNotification?.handleStatus = notiStatus.rawValue
      viewModel.clearSingleNotifyUnreadCount(notification: noti.imNotification!)
    }
    notifiModel.unReadCount = 0
    loadData()
  }

  open func onAccept(_ notifiModel: NENotification) {
    weak var weakSelf = self
    guard let teamId = notifiModel.targetID, let invitorId = notifiModel.sourceID else {
      return
    }

    if notifiModel.type == .teamInvite {
      viewModel.acceptInviteWithTeam(teamId, invitorId) { error in
        NELog.infoLog(
          ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"),
          desc: "CALLBACK acceptInviteWithTeam " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"), desc: "❌CALLBACK acceptInviteWithTeam failed,error = \(error!.localizedDescription)")
          if err.code == 807 || err.code == 809 {
            weakSelf?.showToast(localizable("validate_processed"))
          } else if err.code == teamNotExistCode {
            weakSelf?.showToast(localizable("team_not_exist"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeOk)
        }
      }
    } else if notifiModel.type == .addFriendRequest {
      viewModel.agreeRequest(invitorId) { error in
        NELog.infoLog(
          ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"),
          desc: "CALLBACK agreeRequest " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          NELog.infoLog(ModuleName + " " + self.tag, desc: "❌CALLBACK agreeRequest failed,error = \(error!)")
          weakSelf?.showToast(localizable("failed_operation"))
        } else {
          weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeOk)

          Router.shared.use(ChatAddFriendRouter, parameters: ["text": localizable("let_us_chat"),
                                                              "sessionId": invitorId,
                                                              "sessionType": NIMSessionType.P2P])
        }
      }
    }
  }

  open func onRefuse(_ notifiModel: NENotification) {
    weak var weakSelf = self
    guard let teamId = notifiModel.targetID, let invitorId = notifiModel.sourceID else {
      return
    }

    if notifiModel.type == .teamInvite {
      weakSelf?.viewModel.rejectInviteWithTeam(teamId, invitorId) { error in
        NELog.infoLog(
          ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"),
          desc: "CALLBACK rejectInviteWithTeam " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"), desc: "❌CALLBACK rejectInviteWithTeam failed,error = \(error!.localizedDescription)")
          if err.code == 807 || err.code == 809 {
            weakSelf?.showToast(localizable("validate_processed"))
          } else if err.code == teamNotExistCode {
            weakSelf?.showToast(localizable("team_not_exist"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeNo)
        }
      }
    } else if notifiModel.type == .addFriendRequest {
      viewModel.refuseRequest(invitorId) { error in
        NELog.infoLog(
          ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"),
          desc: "CALLBACK refuseRequest " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ValidationMessageViewController"), desc: "❌CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
          if err.code == 509 {
            weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeOk)
            weakSelf?.showToast(localizable("validate_processed"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeNo)
        }
      }
    }
  }
}
