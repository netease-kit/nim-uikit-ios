
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseTeamMembersController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource, TeamMemberCellDelegate, TeamMembersViewModelDelegate {
  public var teamId: String?

  public var memberDatas: [TeamMemberInfoModel]? {
    didSet {
      viewmodel.setShowDatas(memberDatas)
    }
  }

  public var ownerId: String?

  public var isSenior = false

  public var searchDatas = [TeamMemberInfoModel]()

  public let back = UIView()

  let viewmodel = TeamMembersViewModel()

  public lazy var searchTextField: UITextField = {
    let field = UITextField()
    field.translatesAutoresizingMaskIntoConstraints = false
    field.placeholder = localizable("search_friend")
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

  public lazy var contentTable: UITableView = {
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
    table.keyboardDismissMode = .onDrag
    return table
  }()

  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("no_result"), frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  public init(teamId: String?) {
    super.init(nibName: nil, bundle: nil)
    self.teamId = teamId
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    addObserver()

    viewmodel.delegate = self
    let team = TeamProvider.shared.getTeam(teamId: teamId ?? "")
    ownerId = team?.owner
    if team?.isDisscuss() == false {
      isSenior = true
    }
    if let tid = team?.teamId {
      viewmodel.getMemberInfo(tid)
    }

    setupUI()

    TeamRepo.shared.fetchTeamInfo(teamId ?? "") { [weak self] error, teamModel in
      if error != nil {
        self?.emptyView.isHidden = false
      } else {
        self?.viewmodel.setShowDatas(teamModel?.users)
        self?.didNeedRefreshUI()
      }
    }
  }

  open func setupUI() {
    if isSenior {
      title = localizable("group_memmber")
    } else {
      title = localizable("discuss_mebmer")
    }

    back.backgroundColor = .clear
    back.translatesAutoresizingMaskIntoConstraints = false
    back.clipsToBounds = true
    back.layer.cornerRadius = 4.0

    view.addSubview(back)
    NSLayoutConstraint.activate([
      back.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0 + topConstant),
      back.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      back.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      back.heightAnchor.constraint(equalToConstant: 32),
    ])

    let searchIcon = UIImageView()
    searchIcon.image = coreLoader.loadImage("search_icon")
    searchIcon.translatesAutoresizingMaskIntoConstraints = false
    back.addSubview(searchIcon)
    NSLayoutConstraint.activate([
      searchIcon.centerYAnchor.constraint(equalTo: back.centerYAnchor),
      searchIcon.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 16.0),
    ])

    back.addSubview(searchTextField)
    NSLayoutConstraint.activate([
      searchTextField.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 36.0),
      searchTextField.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -16.0),
      searchTextField.topAnchor.constraint(equalTo: back.topAnchor),
      searchTextField.bottomAnchor.constraint(equalTo: back.bottomAnchor),
    ])

    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: back.bottomAnchor, constant: 10),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentTable.register(NEBaseTeamMemberCell.self, forCellReuseIdentifier: "\(NEBaseTeamMemberCell.self)")

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: contentTable.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: contentTable.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: contentTable.topAnchor, constant: 50),
      emptyView.bottomAnchor.constraint(equalTo: contentTable.bottomAnchor),
    ])
  }

  func addObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(self, selector: #selector(didNeedRefreshUI), name: NENotificationName.updateFriendInfo, object: nil)
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
    searchDatas.removeAll()
    if let text = searchTextField.text, text.count > 0 {
      viewmodel.datas.forEach { model in
        if let uid = model.nimUser?.userId, uid.contains(text) {
          searchDatas.append(model)
        } else if let nick = model.nimUser?.userInfo?.nickName, nick.contains(text) {
          searchDatas.append(model)
        } else if let alias = model.nimUser?.alias, alias.contains(text) {
          searchDatas.append(model)
        } else if let tNick = model.teamMember?.nickname, tNick.contains(text) {
          searchDatas.append(model)
        }
      }
      emptyView.isHidden = searchDatas.count > 0
    } else {
      emptyView.isHidden = true
    }
    didNeedRefreshUI()
  }

  func getRealModel(_ index: Int) -> TeamMemberInfoModel? {
    if let text = searchTextField.text, text.count > 0 {
      return searchDatas[index]
    }
    return viewmodel.datas[index]
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let text = searchTextField.text, text.count > 0 {
      return searchDatas.count
    }
    return viewmodel.datas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NEBaseTeamMemberCell.self)",
      for: indexPath
    ) as? NEBaseTeamMemberCell {
      if let model = getRealModel(indexPath.row) {
        cell.configure(model)
        cell.ownerLabel.isHidden = !isOwner(model.nimUser?.userId)
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
      if IMKitClient.instance.isMySelf(user.userId) {
        Router.shared.use(
          MeSettingRouter,
          parameters: ["nav": navigationController as Any],
          closure: nil
        )
      } else {
        if let uid = user.userId {
          Router.shared.use(
            ContactUserInfoPageRouter,
            parameters: ["nav": navigationController as Any, "uid": uid],
            closure: nil
          )
        }
      }
    }
  }

  func didClickRemoveButton(_ model: TeamMemberInfoModel?, _ index: Int) {
    print("did click remove button")
    weak var weakSelf = self

    // 注释掉的暂时留存，后续可能更改提示语 let content = String(format: localizable("confirm_delete_text"), model?.atNameInTeam() ?? "") + localizable("question_mark")

    showAlert(title: localizable("remove_manager_title"), message: localizable("remove_member_tip")) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.view.makeToast(commonLocalizable("network_error"))
        return
      }

      if let tid = weakSelf?.teamId, let uid = model?.nimUser?.userId {
        weakSelf?.viewmodel.removeTeamMember(tid, [uid]) { error in
          if let err = error {
            if err.code == noPermissionCode {
              weakSelf?.view.makeToast(localizable("no_permission_tip"))
            } else {
              weakSelf?.view.makeToast(localizable("remove_failed"))
            }
          } else {
            if let text = weakSelf?.searchTextField.text, text.count > 0 {
              weakSelf?.searchDatas.remove(at: index)
              weakSelf?.viewmodel.removeModel(model)
              weakSelf?.didNeedRefreshUI()
            } else {
              weakSelf?.viewmodel.removeModel(model)
              weakSelf?.didNeedRefreshUI()
            }
          }
        }
      }
    }
  }

  // 查找移除数据在 data 中的位置

  func didNeedRefreshUI() {
    contentTable.reloadData()
  }
}
