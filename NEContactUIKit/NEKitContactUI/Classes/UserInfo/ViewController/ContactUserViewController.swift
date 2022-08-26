
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCore
import NIMSDK
public class ContactUserViewController: ContactBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  private var user: User?
  private var uid: String?
  public var isBlack: Bool = false

  let viewModel = ContactUserViewModel()
  var tableView = UITableView(frame: .zero, style: .grouped)
  var data = [[UserItem]]()
  var headerView: UserInfoHeaderView?

  init(user: User?) {
    super.init(nibName: nil, bundle: nil)
    self.user = user
  }

  init(uid: String) {
    super.init(nibName: nil, bundle: nil)
    self.uid = uid
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    if user != nil {
      commonUI()
      loadData()
    } else if let userId = uid {
      weak var weakSelf = self
      viewModel.getUserInfo(userId) { error, user in
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else if let u = user {
          weakSelf?.user = u
          weakSelf?.commonUI()
          weakSelf?.loadData()
        }
      }
    }
  }

  func commonUI() {
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.sectionHeaderHeight = 6
    view.addSubview(tableView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        self.tableView.topAnchor
          .constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.topAnchor),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }
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

    tableView.rowHeight = 62
    headerView =
      UserInfoHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width,
                                       height: 113))
    headerView?.setData(user: user)
    tableView.tableHeaderView = headerView
  }

  func loadData() {
    let isFriend = viewModel.contactRepo.isFriend(account: user?.userId ?? "")
    isBlack = viewModel.contactRepo.isBlackList(account: user?.userId ?? "")

    if isFriend {
      data = [
        [UserItem(
          title: localizable("备注名"),
          detailTitle: user?.alias,
          value: false,
          textColor: UIColor.darkText,
          cellClass: TextWithRightArrowCell.self
        )],
        [
          UserItem(title: localizable("手机"), detailTitle: user?.userInfo?.mobile,
                   value: false,
                   textColor: UIColor.darkText, cellClass: TextWithDetailTextCell.self),
          UserItem(
            title: localizable("邮箱"),
            detailTitle: user?.userInfo?.email,
            value: false,
            textColor: UIColor.darkText,
            cellClass: TextWithDetailTextCell.self
          ),
          UserItem(
            title: localizable("个性签名"),
            detailTitle: user?.userInfo?.sign,
            value: false,
            textColor: UIColor.darkText,
            cellClass: TextWithDetailTextCell.self
          ),
        ],
        // UserItem(title: localizable("消息提醒"), detailTitle: "", value: false, textColor: UIColor.darkText, cellClass: TextWithSwitchCell.self) 隐藏消息提醒
        [UserItem(
          title: localizable("加入黑名单"),
          detailTitle: "",
          value: isBlack,
          textColor: UIColor.darkText,
          cellClass: TextWithSwitchCell.self
        )],
        [
          UserItem(title: localizable("聊天"), detailTitle: "", value: false,
                   textColor: UIColor(hexString: "#337EFF"), cellClass: CenterTextCell.self),
          UserItem(
            title: localizable("删除好友"),
            detailTitle: "",
            value: false,
            textColor: UIColor.red,
            cellClass: CenterTextCell.self
          ),
        ],
      ]
    } else {
      data = [[UserItem(
        title: localizable("添加好友"),
        detailTitle: user?.alias,
        value: false,
        textColor: UIColor(hexString: "#337EFF"),
        cellClass: CenterTextCell.self
      )]]
    }
    tableView.reloadData()
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    data.count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    data[section].count
  }

  public func tableView(_ tableView: UITableView,
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
      return c
    }

    if let c = cell as? TextWithSwitchCell {
      c.titleLabel.text = item.title
      c.switchButton.isOn = item.value
      c.block = { [weak self] title, value in
        print("title:\(title) value\(value)")
        if title == localizable("加入黑名单") {
          self?.blackList(isBlack: value)
        } else if title == localizable("消息提醒") {}
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

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = data[indexPath.section][indexPath.row]
    if item.title == localizable("备注名") {
      toEditRemarks()
    }
//        if item.title == localizable("消息提醒") {
//            allowNotify(allow: item.value)
//        }
//        if item.title == localizable("加入黑名单") {
//            blackList(isBlack: item.value)
//        }
    if item.title == localizable("聊天") {
      chat(user: user)
    }
    if item.title == localizable("删除好友") {
      deleteFriend(user: user)
    }
    if item.title == localizable("添加好友") {
      addFriend()
    }
  }

  func toEditRemarks() {
    let remark = ContactRemakNameViewController()
    remark.user = user
    remark.completion = { u in
      self.user = u
      self.headerView?.setData(user: u)
    }
    navigationController?.pushViewController(remark, animated: true)

    print("edit remarks")
  }

  func allowNotify(allow: Bool) {
    print("edit remarks")
  }

  func blackList(isBlack: Bool) {
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

  func chat(user: User?) {
    print("edit remarks")
    guard let accid = self.user?.userId else {
      return
    }
    let session = NIMSession(accid, type: .P2P)
    Router.shared.use(
      PushP2pChatVCRouter,
      parameters: ["nav": navigationController, "session": session]
    ) { obj, routerState, str in
      print("obj:\(obj) routerState:\(routerState) str:\(str)")
    }
  }

  func deleteFriend(user: User?) {
    print("edit remarks")
    if let userId = user?.userId {
      viewModel.deleteFriend(account: userId) { error in
        if error != nil {
          self.showToast(error?.localizedDescription ?? "")
        } else {
          self.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  @objc func addFriend() {
    weak var weakSelf = self
    if let account = user?.userId {
      viewModel.addFriend(account) { error in
        if let err = error {
          NELog.errorLog("ContactUserViewController", desc: "❌add friend failed :\(err)")
        } else {
          weakSelf?.showToast("好友申请已发送")
        }
      }
    }
  }
}
