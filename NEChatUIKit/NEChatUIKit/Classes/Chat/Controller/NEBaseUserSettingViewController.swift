
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseUserSettingViewController: ChatBaseViewController, UserSettingViewModelDelegate,
  UITableViewDataSource, UITableViewDelegate {
  public var userId: String?

  let viewmodel = UserSettingViewModel()

  lazy var userHeader: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(16.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  lazy var addBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("setting_add"), for: .normal)
    button.accessibilityIdentifier = "id.add"
    return button
  }()

  lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12.0)
    label.textColor = .ne_darkText
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  lazy var contentTable: UITableView = {
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

  public var cellClassDic = [Int: NEBaseUserSettingCell.Type]()

  public init(userId: String) {
    super.init(nibName: nil, bundle: nil)
    self.userId = userId
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.delegate = self
    if let uid = userId {
      viewmodel.getUserSettingModel(uid)
      contentTable.tableHeaderView = headerView()
      contentTable.reloadData()
    }
    setupUI()
  }

  func setupUI() {
    view.backgroundColor = .ne_lightBackgroundColor
    title = chatLocalizable("chat_setting")
    navigationView.moreButton.isHidden = true
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    cellClassDic.forEach { (key: Int, value: NEBaseUserSettingCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
    if let pan = navigationController?.interactivePopGestureRecognizer {
      contentTable.panGestureRecognizer.require(toFail: pan)
    }
  }

  open func headerView() -> UIView {
    let header = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 110))
    header.backgroundColor = .clear
    let cornerBack = UIView()
    cornerBack.layer.cornerRadius = 8.0
    cornerBack.backgroundColor = .white
    cornerBack.translatesAutoresizingMaskIntoConstraints = false
    header.addSubview(cornerBack)
    NSLayoutConstraint.activate([
      cornerBack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12),
      cornerBack.leftAnchor.constraint(equalTo: header.leftAnchor, constant: 20),
      cornerBack.widthAnchor.constraint(equalToConstant: kScreenWidth - 40),
      cornerBack.heightAnchor.constraint(equalToConstant: 86.0),
    ])

    cornerBack.addSubview(userHeader)
    let tap = UITapGestureRecognizer()
    userHeader.addGestureRecognizer(tap)
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1

    if let url = viewmodel.userInfo?.userInfo?.avatarUrl, !url.isEmpty {
      userHeader.sd_setImage(with: URL(string: url), completed: nil)
      userHeader.setTitle("")
      userHeader.backgroundColor = .clear
    } else if let name = viewmodel.userInfo?.showName(false) {
      userHeader.sd_setImage(with: nil)
      userHeader.setTitle(name)
      userHeader.backgroundColor = UIColor.colorWithString(string: viewmodel.userInfo?.userId)
    }

    nameLabel.text = viewmodel.userInfo?.showName()
    cornerBack.addSubview(nameLabel)
    if IMKitClient.instance.getConfigCenter().teamEnable {
      NSLayoutConstraint.activate([
        userHeader.leftAnchor.constraint(equalTo: cornerBack.leftAnchor, constant: 16),
        userHeader.topAnchor.constraint(equalTo: cornerBack.topAnchor, constant: 12),
        userHeader.widthAnchor.constraint(equalToConstant: 42),
        userHeader.heightAnchor.constraint(equalToConstant: 42),
      ])

      nameLabel.font = NEConstant.defaultTextFont(12)
      nameLabel.textAlignment = .center
      NSLayoutConstraint.activate([
        nameLabel.leftAnchor.constraint(equalTo: userHeader.leftAnchor, constant: -12.0),
        nameLabel.rightAnchor.constraint(equalTo: userHeader.rightAnchor, constant: 12.0),
        nameLabel.topAnchor.constraint(equalTo: userHeader.bottomAnchor, constant: 6.0),
      ])

      cornerBack.addSubview(addBtn)
      addBtn.addTarget(self, action: #selector(createDiscuss), for: .touchUpInside)
      NSLayoutConstraint.activate([
        addBtn.leftAnchor.constraint(equalTo: userHeader.rightAnchor, constant: 20.0),
        addBtn.topAnchor.constraint(equalTo: userHeader.topAnchor),
        addBtn.widthAnchor.constraint(equalToConstant: 42.0),
        addBtn.heightAnchor.constraint(equalToConstant: 42.0),
      ])
    } else {
      NSLayoutConstraint.activate([
        userHeader.leftAnchor.constraint(equalTo: cornerBack.leftAnchor, constant: 16),
        userHeader.centerYAnchor.constraint(equalTo: cornerBack.centerYAnchor),
        userHeader.widthAnchor.constraint(equalToConstant: 60),
        userHeader.heightAnchor.constraint(equalToConstant: 60),
      ])

      nameLabel.font = NEConstant.defaultTextFont(16)
      nameLabel.textAlignment = .left
      NSLayoutConstraint.activate([
        nameLabel.leftAnchor.constraint(equalTo: userHeader.rightAnchor, constant: 16.0),
        nameLabel.rightAnchor.constraint(equalTo: cornerBack.rightAnchor),
        nameLabel.centerYAnchor.constraint(equalTo: userHeader.centerYAnchor),
      ])
    }

    return header
  }

  open func filterStackViewController() -> [UIViewController]? {
    navigationController?.viewControllers.filter {
      if $0.isKind(of: ChatViewController.self) || $0
        .isKind(of: NEBaseUserSettingViewController.self) {
        return false
      }
      return true
    }
  }

  func createDiscuss() {
    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting create disscuss  : ", param)
      var convertParam = [String: Any]()
      param.forEach { (key: String, value: Any) in
        if key == "names", let names = value as? String {
          convertParam[key] = "\(weakSelf?.nameLabel.text ?? "")、\(names)"
        } else {
          convertParam[key] = value
        }
      }
      weakSelf?.view.makeToastActivity(.center)
      Router.shared.use(TeamCreateDisuss, parameters: convertParam, closure: nil)
    }
    var filters = Set<String>()
    if let uid = userId {
      filters.insert(uid)
    }

    Router.shared.use(
      ContactUserSelectRouter,
      parameters: [
        "nav": navigationController as Any,
        "filters": filters,
        "limit": 199,
        "uid": userId ?? "",
      ],
      closure: nil
    )

    Router.shared.register(TeamCreateDiscussResult) { param in
      print("create discuss ", param)
      weakSelf?.view.hideToastActivity()
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        let session = NIMSession(teamid, type: .team)

        DispatchQueue.main.async {
          if let allControllers = weakSelf?.filterStackViewController() {
            weakSelf?.navigationController?.viewControllers = allControllers
            Router.shared.use(
              PushTeamChatVCRouter,
              parameters: ["nav": weakSelf?.navigationController as Any,
                           "session": session as Any],
              closure: nil
            )
          }
        }
      } else if let error = param["msg"] as? String {
        weakSelf?.showToast(error)
      }
    }
  }

  open func showUserInfo() {
    if let user = viewmodel.userInfo {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "user": user],
        closure: nil
      )
    }
  }

  func didNeedRefreshUI() {
    contentTable.reloadData()
  }

  func didError(_ error: Error) {
    showToast(error.localizedDescription)
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel.cellDatas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.cellDatas[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseUserSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func getPinMessageViewController(session: NIMSession) -> NEBasePinMessageViewController {
    NEBasePinMessageViewController(session: session)
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      if let accid = userId {
        let session = NIMSession(accid, type: .P2P)
        let pin = getPinMessageViewController(session: session)
        navigationController?.pushViewController(pin, animated: true)
      }
    }
  }
}
