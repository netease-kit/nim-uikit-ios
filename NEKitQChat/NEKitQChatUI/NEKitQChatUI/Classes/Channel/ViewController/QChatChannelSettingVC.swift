
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM

typealias updateChannelSuccess = (_ channel: ChatChannel?) -> Void

public class QChatChannelSettingVC: QChatTableViewController, QChatTextEditCellDelegate {
    var viewModel: QChatUpdateChannelViewModel?
    var didUpdateChannel: updateChannelSuccess?
    var didDeleteChannel: updateChannelSuccess?
    
    var sections: [String]?
    var cells = [String]()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        commonUI()
    }

    func loadData() {
        sections = [localizable("channel_name"),localizable("channel_topic"),localizable("authority"),localizable("list"),""]
    
        let listName = viewModel?.channel?.visibleType == .isPublic ? localizable("black_list") : localizable("white_list")
        
        cells = [viewModel?.channel?.name ?? "",viewModel?.channel?.topic ?? "",localizable("authority_setting"),listName, localizable("delete_channel")]
    }
    
    func commonUI() {
        self.title = localizable("channel_setting")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: localizable("save"), style: .plain, target: self, action: #selector(save))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: localizable("close"), style: .plain, target: self, action: #selector(close))
        self.navigationItem.rightBarButtonItem?.tintColor = .ne_blueText
        self.tableView.rowHeight = 50
        self.tableView.register(QChatTextEditCell.self, forCellReuseIdentifier: "\(QChatTextEditCell.self)")
        self.tableView.register(QChatTextArrowCell.self, forCellReuseIdentifier: "\(QChatTextArrowCell.self)")
        self.tableView.register(QChatCenterTextCell.self, forCellReuseIdentifier: "\(QChatCenterTextCell.self)")
        self.tableView.register(QChatSectionView.self, forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)")
        
    }
//    MARK: deletgate
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextEditCell.self)", for: indexPath) as! QChatTextEditCell
            cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
            cell.textFied.text = cells[indexPath.section]
            cell.textFied.tag = 20
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextEditCell.self)", for: indexPath) as! QChatTextEditCell
            cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
            cell.textFied.text = cells[indexPath.section]
            cell.textFied.tag = 21
            cell.delegate = self
            return cell
        case 2,3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextArrowCell.self)", for: indexPath) as! QChatTextArrowCell
            cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
            cell.titleLabel.text = cells[indexPath.section]
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(QChatCenterTextCell.self)", for: indexPath) as! QChatCenterTextCell
            cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
            cell.titleLabel.text = cells[indexPath.section]
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "\(QChatSectionView.self)") as! QChatSectionView
        head.titleLable.text = sections?[section]
        return head
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 2:
            // authority
            enterAuthoritySettingVC()
        case 3:
            // name list
            enterListVC()
        case 4:
//            delete
            deleteChannel()
        default:
            break
        }
    }
    
//    MARK: private method
    private func enterAuthoritySettingVC() {
        self.navigationController?.pushViewController(QChatChannelAuthoritySettingVC(channel: viewModel?.channel), animated: true)
    }
    
    private func enterListVC() {
        let listVC = QChatWhiteBlackListVC()
        listVC.channel = self.viewModel?.channel
        listVC.type = viewModel?.channel?.visibleType == .isPublic ? .black : .white
        self.navigationController?.pushViewController(listVC, animated: true)
    }
    
    private func deleteChannel() {
        let message: String?
        if let name = viewModel?.channel?.name {
            message = localizable("confirm_delete_channel") + name + "?"
        }else {
            message = localizable("confirm_delete_channel") + "?"
        }
        let alertVC = UIAlertController.reconfimAlertView(title: localizable("delete_channel"), message: message) {
            self.viewModel?.deleteChannel(completion: { [weak self] error in
                
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }else {
                    self?.view.makeToast(localizable("delete_channel_suscess"), duration: 1, completion: { didTap in
                        //通知上级页面
                        NotificationCenter.default.post(name: NotificationName.deleteChannel, object: self?.viewModel?.channel)
                        self?.didDeleteChannel?(self?.viewModel?.channel)
                        self?.close()
                    })
                }
            })
        }
        self.present(alertVC, animated: true, completion: nil)
    }
    
//    MARK: QChatTextEditCellDelegate
    func textDidChange(_ textField: UITextField) {
        if textField.tag == 20 {
            if textField.text?.count == 0 {
                self.navigationItem.rightBarButtonItem?.tintColor = .ne_greyText
            }else {
                if var str = textField.text, str.count > 50 {
                    str = str.substring(to: str.index(str.startIndex, offsetBy: 50))
                    print("str:\(str)")
                    textField.text = str
                }
                self.navigationItem.rightBarButtonItem?.tintColor = .ne_blueText
            }
            viewModel?.channelTmp?.name = textField.text
        }else if textField.tag == 21 {
            if var str = textField.text, str.count > 64 {
                str = str.substring(to: str.index(str.startIndex, offsetBy: 64))
                print("str:\(str)")
                textField.text = str
            }
            viewModel?.channelTmp?.topic = textField.text
        }
    }
    
//    MARK: event
    @objc func save() {
        viewModel?.updateChannelInfo(completion: {[weak self] error, channel in
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
                return
            }
            self?.view.makeToast(localizable("update_channel_suscess"), duration: 2, completion: { didTap in
                self?.didUpdateChannel?(channel)
                NotificationCenter.default.post(name: NotificationName.updateChannel, object: channel)
                //通知上级页面
                self?.close()
            })
        })
    }
    
    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    


}
