
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM
import MJRefresh

public class QChatChannelMembersVC: QChatTableViewController, QChatMemberInfoViewDelegate {
    
    public var channel: ChatChannel?
    private var channelMembers:[ServerMemeber]?
    var memberInfoView: QChatMemberInfoView?
    var  lastMember: ServerMemeber?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        commonUI()
        loadData()
    }
    func commonUI() {
        self.title = localizable("channel_member")
        let header = ChannelHeaderView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 78))
        header.settingButton.addTarget(self, action: #selector(enterChannelSetting), for: .touchUpInside)
        header.titleLabel.text = self.channel?.name
        header.detailLabel.text = self.channel?.topic
        tableView.tableHeaderView = header
        tableView.register(QChatImageTextOnlineCell.self, forCellReuseIdentifier: "\(QChatImageTextOnlineCell.self)")
        tableView.mj_footer = MJRefreshBackNormalFooter(refreshingTarget: self, refreshingAction: #selector(loadMoreData))
        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(loadData))
    }
    
    @objc func loadData() {
        var param = ChannelMembersParam(serverId: self.channel?.serverId ?? 0, channelId: self.channel?.channelId ?? 0)
        param.limit = 50
        QChatChannelProvider.shared.getChannelMembers(param: param) { [weak self] error, cMembersResult in
            print("cMembersResult.memberArray:\(cMembersResult?.memberArray) thread:\(Thread.current) ")
            self?.channelMembers = cMembersResult?.memberArray
            self?.lastMember = cMembersResult?.memberArray?.last
            self?.tableView.reloadData()
            self?.tableView.mj_footer?.resetNoMoreData()
            self?.tableView.mj_header?.endRefreshing()
        }
    }
    @objc func loadMoreData() {
        var param = ChannelMembersParam(serverId: self.channel?.serverId ?? 0, channelId: self.channel?.channelId ?? 0)
        param.timeTag = self.lastMember?.createTime
        param.limit = 50
        QChatChannelProvider.shared.getChannelMembers(param: param) { [weak self] error, cMembersResult in
            print("more cMembersResult.memberArray:\(cMembersResult?.memberArray) thread:\(Thread.current) ")
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
                return
            }
            if let members = cMembersResult?.memberArray, members.count > 0 {
                for m in members {
                    self?.channelMembers?.append(m)
                }
                self?.lastMember = members.last
                self?.tableView.reloadData()
            }else {
//                end
                self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
            }
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channelMembers?.count ?? 0
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatImageTextOnlineCell.self)", for: indexPath) as! QChatImageTextOnlineCell
        let member = self.channelMembers![indexPath.row] as ServerMemeber
        cell.setup(accid: member.accid, nickName: member.nick)
        cell.online = false
        if self.channelMembers?.count == 1 {
            cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
        }else {
            if indexPath.row == 0 {
                cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
            }else if indexPath.row == self.channelMembers!.count - 1 {
                cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let m = self.channelMembers![indexPath.row]
        memberInfoView = QChatMemberInfoView(inView: UIApplication.shared.keyWindow!)
        memberInfoView?.setup(accid: m.accid, nickName: m.nick)
        memberInfoView?.delegate = self
        self.memberInfoView?.present()
        self.loadRolesOfMember(member: m)
        
    }
    
    func loadRolesOfMember(member: ServerMemeber) {
        let param = GetServerRolesByAccIdParam(serverId: self.channel?.serverId, accid: member.accid)
        QChatRoleProvider.shared.getServerRolesByAccId(param: param) {[weak self] error , roles in
            print("roles:\(roles?.count) error: \(error)")
            guard let roleList = roles else {
                return
            }
            var names = [String]()
            
            for r in roleList {
                names.append(r.name ?? "")
            }
            self?.memberInfoView?.setupRoles(dataArray: names)
        
        }
    }
    
    @objc func enterChannelSetting() {
        let settingVC = QChatChannelSettingVC()
        settingVC.didUpdateChannel = { [weak self] channel in
            self?.channel = channel
            guard let head =  self?.tableView.tableHeaderView as? ChannelHeaderView else {
                return
            }
            head.titleLabel.text = channel?.name
            head.detailLabel.text = channel?.topic
        }
        
        settingVC.didDeleteChannel = { [weak self] channel in
            self?.navigationController?.popViewController(animated: true)
        }

        settingVC.viewModel = QChatUpdateChannelViewModel(channel: self.channel)
        let nav = UINavigationController(rootViewController: settingVC)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    func didClickUserHeader(_ accid: String?) {
        if let uid = accid {
            if CoreKitIMEngine.instance.isMySelf(uid){
                Router.shared.use(MeSetting, parameters: ["nav": navigationController as Any], closure: nil)
            }else {
                Router.shared.use(ContactUserInfoPageRouter, parameters: ["nav": navigationController as Any, "uid": uid as Any], closure: nil)
            }
        }
        
    }
    
}
