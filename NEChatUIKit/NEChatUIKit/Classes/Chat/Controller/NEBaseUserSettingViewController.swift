
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseUserSettingViewController: NEChatBaseViewController, UserSettingViewModelDelegate,
  UITableViewDataSource, UITableViewDelegate {
  public var userId: String?

  let viewModel = UserSettingViewModel()

  public lazy var userHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(16.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  public lazy var addButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("setting_add"), for: .normal)
    button.accessibilityIdentifier = "id.add"
    return button
  }()

  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12.0)
    label.textColor = .ne_darkText
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  public var contentTableTopAnchor: NSLayoutConstraint?
  public lazy var contentTable: UITableView = {
    let contentTable = UITableView()
    contentTable.translatesAutoresizingMaskIntoConstraints = false
    contentTable.backgroundColor = .clear
    contentTable.dataSource = self
    contentTable.delegate = self
    contentTable.separatorColor = .clear
    contentTable.separatorStyle = .none
    contentTable.sectionHeaderHeight = 12.0
    contentTable
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    if #available(iOS 15.0, *) {
      contentTable.sectionHeaderTopPadding = 0.0
    }
    return contentTable
  }()

  public var cellClassDic = [Int: NEBaseUserSettingCell.Type]()

  public init(userId: String) {
    super.init(nibName: nil, bundle: nil)
    self.userId = userId
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    contentTableTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewModel.delegate = self
    if let uid = userId {
      viewModel.getConversation(uid) { [weak self] error in
        self?.viewModel.getUserSettingModel(uid) { [weak self] in
          self?.contentTable.tableHeaderView = self?.headerView()
          self?.didLoadData()
          self?.contentTable.reloadData()
        }
      }
    }
    setupUI()
  }

  /// 渲染数据开始，在子类中使用
  open func didLoadData() {}

  func setupUI() {
    view.backgroundColor = .ne_lightBackgroundColor
    title = chatLocalizable("chat_setting")
    navigationView.moreButton.isHidden = true
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(contentTable)
    contentTableTopAnchor = contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    contentTableTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    for (key, value) in cellClassDic {
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
    if let pan = navigationController?.interactivePopGestureRecognizer {
      contentTable.panGestureRecognizer.require(toFail: pan)
    }
  }

  open func headerView() -> UIView {
    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 110))
    headerView.backgroundColor = .clear
    let cornerBackView = UIView()
    cornerBackView.layer.cornerRadius = 8.0
    cornerBackView.backgroundColor = .white
    cornerBackView.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(cornerBackView)
    NSLayoutConstraint.activate([
      cornerBackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
      cornerBackView.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 20),
      cornerBackView.widthAnchor.constraint(equalToConstant: kScreenWidth - 40),
      cornerBackView.heightAnchor.constraint(equalToConstant: 86.0),
    ])

    cornerBackView.addSubview(userHeaderView)
    let tapGesture = UITapGestureRecognizer()
    userHeaderView.addGestureRecognizer(tapGesture)
    tapGesture.numberOfTapsRequired = 1
    tapGesture.numberOfTouchesRequired = 1

    if let url = viewModel.userInfo?.user?.avatar, !url.isEmpty {
      userHeaderView.sd_setImage(with: URL(string: url), completed: nil)
      userHeaderView.setTitle("")
      userHeaderView.backgroundColor = .clear
    } else if let name = viewModel.userInfo?.showName() {
      userHeaderView.sd_setImage(with: nil)
      userHeaderView.setTitle(name)
      userHeaderView.backgroundColor = UIColor.colorWithString(string: viewModel.userInfo?.user?.accountId)
    }

    nameLabel.text = viewModel.userInfo?.showName()
    cornerBackView.addSubview(nameLabel)
    if IMKitConfigCenter.shared.enableTeam {
      NSLayoutConstraint.activate([
        userHeaderView.leftAnchor.constraint(equalTo: cornerBackView.leftAnchor, constant: 16),
        userHeaderView.topAnchor.constraint(equalTo: cornerBackView.topAnchor, constant: 12),
        userHeaderView.widthAnchor.constraint(equalToConstant: fun_chat_min_h),
        userHeaderView.heightAnchor.constraint(equalToConstant: fun_chat_min_h),
      ])

      nameLabel.font = NEConstant.defaultTextFont(12)
      nameLabel.textAlignment = .center
      NSLayoutConstraint.activate([
        nameLabel.leftAnchor.constraint(equalTo: userHeaderView.leftAnchor, constant: -12.0),
        nameLabel.rightAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 12.0),
        nameLabel.topAnchor.constraint(equalTo: userHeaderView.bottomAnchor, constant: 6.0),
      ])

      cornerBackView.addSubview(addButton)
      addButton.addTarget(self, action: #selector(createDiscuss), for: .touchUpInside)
      NSLayoutConstraint.activate([
        addButton.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 20.0),
        addButton.topAnchor.constraint(equalTo: userHeaderView.topAnchor),
        addButton.widthAnchor.constraint(equalToConstant: 42.0),
        addButton.heightAnchor.constraint(equalToConstant: 42.0),
      ])

    } else {
      NSLayoutConstraint.activate([
        userHeaderView.leftAnchor.constraint(equalTo: cornerBackView.leftAnchor, constant: 16),
        userHeaderView.centerYAnchor.constraint(equalTo: cornerBackView.centerYAnchor),
        userHeaderView.widthAnchor.constraint(equalToConstant: 60),
        userHeaderView.heightAnchor.constraint(equalToConstant: 60),
      ])

      nameLabel.font = NEConstant.defaultTextFont(16)
      nameLabel.textAlignment = .left
      NSLayoutConstraint.activate([
        nameLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 16.0),
        nameLabel.rightAnchor.constraint(equalTo: cornerBackView.rightAnchor),
        nameLabel.centerYAnchor.constraint(equalTo: userHeaderView.centerYAnchor),
      ])
    }

    return headerView
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
      for (key, value) in param {
        if key == "names", let names = value as? String {
          convertParam[key] = "\(weakSelf?.nameLabel.text ?? "")、\(names)"
        } else {
          convertParam[key] = value
        }
      }
      weakSelf?.view.makeToastActivity(.center)
      Router.shared.use(TeamCreateDisuss, parameters: convertParam, closure: nil)
    }

    // 单聊设置-创建讨论组-人员选择页面不包含自己
    var filters = Set<String>()
    filters.insert(IMKitClient.instance.account())

    // 单聊设置-创建讨论组-人员选择页面不包含单聊对方
    if let uid = userId {
      filters.insert(uid)
    }

    if IMKitConfigCenter.shared.enableAIUser {
      Router.shared.use(
        ContactFusionSelectRouter,
        parameters: [
          "nav": navigationController as Any,
          "filters": filters,
          "limit": inviteNumberLimit,
          "uid": userId ?? "",
        ],
        closure: nil
      )
    } else {
      Router.shared.use(
        ContactUserSelectRouter,
        parameters: [
          "nav": navigationController as Any,
          "filters": filters,
          "limit": inviteNumberLimit,
          "uid": userId ?? "",
        ],
        closure: nil
      )
    }

    Router.shared.register(TeamCreateDiscussResult) { param in
      print("create discuss ", param)
      weakSelf?.view.hideToastActivity()
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        let conversationId = V2NIMConversationIdUtil.teamConversationId(teamid)

        DispatchQueue.main.async {
          if let allControllers = weakSelf?.filterStackViewController() {
            weakSelf?.navigationController?.viewControllers = allControllers
            Router.shared.use(
              PushTeamChatVCRouter,
              parameters: ["nav": weakSelf?.navigationController as Any,
                           "conversationId": conversationId as Any],
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
    if let user = viewModel.userInfo {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "user": user],
        closure: nil
      )
    }
  }

  func didNeedRefreshUI() {
    didLoadData()
    contentTable.reloadData()
  }

  func didError(_ error: Error) {
    showToast(error.localizedDescription)
  }

  func didShowErrorMsg(_ msg: String) {
    showToast(msg)
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.cellDatas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.cellDatas[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseUserSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func getPinMessageViewController(conversationId: String) -> NEBasePinMessageViewController {
    NEBasePinMessageViewController(conversationId: conversationId)
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      if let accid = userId, let conversationId = V2NIMConversationIdUtil.p2pConversationId(accid) {
        let pin = getPinMessageViewController(conversationId: conversationId)
        navigationController?.pushViewController(pin, animated: true)
      }
    }
  }
}
