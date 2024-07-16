
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 用户信息界面 - 基类
@objcMembers
open class NEBaseContactUserViewController: NEContactBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  var user: NEUserWithFriend?
  var uid: String?
  var className = "ContactUserViewController"

  public let viewModel = ContactUserViewModel()
  var data = [[UserItem]]()
  public var headerView = NEBaseUserInfoHeaderView()
  public var tableViewTopAnchor: NSLayoutConstraint?

  /// 使用 accountId 初始化
  /// - Parameter accountId: 用户 id
  public init(uid: String) {
    super.init(nibName: nil, bundle: nil)
    self.uid = uid
  }

  /// 使用 V2NIMUser 初始化
  /// - Parameter nim_user: V2NIMUser 对象
  public init(nim_user: V2NIMUser) {
    super.init(nibName: nil, bundle: nil)
    user = NEUserWithFriend(user: nim_user)
    uid = user?.user?.accountId
  }

  /// 使用 NEUserWithFriend 初始化
  /// - Parameter user: NEUserWithFriend 对象
  public init(user: NEUserWithFriend?) {
    super.init(nibName: nil, bundle: nil)
    self.user = user
    uid = user?.user?.accountId
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableViewTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
    ContactRepo.shared.addContactListener(self)

    // 数字人无需远端查询信息
    if user?.user is V2NIMAIUser {
      loadData()
      return
    }

    if let userId = uid {
      weak var weakSelf = self
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"), .bottom)
      }
      view.makeToastActivity(.center)
      viewModel.getUserInfo(userId) { user, error in
        weakSelf?.view.hideToastActivity()
        NEALog.infoLog(
          weakSelf?.className ?? "ContactUserViewController",
          desc: "CALLBACK getUserInfo " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else if let u = user {
          weakSelf?.user = u
          weakSelf?.loadData()
          NotificationCenter.default.post(name: NENotificationName.didTapHeader, object: user)
        }
      }
    }
  }

  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  open func commonUI() {
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.moreButton.isHidden = true

    view.addSubview(tableView)
    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
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
    guard let uid = user?.user?.accountId ?? uid else { return }

    // 数字人信息从缓存中取
    if let aiUser: NEUserWithFriend = NEAIUserManager.shared.getAIUserById(uid) {
      user = aiUser
    }

    if user?.user is V2NIMAIUser {
      // 数字人仅展示【聊天】
      data = [
        [
          UserItem(title: localizable("chat"),
                   detailTitle: "",
                   value: false,
                   textColor: UIColor(hexString: "#337EFF"),
                   cellClass: CenterTextCell.self),
        ],
      ]
    } else if NEFriendUserCache.shared.isFriend(uid) {
      data = [
        [
          UserItem(title: localizable("noteName"),
                   detailTitle: user?.friend?.alias,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithRightArrowCell.self),
        ],
        [
          UserItem(title: localizable("birthday"),
                   detailTitle: user?.user?.birthday,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
          UserItem(title: localizable("phone"),
                   detailTitle: user?.user?.mobile,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
          UserItem(title: localizable("email"),
                   detailTitle: user?.user?.email,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
          UserItem(title: localizable("sign"),
                   detailTitle: user?.user?.sign,
                   value: false,
                   textColor: UIColor.darkText,
                   cellClass: TextWithDetailTextCell.self),
        ],

        [
          UserItem(title: localizable("add_blackList"),
                   detailTitle: "",
                   value: NEFriendUserCache.shared.isBlockAccount(uid),
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
                   detailTitle: "",
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
      if let uid = user?.user?.accountId {
        if NEFriendUserCache.shared.isFriend(uid) {
          loadData()
        } else {
          addFriend()
        }
      }
    }
  }

  open func getContactAliasViewController() -> NEBaseContactAliasViewController {
    NEBaseContactAliasViewController()
  }

  func toEditRemarks() {
    let remark = getContactAliasViewController()
    remark.user = user
    remark.completion = { [weak self] u in
      self?.user = u
      self?.headerView.setData(user: u)
    }
    navigationController?.pushViewController(remark, animated: true)

    print("edit remarks")
  }

  func allowNotify(allow: Bool) {
    print("edit remarks")
  }

  func blackList(isBlack: Bool, completion: @escaping () -> Void) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      completion()
      return
    }

    guard let userId = user?.user?.accountId else {
      return
    }

    if isBlack {
      // add
      viewModel.contactRepo.addBlockList(accountId: userId) { [weak self] error in
        if let err = error {
          self?.showToast(err.localizedDescription)
          completion()
        }
      }

    } else {
      // remove
      viewModel.contactRepo.removeBlockList(accountId: userId) { [weak self] error in
        if let err = error {
          self?.showToast(err.localizedDescription)
          completion()
        }
      }
    }
  }

  func chat(user: NEUserWithFriend?) {
    guard let accid = self.user?.user?.accountId else {
      return
    }

    let conversationId = V2NIMConversationIdUtil.p2pConversationId(accid)
    Router.shared.use(
      PushP2pChatVCRouter,
      parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any, "removeUserVC": true],
      closure: nil
    )
  }

  func deleteFriendAction(user: NEUserWithFriend?) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    if let userId = user?.user?.accountId {
      viewModel.deleteFriend(account: userId) { error in
        NEALog.infoLog(
          self.className,
          desc: "CALLBACK deleteFriend " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self.showToast(error?.localizedDescription ?? "")
        } else {
          self.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  open func deleteFriend(user: NEUserWithFriend?) {
    let alertTitle = String(format: localizable("delete_title"), user?.showName() ?? "")
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
    if let account = user?.user?.accountId {
      viewModel.addFriend(account) { error in
        NEALog.infoLog(
          self.className,
          desc: "CALLBACK addFriend " + (error?.localizedDescription ?? "no error")
        )
        if let err = error {
          NEALog.errorLog("ContactUserViewController", desc: "add friend failed :\(err)")
        } else {
          weakSelf?.showToast(localizable("send_friend_apply"))
          if NEFriendUserCache.shared.isBlockAccount(account) {
            weakSelf?.viewModel.removeBlackList(account: account) { err in
              NEALog.infoLog(
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

// MARK: - NEContactListener

extension NEBaseContactUserViewController: NEContactListener {
  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if contact.user?.accountId == uid {
        user = contact
        loadData()
      }
    }
  }
}
