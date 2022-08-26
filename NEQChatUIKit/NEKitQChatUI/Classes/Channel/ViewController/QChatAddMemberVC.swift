
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import CoreAudio
import MJRefresh

typealias AddMemberRoleBlock = (_ memberRole: MemberRole?) -> Void
public class QChatAddMemberVC: QChatSearchVC {
  public var channel: ChatChannel?
  private var serverMembers: [ServerMemeber]?
  private var channelMembers: [ServerMemeber]?
  private var lastTimeTag: Double?
//    public var didAddMemberRole: AddMemberRoleBlock?

  public init(channel: ChatChannel?) {
    super.init(nibName: nil, bundle: nil)
    self.channel = channel
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("add_member")
    tableView.register(
      QChatImageTextCell.self,
      forCellReuseIdentifier: "\(QChatImageTextCell.self)"
    )
    tableView.rowHeight = 60
    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadData)
    )
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMore)
    )
    loadData()
  }

  @objc func loadData() {
    lastTimeTag = 0
    var param = GetServerMembersByPageParam()
    param.serverId = channel?.serverId
    param.limit = 50
    param.timeTag = lastTimeTag
    QChatServerProvider.shared.getServerMembers(param) { [weak self] error, sMembers in
      print("sMembers:\(sMembers) error:\(error)")
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
        self?.emptyView.isHidden = false

      } else {
        if !sMembers.isEmpty {
          self?.lastTimeTag = sMembers.last?.createTime
//                    var filteredMemberArray = sMembers
          if let sid = self?.channel?.serverId, let cid = self?.channel?.channelId {
            // 过滤掉已经存在在channel中的成员
            var ids = [String]()
            for member in sMembers {
              if let id = member.accid {
                ids.append(id)
              }
            }
            let param = GetExistingAccidsOfMemberRolesParam(
              serverId: sid,
              channelId: cid,
              accids: ids
            )
            QChatRoleProvider.shared
              .getExistingMemberRoles(param: param) { error, existMemberArray in
                var filterMembers = [ServerMemeber]()
                if let existMembers = existMemberArray, !existMembers.isEmpty {
                  for m in sMembers {
                    if existMembers.contains(where: { existMember in
                      m.accid == existMember.accid
                    }) {
                    } else {
                      filterMembers.append(m)
                    }
                  }
                  self?.serverMembers = filterMembers
                  self?.emptyView.isHidden = !filterMembers.isEmpty

                } else {
                  self?.serverMembers = sMembers
                  self?.emptyView.isHidden = !sMembers.isEmpty
                }
                self?.tableView.mj_footer?.resetNoMoreData()
                self?.tableView.mj_header?.endRefreshing()
                self?.tableView.reloadData()
              }
          } else {
            self?.emptyView.isHidden = !sMembers.isEmpty
            self?.serverMembers = sMembers
            self?.tableView.mj_footer?.resetNoMoreData()
            self?.tableView.mj_header?.endRefreshing()
            self?.tableView.reloadData()
          }
        } else {
          // 空白页
          self?.emptyView.isHidden = false
        }
      }
    }
  }

  @objc func loadMore() {
    var param = GetServerMembersByPageParam()
    param.serverId = channel?.serverId
    param.limit = 50
    param.timeTag = lastTimeTag
    QChatServerProvider.shared.getServerMembers(param) { [weak self] error, sMembers in
      print("sMembers:\(sMembers) error:\(error)")
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
      } else {
        if !sMembers.isEmpty {
          self?.lastTimeTag = sMembers.last?.createTime
          if let sid = self?.channel?.serverId, let cid = self?.channel?.channelId {
            // 过滤掉已经存在在channel中的成员
            var ids = [String]()
            for member in sMembers {
              if let id = member.accid {
                ids.append(id)
              }
            }
            let param = GetExistingAccidsOfMemberRolesParam(
              serverId: sid,
              channelId: cid,
              accids: ids
            )
            QChatRoleProvider.shared
              .getExistingMemberRoles(param: param) { error, existMemberArray in
                if let existMembers = existMemberArray, !existMembers.isEmpty {
                  for m in sMembers {
                    if existMembers.contains(where: { existMember in
                      m.accid == existMember.accid
                    }) {
                    } else {
                      self?.serverMembers?.append(m)
                    }
                  }
                }
                self?.emptyView.removeFromSuperview()
                self?.tableView.mj_footer?.endRefreshing()
                self?.tableView.reloadData()
              }
          } else {
            for m in sMembers {
              self?.serverMembers?.append(m)
            }
            self?.emptyView.isHidden = true
            self?.tableView.mj_footer?.endRefreshing()
            self?.tableView.reloadData()
          }
        } else {
          self?.emptyView.isHidden = true
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        }
      }
    }
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    serverMembers?.count ?? 0
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatImageTextCell.self)",
      for: indexPath
    ) as! QChatImageTextCell
    cell.backgroundColor = .white
    cell.rightStyle = .indicate
    let member = serverMembers?[indexPath.row]
    cell.setup(accid: member?.accid, nickName: member?.nick)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // 成员权限设置
    let member = serverMembers?[indexPath.row]
    addMemberInChannel(member: member, index: indexPath.row)
  }

  private func addMemberInChannel(member: ServerMemeber?, index: Int) {
    let param = AddMemberRoleParam(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      accid: member?.accid
    )
    QChatRoleProvider.shared.addMemberRole(param) { error, memberRole in
      if error != nil {
        self.showToast(error?.localizedDescription ?? "")
      } else {
        self.serverMembers?.remove(at: index)
        self.tableView.reloadData()
        let settingVC = QChatMemberPermissionSettingVC(
          channel: self.channel,
          memberRole: memberRole
        )
        self.navigationController?.pushViewController(settingVC, animated: true)
//                if let block = self.didAddMemberRole {
//                    block(memberRole)
//                }
      }
    }
  }

  private lazy var emptyView: EmptyDataView = {
    let view = EmptyDataView(
      imageName: "memberPlaceholder",
      content: "无成员可添加",
      frame: CGRect(
        x: 0,
        y: 60,
        width: self.view.bounds.size.width,
        height: self.view.bounds.size.height
      )
    )
    self.view.addSubview(view)
    return view
  }()
}
