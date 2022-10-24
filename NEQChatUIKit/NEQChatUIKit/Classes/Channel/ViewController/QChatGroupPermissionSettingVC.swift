
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit

typealias channelUpdateSettingBlock = (_ channelRole: ChannelRole?) -> Void

public class QChatGroupPermissionSettingVC: QChatTableViewController,
  QChatPermissionSettingCellDelegate {
//    public var didUpdateBlock: channelUpdateSettingBlock?
  public var cRole: ChannelRole?
  private var commonAuths = [RoleStatusInfoExt]()
  private var messageAuths = [RoleStatusInfoExt]()
  private var memberAuths = [RoleStatusInfoExt]()
  private var auths = [[RoleStatusInfoExt]]()

  public init(cRole: ChannelRole?) {
    super.init(nibName: nil, bundle: nil)
    self.cRole = cRole
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    if let name = cRole?.name {
      title = name + localizable("authority_setting")
    } else {
      title = localizable("authority_setting")
    }
    tableView.register(
      QChatPermissionSettingCell.self,
      forCellReuseIdentifier: "\(QChatPermissionSettingCell.self)"
    )
    tableView.register(
      QChatSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)"
    )
    tableView.sectionHeaderHeight = 42
    tableView.rowHeight = 48
    reloadData()
  }

  private func reloadData() {
    if let auths = cRole?.auths {
      for auth in auths {
        var authExt = RoleStatusInfoExt(status: auth)
        let key = "auth" + String(auth.type.rawValue)
        authExt.title = localizable(key)
        switch auth.type {
        case .ManageChannel:
          commonAuths.insert(authExt, at: 0)
        case .ManageRole:
          commonAuths.append(authExt)
        case .SendMsg:
          messageAuths.append(authExt)
//                case .DeleteOtherMsg:
//                    messageAuths.append(authExt)
//                case .RevokeMsg:
//                    messageAuths.append(authExt)
        case .BlackWhiteList:
          memberAuths.append(authExt)
        default:
          break
        }
      }
      if !commonAuths.isEmpty {
        self.auths.append(commonAuths)
      }
      if !messageAuths.isEmpty {
        self.auths.append(messageAuths)
      }
      if !memberAuths.isEmpty {
        self.auths.append(memberAuths)
      }
      tableView.reloadData()
    }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    auths.count
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    auths[section].count
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatPermissionSettingCell.self)",
      for: indexPath
    ) as! QChatPermissionSettingCell
    let auths = auths[indexPath.section]
    let authExt = auths[indexPath.row]
    cell.updateModel(model: authExt)
    cell.delegate = self
    if indexPath.row == 0 {
      cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
    } else if indexPath.row == auths.count - 1 {
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
    }
    return cell
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(QChatSectionView.self)"
      ) as? QChatSectionView
    if section == 0 {
      view?.titleLable.text = localizable("qchat_common_permission")
    } else if section == 1 {
      view?.titleLable.text = localizable("qchat_message_permission")
    } else {
      view?.titleLable.text = localizable("qchat_member_permission")
    }
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    42
  }

  //    MARK: QChatPermissionSettingCellDelegate

  func didSelected(cell: QChatPermissionSettingCell?, model: RoleStatusInfo?) {
    if let auth = model {
      let param = UpdateChannelRoleParam(
        serverId: cRole?.serverId,
        channelId: cRole?.channelId,
        roleId: cRole?.roleId,
        commands: [auth]
      )
      QChatRoleProvider.shared
        .updateChannelRole(param: param) { [weak self] error, channelRole in
          if error != nil {
            self?.view.makeToast(error?.localizedDescription)
            cell?.selectedSuccess(success: false)
          } else {
            cell?.selectedSuccess(success: true)
//                    if let block = self?.didUpdateBlock {
//                        block(channelRole)
//                    }
          }
        }
    }
  }
}
