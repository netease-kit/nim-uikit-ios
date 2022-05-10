
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitTeamUI
import NEKitChatUI


class MessageRemindViewController: NEBaseViewController {
    
    public var cellClassDic = [SettingCellType.SettingSwitchCell.rawValue: TeamSettingSwitchCell.self]
    private var viewModel = MessageRemindViewModel()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.getData()
        setupSubviews()
        initialConfig()
    }
    
    func initialConfig(){
        self.title = "消息提醒"
    }
    
    func setupSubviews(){
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        cellClassDic.forEach { (key: Int, value: BaseTeamSettingCell.Type) in
            tableView.register(value, forCellReuseIdentifier: "\(key)")
        }
    }
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = UIColor.init(hexString: "0xF1F1F6")
        table.dataSource = self
        table.delegate = self
        table.separatorColor = .clear
        table.separatorStyle = .none
        table.sectionHeaderHeight = 12.0
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0.0
        }
        return table
    }()
}

extension MessageRemindViewController:UITableViewDelegate,UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.sectionData.count > section {
            let model = viewModel.sectionData[section]
            return model.cellModels.count
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionData.count
    }



    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "\(model.type)", for: indexPath) as? BaseTeamSettingCell {
            cell.configure(model)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

//        let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
//        if let block = model.cellClick {
//            block()
//        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
        return model.rowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        if viewModel.sectionData.count > section {
            let model = viewModel.sectionData[section]
            if model.cellModels.count > 0 {
                return 12.0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.init(hexString: "0xF1F1F6")
        return header
    }
}
