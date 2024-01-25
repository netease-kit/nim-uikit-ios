
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import UIKit

public typealias DidSelectedAtRow = (_ index: Int, _ model: ChatTeamMemberInfoModel?) -> Void

@objcMembers
open class NEBaseSelectUserViewController: ChatBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public var tableView = UITableView(frame: .zero, style: .plain)
  public var sessionId: String
  public var viewModel = TeamMemberSelectVM()
  public var selectedBlock: DidSelectedAtRow?
  var teamInfo: ChatTeamInfoModel?
  private var showSelf = true // 是否展示自己
  var className = "SelectUserViewController"
  var isShowAtAll = true

  init(sessionId: String, showSelf: Bool = true) {
    self.sessionId = sessionId
    self.showSelf = showSelf
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
    commonUI()
    loadData()
  }

  func commonUI() {
    let btn = UIButton(type: .custom)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.accessibilityIdentifier = "id.arrowDown"
    btn.setImage(UIImage.ne_imageNamed(name: "arrowDown"), for: .normal)
    btn.addTarget(self, action: #selector(btnEvent), for: .touchUpInside)
    view.addSubview(btn)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        btn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
        btn.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        btn.widthAnchor.constraint(equalToConstant: 50),
        btn.heightAnchor.constraint(equalToConstant: 50),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        btn.topAnchor.constraint(equalTo: view.topAnchor),
        btn.widthAnchor.constraint(equalToConstant: 50),
        btn.heightAnchor.constraint(equalToConstant: 50),
      ])
    }

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("user_select")
    label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    label.textAlignment = .center
    label.textColor = .ne_darkText
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      label.topAnchor.constraint(equalTo: view.topAnchor),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: 50),
    ])

    tableView.delegate = self
    tableView.dataSource = self
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.tableFooterView = UIView()
    view.addSubview(tableView)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        tableView.topAnchor.constraint(equalTo: label.bottomAnchor),
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        tableView.bottomAnchor
          .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        tableView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }
  }

  func loadData() {
    viewModel.fetchTeamMembers(sessionId: sessionId) { [weak self] error, team in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "SelectUserViewController"),
        desc: "CALLBACK fetchTeamMembers " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
        return
      }

      // 人员选择页面移除自己
      var selfIndex = -1
      if !(self?.showSelf ?? true),
         let users = team?.users {
        for (index, user) in users.enumerated() {
          if let u = team?.users[index].nimUser {
            ChatUserCache.updateUserInfo(u)
          }
          if user.nimUser?.userId == IMKitLoginManager.instance.currentAccount() {
            if user.teamMember?.type != .manager, let custom = team?.team?.clientCustomInfo, custom.count > 0, let json = getDictionaryFromJSONString(custom), let atValue = json[keyAllowAtAll] as? String, atValue == allowAtManagerValue {
              self?.isShowAtAll = false
            }
            selfIndex = index
          }
        }
        team?.users.remove(at: selfIndex)
      }

      // 根据身份+进群时间正序排序
      if let users = team?.users {
        var owner: ChatTeamMemberInfoModel? // 群主
        var managers = [ChatTeamMemberInfoModel]() // 管理员
        var normals = [ChatTeamMemberInfoModel]() // 普通成员

        for user in users {
          if user.teamMember?.type == .owner {
            owner = user
          } else if user.teamMember?.type == .manager {
            managers.append(user)
          } else {
            normals.append(user)
          }
        }

        managers.sort(by: { m1, m2 in
          (m1.teamMember?.createTime ?? 0) < (m2.teamMember?.createTime ?? 0)
        })

        normals.sort(by: { m1, m2 in
          (m1.teamMember?.createTime ?? 0) < (m2.teamMember?.createTime ?? 0)
        })

        if let owner = owner {
          team?.users = [owner] + managers + normals
        } else {
          team?.users = managers + normals
        }
      }

      self?.teamInfo = team
      self?.tableView.reloadData()
    }
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return isShowAtAll ? 1 : 0
    }
    if let count = teamInfo?.users.count {
      return count
    }
    return 0
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      if let block = selectedBlock {
        block(indexPath.row, nil)
      }
      dismiss(animated: true, completion: nil)
      return
    }
    if let block = selectedBlock {
      block(indexPath.row, teamInfo?.users[indexPath.row])
    }
    dismiss(animated: true, completion: nil)
  }

  func btnEvent(button: UIButton) {
    dismiss(animated: true, completion: nil)
  }
}
