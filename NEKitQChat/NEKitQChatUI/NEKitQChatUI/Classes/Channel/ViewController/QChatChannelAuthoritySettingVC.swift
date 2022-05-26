
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM

public class QChatChannelAuthoritySettingVC: QChatTableViewController {
    var channel: ChatChannel?
    var viewModel: QChatAuthoritySettingViewModel?
    var sectionTitle: [String] = ["",localizable("qchat_id_group"),localizable("qchat_member")]
    var staticData: [String] = [localizable("add_group"),localizable("add_member")]
    var memberData: [String] = [localizable("add_member"),localizable("add_group")]
    var isEdit = false

    init(channel: ChatChannel?) {
        super.init(nibName: nil, bundle: nil)
        self.channel = channel
        self.viewModel = QChatAuthoritySettingViewModel(channel: self.channel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
         print("viewWillAppear")
        loadData()
    }
    

    
    public override func viewDidLoad() {
        super.viewDidLoad()
        commonUI()
    }
    
    func commonUI() {
        self.title = localizable("authority_setting")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: localizable("qchat_edit"), style: .plain, target: self, action: #selector(edit))
        self.tableView.rowHeight = 50
        self.tableView.register(QChatTextArrowCell.self, forCellReuseIdentifier: "\(QChatTextArrowCell.self)")
        self.tableView.register(QChatImageTextCell.self, forCellReuseIdentifier: "\(QChatImageTextCell.self)")
        self.tableView.register(QChatCenterTextCell.self, forCellReuseIdentifier: "\(QChatCenterTextCell.self)")
        self.tableView.register(QChatSectionView.self, forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)")
    }
    
    func loadData() {
        //获取频道下的身份组
        viewModel?.firstGetChannelRoles({[weak self] error, roles in
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
            }else {
                self?.tableView.reloadData()
            }
        })
        
        //获取频道下的成员
        viewModel?.firstGetMembers({[weak self] error, members in
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
            }else {
                self?.tableView.reloadData()
            }
        })
    }

    // MARK: - event
    @objc func edit() {
        self.isEdit = !self.isEdit
        let title = self.isEdit ? localizable("finish") : localizable("qchat_edit")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(edit))
        self.tableView.reloadData()
    }
    
    // MARK: - delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return staticData.count
        case 1:
            return viewModel?.rolesData.roles.count ?? 0
        case 2:
            return viewModel?.membersData.roles.count ?? 0
        default:
            return 0
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextArrowCell.self)", for: indexPath) as! QChatTextArrowCell
            if indexPath.row == 0 {
                cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
            }else {
                cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
            }
            cell.titleLabel.text = staticData[indexPath.row]
            cell.rightStyle = .indicate
            return cell
        case 1:
            let role = viewModel?.rolesData.roles[indexPath.row]
            if (role!.isPlacehold) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatCenterTextCell.self)", for: indexPath) as! QChatCenterTextCell
                cell.titleLabel.text = role?.title
                cell.titleLabel.textColor = .ne_greyText
                cell.titleLabel.font = .systemFont(ofSize: 14)
                switch role?.corner {
                case .top:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
                case .bottom:
                    cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
                case .all:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
                default:
                    cell.cornerType = .none
                }
                return cell
            }else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextArrowCell.self)", for: indexPath) as! QChatTextArrowCell
                cell.titleLabel.text = role?.role?.name
                if role?.role?.type == .everyone {
                    cell.rightStyle = .none
                }else {
                    cell.rightStyle = self.isEdit ? .delete : .none
                }
                switch role?.corner {
                case .top:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
                case .bottom:
                    cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
                case .all:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
                default:
                    cell.cornerType = .none
                }
                return cell
            }

        case 2:
            let role = viewModel?.membersData.roles[indexPath.row]
            if (role!.isPlacehold) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatCenterTextCell.self)", for: indexPath) as! QChatCenterTextCell
                cell.titleLabel.textColor = .ne_greyText
                cell.titleLabel.font = .systemFont(ofSize: 14)
                cell.titleLabel.text = role?.title
                switch role?.corner {
                case .top:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
                case .bottom:
                    cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
                case .all:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
                default:
                    cell.cornerType = .none
                }
                return cell
            }else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatImageTextCell.self)", for: indexPath) as! QChatImageTextCell
                cell.rightStyle = self.isEdit ? .delete : .none
                let member = viewModel?.membersData.roles[indexPath.row].member
                cell.setup(accid: member?.accid, nickName: member?.nick)
                switch role?.corner {
                case .top:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
                case .bottom:
                    cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
                case .all:
                    cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
                default:
                    cell.cornerType = .none
                }
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "\(QChatSectionView.self)") as! QChatSectionView
        head.titleLable.text = sectionTitle[section]
        if section == 2, self.viewModel?.membersData.roles.count == 0 {
            head.titleLable.text = ""
        }
        return head
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                // add group
                let addRoleVC = QChatAddRoleGroupVC(channel: viewModel?.channel)
                self.navigationController?.pushViewController(addRoleVC, animated: true)
                
            }else {
                // add member
                let addMemberVC = QChatAddMemberVC(channel: viewModel?.channel)
                self.navigationController?.pushViewController(addMemberVC, animated: true)
            }
            
        case 1:
