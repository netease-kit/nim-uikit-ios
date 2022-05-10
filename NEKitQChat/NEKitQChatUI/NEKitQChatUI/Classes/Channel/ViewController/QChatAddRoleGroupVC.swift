
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM
import MJRefresh

typealias AddChannelRoleBlock = (_ role: ChannelRole?) -> Void
class QChatAddRoleGroupVC: QChatSearchVC {
    public var channel: ChatChannel?
    private var serverRoles:[ServerRole]?
    private var channelRoles:[ChannelRole]?
//    public var didAddChannelRole: AddChannelRoleBlock?
    private var priority: Int?
    private lazy var placeholderView: EmptyDataView = EmptyDataView(imageName: "rolePlaceholder", content: localizable("has_no_role"), frame: CGRect(x: 0, y: 60, width: self.view.bounds.size.width, height: self.view.bounds.size.height))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = localizable("add_group")
        self.tableView.register(QChatTextArrowCell.self, forCellReuseIdentifier: "\(QChatTextArrowCell.self)")
        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(loadData))
        tableView.mj_footer = MJRefreshBackNormalFooter(refreshingTarget: self, refreshingAction: #selector(loadMore))
        self.view.addSubview(self.placeholderView)
        loadData()
    }
    
    init(channel:ChatChannel?) {
        super.init(nibName: nil, bundle: nil)
        self.channel = channel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func loadData() {
        self.priority = 0
        //加载server的身份组
        var param = GetServerRoleParam()
        param.serverId = self.channel?.serverId
        param.limit = 50
        param.priority = self.priority
        print("thread:\(Thread.current)")
        QChatRoleProvider.shared.getRoles(param) {[weak self] error, roles, sets in
            print("sRoles:\(roles) error:\(error)")
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
                // 空白页
                self?.placeholderView.isHidden = false
            }else {
                if let roleArray = roles, !roleArray.isEmpty {
                    self?.priority = roleArray.last?.priority
                    if let sid = self?.channel?.serverId, let cid = self?.channel?.channelId {
                        // 过滤掉已经存在在channel中的身份组
                        var ids = [UInt64]()
                        for role in roleArray {
                            if let id = role.roleId {
                                ids.append(id)
                            }
                        }
                        let param = GetExistingChannelRolesByServerRoleIdsParam(serverId: sid, channelId: cid, roleIds: ids)
                        QChatRoleProvider.shared.getExistingChannelRoles(param: param) {error, channelRoles in
                            if let existRoles = channelRoles, !existRoles.isEmpty {
                                var tmp = [ServerRole]()
                                print("roleArray: \(roleArray)")
                                for role in roleArray {
                                    if existRoles.contains(where: { existRole in
                                        return role.roleId == existRole.parentRoleId
                                    }) {
                                        
                                    }else {
                                        tmp.append(role)
                                        
                                    }
                                }
                                self?.serverRoles = tmp
                                self?.placeholderView.isHidden = !tmp.isEmpty
                                
                            }else {
                                self?.serverRoles = roleArray
                                self?.placeholderView.isHidden = !roleArray.isEmpty
                            }
                            self?.tableView.mj_footer?.resetNoMoreData()
                            self?.tableView.mj_header?.endRefreshing()
                            self?.tableView.reloadData()
                        }
                    }else {
                        self?.serverRoles = roleArray
                        self?.tableView.mj_footer?.resetNoMoreData()
                        self?.tableView.mj_header?.endRefreshing()
                        self?.tableView.reloadData()
                    }
                }else {
                    // 空白页
                    self?.placeholderView.isHidden = false
                }
            }
        }
    }
    
    @objc func loadMore() {
        //加载server的身份组
        var param = GetServerRoleParam()
        param.serverId = self.channel?.serverId
        param.limit = 50
        param.priority = self.priority
        QChatRoleProvider.shared.getRoles(param) {[weak self] error, roles, sets in
            print("sRoles:\(roles) error:\(error)")
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
            }else {
                if let roleArray = roles, !roleArray.isEmpty {
                    self?.priority = roleArray.last?.priority
                    if let sid = self?.channel?.serverId, let cid = self?.channel?.channelId {
                        // 过滤掉已经存在在channel中的身份组
                        var ids = [UInt64]()
                        for role in roleArray {
                            if let id = role.roleId {
                                ids.append(id)
                            }
                        }
                        let param = GetExistingChannelRolesByServerRoleIdsParam(serverId: sid, channelId: cid, roleIds: ids)
                        QChatRoleProvider.shared.getExistingChannelRoles(param: param) {error, channelRoles in
                            if let existRoles = channelRoles, !existRoles.isEmpty {
                                for role in roleArray {
                                    if existRoles.contains(where: { existRole in
                                        return role.roleId == existRole.parentRoleId
                                    }) {
                                        
                                    }else {
                                        self?.serverRoles?.append(role)
                                    }
                                }
                            }else {
                                for role in roleArray {
                                    self?.serverRoles?.append(role)
                                }
                            }

                            self?.placeholderView.isHidden = true
                            self?.tableView.mj_footer?.endRefreshing()
                            self?.tableView.reloadData()
                        }
                    }else {
                        for role in roleArray {
                            self?.serverRoles?.append(role)
                        }
                        self?.placeholderView.isHidden = true
                        self?.tableView.mj_footer?.endRefreshing()
                        self?.tableView.reloadData()
                    }
                    
                }else {
                    self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.serverRoles?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextArrowCell.self)", for: indexPath) as! QChatTextArrowCell
        cell.backgroundColor = .white
        cell.titleLabel.text = self.serverRoles?[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let role = self.serverRoles?[indexPath.row]
        guard let sId = self.channel?.serverId, let cId = self.channel?.channelId, let roleId = role?.roleId  else {
            return
        }
        //1.添加到频道下
        let param = AddChannelRoleParam(serverId: sId, channelId: cId, parentRoleId: roleId)
        QChatRoleProvider.shared.addChannelRole(param: param) { [weak self] error, cRole in
            if error == nil {
                //2.跳转到身份组权限设置
                self?.navigationController?.pushViewController(QChatGroupPermissionSettingVC(cRole: cRole), animated: true)
                //3.此页面移除该数据并刷新
                self?.serverRoles?.remove(at: indexPath.row)
                if self?.serverRoles?.count ?? 0 > 0 {
                    self?.placeholderView.isHidden = true
                    self?.tableView.reloadData()
                }else {
                    self?.placeholderView.isHidden = false
                }
//                if let block = self?.didAddChannelRole {
//                    block(cRole)
//                }
            }else {
                self?.view.makeToast(error?.localizedDescription)
            }
        }
    }
}
