
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM

struct ChannelSelection {
    var sectionName = ""
    var isSeleted = false
}

protocol QChatChannelTypeVCDelegate: AnyObject {
    func didSelected(type: Int)
}

public class QChatChannelTypeVC: QChatTableViewController {
    var dataList = [ChannelSelection]()
    weak var delegate: QChatChannelTypeVCDelegate?
    var isPrivate: Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        commonUI()
    }
    
    func commonUI() {
        self.title = localizable("channel_type")
        self.tableView.register(QChatTextSelectionCell.self, forCellReuseIdentifier: "\(QChatTextSelectionCell.self)")
        self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
    }
    func loadData() {
        dataList.append(ChannelSelection(sectionName: localizable("public"), isSeleted: !isPrivate))
        dataList.append(ChannelSelection(sectionName: localizable("private"), isSeleted: isPrivate))
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QChatTextSelectionCell = tableView.dequeueReusableCell(withIdentifier: "\(QChatTextSelectionCell.self)", for: indexPath) as! QChatTextSelectionCell
        let item = dataList[indexPath.row]
        cell.titleLabel.text = item.sectionName
        if indexPath.row == 0 {
            cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
        }else {
            cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
            cell.setSelected(true, animated: true)
        }
        cell.selected(selected: item.isSeleted)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelected(type: indexPath.row)
        self.navigationController?.popViewController(animated: true)
    }
    
}
