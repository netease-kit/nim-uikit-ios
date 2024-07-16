
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamMembersController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource, TeamMemberCellDelegate, TeamMembersViewModelDelegate {
  /// 群id
  public var teamId: String?
  /// 群成员数据
  public var memberDatas: [NETeamMemberInfoModel]? {
    didSet {
      viewModel.setShowDatas(memberDatas)
    }
  }

  /// 创建者account id
  public var ownerId: String?

  public var isSenior = false

  public let backView = UIView()

  let viewModel = TeamMembersViewModel()

  /// 搜索输入控件
  public lazy var searchTextField: UITextField = {
    let field = UITextField()
    field.translatesAutoresizingMaskIntoConstraints = false
    field.placeholder = commonLocalizable("search")
    field.clearButtonMode = .always
    field.textColor = .ne_greyText
    field.font = UIFont.systemFont(ofSize: 14.0)
    field.backgroundColor = UIColor.ne_backcolor
    if let clearButton = field.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    field.accessibilityIdentifier = "id.search"
    return field
  }()

  /// 群成员列表视图
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

  /// 空占位图
  public lazy var emptyView: NEEmptyDataView = {
    // member_select_no_member
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("no_result"), frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view
  }()

  /// 搜索背景图
  public lazy var searchIconImageView: UIImageView = {
    let searchIconImageView = UIImageView()
    searchIconImageView.image = coreLoader.loadImage("search_icon")
    searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
    return searchIconImageView
  }()

  public init(teamId: String?) {
    super.init(nibName: nil, bundle: nil)
    self.teamId = teamId
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    addObserver()
    viewModel.delegate = self
    viewModel.teamId = teamId
    navigationView.moreButton.isHidden = true
    weak var weakSelf = self
    if let tid = teamId {
      weakSelf?.viewModel.getTeamInfo(tid) { teamInfo, error in
        weakSelf?.ownerId = teamInfo?.team?.ownerAccountId
        if error != nil {
          weakSelf?.emptyView.isHidden = false
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          }
        } else {
          if teamInfo?.team?.isDisscuss() == false {
            weakSelf?.isSenior = true
            weakSelf?.title = localizable("group_memmber")
          } else {
            weakSelf?.title = localizable("discuss_mebmer")
          }
          if IMKitConfigCenter.shared.onlineStatusEnable {
            if let members = teamInfo?.users {
              var subcribeMembers = [NETeamMemberInfoModel]()
              for model in members {
                if let account = model.teamMember?.accountId {
                  if account != IMKitClient.instance.account() {
                    subcribeMembers.append(model)
                  }
                }
              }
              weakSelf?.viewModel.subcribeMembers(members) { error in
                NEALog.infoLog(weakSelf?.className() ?? "", desc: "sub cribe members error : \(error?.localizedDescription ?? "")")
              }
            }
          }
          weakSelf?.didNeedRefreshUI()
        }
      }
    }
    setupUI()
  }

  /// UI 初始化
  open func setupUI() {
    backView.backgroundColor = .clear
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 4.0

    view.addSubview(backView)
    NSLayoutConstraint.activate([
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0 + topConstant),
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      backView.heightAnchor.constraint(equalToConstant: 32),
    ])

    backView.addSubview(searchIconImageView)
    NSLayoutConstraint.activate([
      searchIconImageView.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
      searchIconImageView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16.0),
    ])

    backView.addSubview(searchTextField)
    NSLayoutConstraint.activate([
      searchTextField.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 36.0),
      searchTextField.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16.0),
      searchTextField.topAnchor.constraint(equalTo: backView.topAnchor),
      searchTextField.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
    ])

    view.addSubview(contentTableView)
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: backView.bottomAnchor, constant: 10),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentTableView.register(NEBaseTeamMemberCell.self, forCellReuseIdentifier: "\(NEBaseTeamMemberCell.self)")

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: contentTableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: contentTableView.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: contentTableView.topAnchor, constant: 50),
      emptyView.bottomAnchor.constraint(equalTo: contentTableView.bottomAnchor),
    ])
  }

  func addObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )
  }

  func isOwner(_ userId: String?) -> Bool {
    if isSenior == false {
      return false
    }
    if let uid = userId, let oid = ownerId, uid == oid {
      return true
    }
    return false
  }

  func textChange() {
    viewModel.searchDatas.removeAll()
    if let text = searchTextField.text, text.count > 0 {
      for model in viewModel.datas {
        if let teamName = model.atNameInTeam() {
          if teamName.contains(text) {
            viewModel.searchDatas.append(model)
          }
        }
      }
    } else {
      emptyView.isHidden = true
    }
    didNeedRefreshUI()
  }

  func getRealModel(_ index: Int) -> NETeamMemberInfoModel? {
    if let text = searchTextField.text, text.count > 0 {
      return viewModel.searchDatas[index]
    }
    return viewModel.datas[index]
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let text = searchTextField.text, text.count > 0 {
      return viewModel.searchDatas.count
    }
    return viewModel.datas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NEBaseTeamMemberCell.self)",
      for: indexPath
    ) as? NEBaseTeamMemberCell {
      if let model = getRealModel(indexPath.row) {
        cell.configure(model)
        cell.ownerLabel.isHidden = !isOwner(model.nimUser?.user?.accountId)
      }
      return cell
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    62.0
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let model = getRealModel(indexPath.row), let user = model.nimUser {
      if IMKitClient.instance.isMe(user.user?.accountId) {
        Router.shared.use(
          MeSettingRouter,
          parameters: ["nav": navigationController as Any],
          closure: nil
        )
      } else {
        if let uid = user.user?.accountId {
          Router.shared.use(
            ContactUserInfoPageRouter,
            parameters: ["nav": navigationController as Any, "uid": uid],
            closure: nil
          )
        }
      }
    }
  }

  /// 移除群成员
  /// - Parameter model: 成员信息
  /// - Parameter index: 成员索引
  func didClickRemoveButton(_ model: NETeamMemberInfoModel?, _ index: Int) {
    print("did click remove button")
    weak var weakSelf = self
    showAlert(title: localizable("remove_manager_title"), message: localizable("remove_member_tip")) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.view.makeToast(commonLocalizable("network_error"))
        return
      }

      if let tid = weakSelf?.teamId, let uid = model?.nimUser?.user?.accountId {
        weakSelf?.viewModel.removeTeamMember(tid, [uid]) { error in
          if let err = error {
            if err.code == noPermissionCode {
              weakSelf?.view.makeToast(localizable("no_permission_tip"))
            } else {
              weakSelf?.view.makeToast(localizable("remove_failed"))
            }
          } else {
            if let text = weakSelf?.searchTextField.text, text.count > 0 {
              weakSelf?.viewModel.searchDatas.remove(at: index)
              weakSelf?.viewModel.searchDatas.removeAll(where: { model in
                if model.teamMember?.accountId == uid {
                  return true
                }
                return false
              })
              weakSelf?.viewModel.removeModel(model)
              weakSelf?.didNeedRefreshUI()
            } else {
              weakSelf?.viewModel.removeModel(model)
              weakSelf?.didNeedRefreshUI()
            }
          }
        }
      }
    }
  }

  func didNeedRefreshUI() {
    if let text = searchTextField.text, text.count > 0 {
      emptyView.isHidden = viewModel.searchDatas.count > 0
    }
    contentTableView.reloadData()
  }

  override open func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if IMKitConfigCenter.shared.onlineStatusEnable {
      if parent == nil {
        viewModel.unSubcribeMembers(viewModel.datas) { [weak self] error in
          NEALog.infoLog(self?.className() ?? " ", desc: #function + " un sub scribe member error : \(error?.localizedDescription ?? "")")
        }
      }
    }
  }
}