//            group
            guard let model = viewModel?.rolesData.roles[indexPath.row] else {
                return
            }
            if model.isPlacehold {
                //加载更多
                viewModel?.getChannelRoles({[weak self] error, roles in
                    if error != nil {
                        self?.view.makeToast(error?.localizedDescription)
                    }else {
                        self?.tableView.reloadData()
                    }
                })
            }else {
                if self.isEdit {
                    //delete role
                    deleteRole(role: model.role, index: indexPath.row)
                }else {
                    // enter authority setting
                    let settingVC = QChatGroupPermissionSettingVC(cRole: model.role)
                    self.navigationController?.pushViewController(settingVC, animated: true)
                }
            }

        case 2:
//            member
            guard let model = viewModel?.membersData.roles[indexPath.row] else {
                return
            }
            if model.isPlacehold {
                //加载更多
                viewModel?.getMembers({[weak self] error, members in
                    if error != nil {
                        self?.view.makeToast(error?.localizedDescription)
                    }else {
                        self?.tableView.reloadData()
                    }
                })
            }else {
                if self.isEdit {
                    //delete member
                    deleteMember(member: model.member, index: indexPath.row)
                }else {
                    // enter member authority setting
                    let settingVC = QChatMemberPermissionSettingVC(channel: self.channel, memberRole: model.member)
                    self.navigationController?.pushViewController(settingVC, animated: true)
                }
            }
        default:
            break
        }
    }
    
    private func deleteRole(role: ChannelRole?, index: Int) {
        let name = role?.name ?? ""
        let message = localizable("confirm_delete_channel") + name + localizable("qchat_id_group") + "?"
        let alertVC = UIAlertController.reconfimAlertView(title: localizable("removeRole"), message: message) {
            self.viewModel?.removeChannelRole(role: role, index: index, { [weak self] error in
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }else {
                    self?.tableView.reloadData()
                }
            })
            
        }
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func deleteMember(member: MemberRole?, index: Int) {
        var name = member?.accid ?? ""
        if let n = member?.nick, n.count > 0 {
            name = n
        }
        let message = localizable("confirm_delete_channel") + name + localizable("qchat_member") + "?"
        let alertVC = UIAlertController.reconfimAlertView(title: localizable("removeMember"), message: message) {
            self.viewModel?.removeMemberRole(member: member, index: index, { [weak self] error in
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }else {
                    self?.tableView.reloadData()
                }
            })
        }
        self.present(alertVC, animated: true, completion: nil)
    }
}
