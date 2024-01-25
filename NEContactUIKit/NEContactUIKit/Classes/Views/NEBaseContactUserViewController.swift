
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseContactUserViewController: NEBaseContactViewController, UITableViewDelegate,
  UITableViewDataSource {
  var user: NEKitUser?
  var uid: String?
  public var isBlack: Bool = false
  var className = "ContactUserViewController"

  public let viewModel = ContactUserViewModel()
  public var tableView = UITableView(frame: .zero, style: .grouped)
  var data = [[UserItem]]()
  public var headerView = NEBaseUserInfoHeaderView()

  public init(user: NEKitUser?) {
    super.init(nibName: nil, bundle: nil)
    self.user = user
    uid = user?.userId
  }

  public init(uid: String) {
    super.init(nibName: nil, bundle: nil)
    self.uid = uid
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
    if let userId = uid {
      weak var weakSelf = self
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"), .bottom)
      }
      view.makeToastActivity(.center)
      viewModel.fetchUserInfo(accountList: [userId]) { users, error in
        weakSelf?.view.hideToastActivity()
        NELog.infoLog(
          weakSelf?.className ?? "ContactUserViewController",
          desc: "CALLBACK getUserInfo " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else if let u = users?.first {
          weakSelf?.user = u
          ChatUserCache.updateUserInfo(u)
          weakSelf?.loadData()
        }
      }
    }

    NIMSDK.shared().systemNotificationManager.add(self)
  }

  open func commonUI() {
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white

    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(
      TextWithRightArrowCell.self,
      forCellReuseIdentifier: "\(TextWithRightArrowCell.self)"
    )
    tableView.register(
      TextWithDetailTextCell.self,
      forCellReuseIdentifier: "\(TextWithDetailTextCell.self)"
    )
    tableView.register(
      TextWithSwitchCell.self,
      forCellReuseIdentifier: "\(TextWithSwitchCell.self)"
    )
    tableView.register(CenterTextCell.self, forCellReuseIdentifier: "\(CenterTextCell.self)")
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(UITableViewCell.self)")

    tableView.tableHeaderView = headerView
    headerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      headerView.topAnchor.constraint(equalTo: tableView.topAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 113),
      headerView.widthAnchor.constraint(equalToConstant: NEConstant.screenWidth),
    ])
  }

  func loadData() {
    let isFriend = viewModel.contactRepo.isFriend(account: user?.userId ?? "")
    isBlack = viewModel.contactRepo.isBlackList(account: user?.userId ?? "")

    if isFriend {
      data = [
        [
          UserItem(title: localizable("noteName"),
                   detailTitle: user?.alias,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithRightArrowCell.self),
        ],
        [
          UserItem(title: localizable("birthday"),
                   detailTitle: user?.userInfo?.birth,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
          UserItem(title: localizable("phone"),
                   detailTitle: user?.userInfo?.mobile,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
          UserItem(title: localizable("email"),
                   detailTitle: user?.userInfo?.email,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
          UserItem(title: localizable("sign"),
                   detailTitle: user?.userInfo?.sign,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
        ],

        [
          UserItem(title: localizable("add_blackList"),
                   detailTitle: "",
                   value: isBlack,
                   textColor: UIColor.darkText,
                   cellClass: TextWithSwitchCell.self),
        ],
        [
          UserItem(title: localizable("chat"),
                   detailTitle: "",
                   value: false,
                   textColor: UIColor(hexString: "#337EFF"),
                   cellClass: CenterTextCell.self),
          UserItem(title: localizable("delete_friend"),
                   detailTitle: "",
                   value: false,
                   textColor: UIColor.red,
                   cellClass: CenterTextCell.self),
        ],
      ]
    } else {
      data = [
        [
          UserItem(title: localizable("add_friend"),
                   detailTitle: user?.alias,
                   value: false,
                   textColor: UIColor(hexString: "#337EFF"),
                   cellClass: CenterTextCell.self),
        ],
      ]
    }

    headerView.setData(user: user)
    tableView.tableHeaderView = tableView.tableHeaderView
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

    if let c = cell as? TextWithRightArrowCell {
      c.titleLabel.text = item.title
      return c
    }

    if let c = cell as? TextWithDetailTextCell {
      c.titleLabel.text = item.title
      c.detailTitleLabel.text = item.detailTitle
      if item.title == localizable("sign") {
        c.detailTitleLabel.numberOfLines = 2
      }
      return c
    }

    if let c = cell as? TextWithSwitchCell {
      c.titleLabel.text = item.title
      c.switchButton.isOn = item.value
      c.block = { [weak self] title, value in
        print("title:\(title) value\(value)")
        if title == localizable("add_blackList") {
          self?.blackList(isBlack: value) {
            c.switchButton.isOn = !c.switchButton.isOn
          }
        } else if title == localizable("message_remind") {}
      }

      return c
    }

    if let c = cell as? CenterTextCell {
      c.titleLabel.text = item.title
      c.titleLabel.textColor = item.textColor
      return c
    }
    return cell
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    }
    return 6.0
  }

  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let header = UIView()
    header.backgroundColor = UIColor.clear
    return header
  }

  open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    0
  }

  open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    nil
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = data[indexPath.section][indexPath.row]
    if item.title == localizable("noteName") {
      toEditRemarks()
    }
//        if item.title == localizable("消息提醒") {
//            allowNotify(allow: item.value)
//        }
//        if item.title == localizable("加入黑名单") {
//            blackList(isBlack: item.value)
//        }
    if item.title == localizable("chat") {
      chat(user: user)
    }
    if item.title == localizable("delete_friend") {
      deleteFriend(user: user)
    }
    if item.title == localizable("add_friend") {
      if let uId = user?.userId,
         viewModel.isFriend(account: uId) {
        loadData()
      } else {
        addFriend()
      }
    }
  }

  open func getContactRemakNameViewController() -> NEBaseContactRemakNameViewController {
    NEBaseContactRemakNameViewController()
  }

  func toEditRemarks() {
    let remark = getContactRemakNameViewController()
    remark.user = user
    remark.completion = { [weak self] u in
      self?.user = u
      self?.headerView.setData(user: u)
      ChatUserCache.updateUserInfo(u)
    }
    navigationController?.pushViewController(remark, animated: true)

    print("edit remarks")
  }

  func allowNotify(allow: Bool) {
    print("edit remarks")
  }

  func blackList(isBlack: Bool, completion: () -> Void) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      completion()
      return
    }

    guard let userId = user?.userId else {
      return
    }
    if isBlack {
      // add
      viewModel.contactRepo.addBlackList(account: userId) { [weak self] error in
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        } else {
          // success
          self?.isBlack = true
          self?.loadData()
        }
      }

    } else {
      // remove
      viewModel.contactRepo.removeBlackList(account: userId) { [weak self] error in
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        } else {
          // success
          self?.isBlack = false
          self?.loadData()
        }
      }
    }
  }

  func chat(user: NEKitUser?) {
    guard let accid = self.user?.userId else {
      return
    }

    let session = NIMSession(accid, type: .P2P)
    Router.shared.use(
      PushP2pChatVCRouter,
      parameters: ["nav": navigationController as Any, "session": session, "removeUserVC": true],
      closure: nil
    )
  }

  func deleteFriendAction(user: NEKitUser?) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    if let userId = user?.userId {
      viewModel.deleteFriend(account: userId) { error in
        NELog.infoLog(
          self.className,
          desc: "CALLBACK deleteFriend " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self.showToast(error?.localizedDescription ?? "")
        } else {
          ChatUserCache.removeUserInfo(userId)
          self.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  open func deleteFriend(user: NEKitUser?) {
    let alertTitle = String(format: localizable("delete_title"), user?.showName(true) ?? "")
    let alertController = UIAlertController(
      title: alertTitle,
      message: nil,
      preferredStyle: .actionSheet
    )
    alertController.view.findLabel(with: alertTitle)?.accessibilityIdentifier = "id.action1"

    let cancelAction = UIAlertAction(
      title: commonLocalizable("cancel"),
      style: .cancel,
      handler: nil
    )
    cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    cancelAction.accessibilityIdentifier = "id.action3"

    let deleteAction = UIAlertAction(title: localizable("delete_friend"),
                                     style: .default) { [weak self] action in
      self?.deleteFriendAction(user: user)
    }
    deleteAction.setValue(UIColor.ne_redText, forKey: "_titleTextColor")
    deleteAction.accessibilityIdentifier = "id.action2"

    alertController.addAction(cancelAction)
    alertController.addAction(deleteAction)
    fixAlertOnIpad(alertController)
    present(alertController, animated: true, completion: nil)
  }

  func addFriend() {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    if let account = user?.userId {
      viewModel.addFriend(account) { error in
        NELog.infoLog(
          self.className,
          desc: "CALLBACK addFriend " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          NELog.errorLog("ContactUserViewController", desc: "❌add friend failed :\(err)")
        } else {
          weakSelf?.showToast(localizable("send_friend_apply"))
          if let model = weakSelf?.viewModel,
             model.isBlack(account: account) {
            weakSelf?.viewModel.removeBlackList(account: account) { err in
              NELog.infoLog(
                self.className,
                desc: #function + "CALLBACK " + (err?.localizedDescription ?? "no error")
              )
            }
          }
        }
      }
    }
  }
}

extension NEBaseContactUserViewController: NIMSystemNotificationManagerDelegate {
  open func onReceive(_ notification: NIMSystemNotification) {
    if notification.type == .friendAdd,
       let obj = notification.attachment as? NIMUserAddAttachment,
       obj.operationType == .verify {
      loadData()
    }
  }
}
