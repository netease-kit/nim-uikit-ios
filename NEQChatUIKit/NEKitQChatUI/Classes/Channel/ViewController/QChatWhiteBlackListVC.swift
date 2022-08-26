
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCore

public class QChatWhiteBlackListVC: QChatTableViewController, QChatMemberSelectControllerDelegate {
  public var type: RoleType = .white
  public var channel: ChatChannel?
  private var memberArray: [ServerMemeber]?
  private var isEdited: Bool = false

  override public func viewDidLoad() {
    super.viewDidLoad()
    isEdited = false
    title = type == .white ? localizable("white_list") : localizable("black_list")
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: localizable("qchat_edit"),
      style: .plain,
      target: self,
      action: #selector(edit)
    )

    tableView.backgroundColor = .white
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.register(QChatTextCell.self, forCellReuseIdentifier: "\(QChatTextCell.self)")
    tableView.register(
      QChatImageTextCell.self,
      forCellReuseIdentifier: "\(QChatImageTextCell.self)"
    )
    loadData()
  }

  func loadData() {
    let type: ChannelMemberRoleType = type == .white ? .white : .black
    let param = GetChannelBlackWhiteMembers(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      timeTag: 0,
      limit: 50,
      type: type
    )
    QChatChannelProvider.shared
      .getBlackWhiteMembersByPage(param: param) { [weak self] error, result in
        self?.memberArray = result?.memberArray
        self?.tableView.reloadData()
      }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else {
      return memberArray?.count ?? 0
    }
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextCell.self)",
        for: indexPath
      ) as! QChatTextCell
      cell.backgroundColor = .white
      cell.rightStyle = .indicate
      cell.titleLabel.text = localizable("qchat_add_member")
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatImageTextCell.self)",
        for: indexPath
      ) as! QChatImageTextCell
      cell.backgroundColor = .white
      let member = memberArray?[indexPath.row]
      cell.setup(accid: member?.accid, nickName: member?.nick)
      cell.rightStyle = isEdited ? .delete : .none
//            if CoreKitEngine.instance.imAccid == member?.accid, self.type == .white {
//                cell.rightStyle = .none
//            }
      if IMKitLoginManager.instance.imAccid == member?.accid, type == .white {
        cell.rightStyle = .none
      }
      return cell
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      // present add memeber VC
      let memberSelect = QChatMemberSelectController()
      memberSelect.serverId = channel?.serverId
//            memberSelect.selectType = .ServerMember
      memberSelect.delegate = self
      memberSelect.completion = { [weak self] datas in
        // 选中成员
        print("选中成员：datas:\(datas)")
        if datas.count > 0 {
          var seletedMembers = [ServerMemeber]()
          for data in datas {
            if let m = data.serverMember {
              seletedMembers.append(m)
            }
          }
          self?
            .addMemberList(members: seletedMembers, type: self?.type ?? .white) { error in
              if error != nil {
                self?.view.makeToast(error?.localizedDescription)
              } else {
                for m in seletedMembers {
                  self?.memberArray?.append(m)
                }
                self?.tableView.reloadData()
              }
            }
        }
      }
      navigationController?.pushViewController(memberSelect, animated: true)
    } else {
      if isEdited {
        guard let member = memberArray?[indexPath.row] else {
          return
        }

//                if CoreKitEngine.instance.imAccid == member.accid, self.type == .white {
//                    return
//                }

        if IMKitLoginManager.instance.imAccid == member.accid, type == .white {
          return
        }

        let name = (member.nick != nil ? member.nick : member.accid) ?? ""
        let message = localizable("confirm_delete_channel") + name +
          localizable("qchat_member") + "?"
        let alertVC = UIAlertController.reconfimAlertView(
          title: localizable("removeMember"),
          message: message
        ) {
          let members = [member]
          self.removeMemberList(members: members, type: self.type) { [weak self] error in
            if error != nil {
              self?.view.makeToast(error?.localizedDescription)
            } else {
              if var members = self?.memberArray {
                var index = -1
                for (i, m) in members.enumerated() {
                  if m.accid == member.accid {
                    index = i
                    break
                  }
                }
                if index >= 0 {
                  members.remove(at: index)
                  self?.memberArray = members
                  self?.tableView.reloadData()
                }
              }
            }
          }
        }
        present(alertVC, animated: true, completion: nil)
      }
    }
  }

  // 添加黑白名单
  private func addMemberList(members: [ServerMemeber]?, type: RoleType,
                             _ completion: @escaping (NSError?) -> Void) {
    guard let ms = members else {
      return
    }
    var accids = [String]()
    for m in ms {
      accids.append(m.accid ?? "")
    }
    let param = UpdateChannelBlackWhiteMembersParam(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      type: type == .white ? .white : .black,
      opeType: .add,
      accids: accids
    )
    QChatChannelProvider.shared.updateBlackWhiteMembers(param: param, completion)
  }

  // 移除黑白名单
  private func removeMemberList(members: [ServerMemeber]?, type: RoleType,
                                _ completion: @escaping (NSError?) -> Void) {
    guard let ms = members else {
      return
    }
    var accids = [String]()
    for m in ms {
      if let id = m.accid {
        accids.append(id)
      }
    }
    let param = UpdateChannelBlackWhiteMembersParam(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      type: type == .white ? .white : .black,
      opeType: .remove,
      accids: accids
    )
    QChatChannelProvider.shared.updateBlackWhiteMembers(param: param, completion)
  }

  // MARK: - event

  @objc func edit() {
    isEdited = !isEdited
    if isEdited {
      navigationItem.rightBarButtonItem?.title = localizable("qchat_save")
      // TODO: reload data
    } else {
      navigationItem.rightBarButtonItem?.title = localizable("qchat_edit")
      // TODO: reload data
    }
    tableView.reloadData()
  }

  public func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
    let type: ChannelMemberRoleType = type == .white ? .white : .black
    let param = GetExistingChannelBlackWhiteMembersParam(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      type: type,
      accIds: accid
    )
    QChatChannelProvider.shared
      .getExistingChannelBlackWhiteMembers(param: param) { error, result in
        if let members = result?.memberArray, !members.isEmpty {
          var accidArray = [String]()
          for member in members {
            if let id = member.accid {
              accidArray.append(id)
            }
          }
          filterMembers(accidArray)
        } else {
          filterMembers(nil)
        }
      }
  }
}
