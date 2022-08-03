
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import YXLogin
import NEKitCore
import NIMSDK
import NEKitCoreIM
import NEKitQChatUI
import YXLogin

class MeViewController: UIViewController {

//    private let mineData = [["收藏":"mine_collection"],["关于云信":"about_yunxin"],["设置":"mine_setting"]]
    private let mineData = [["关于云信":"about_yunxin"],["设置":"mine_setting"]]
    private let userProvider = UserInfoProvider.shared
    
    lazy var header: NEUserHeaderView = {
        let view = NEUserHeaderView(frame: .zero)
        view.titleLabel.font = UIFont.systemFont(ofSize: 22.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var nameLabel: UILabel = {
        let name = UILabel()
        name.textColor = .ne_darkText
        name.font = UIFont.systemFont(ofSize: 22.0)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    lazy var idLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ne_darkText
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        updateUserInfo()
        super.viewWillAppear(animated)
    }
    
    func setupSubviews(){
        
        view.addSubview(header)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                header.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                header.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
                header.widthAnchor.constraint(equalToConstant: 60),
                header.heightAnchor.constraint(equalToConstant: 60)
            ])
        } else {
            // Fallback on earlier versions
            NSLayoutConstraint.activate([
                header.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                header.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),
                header.widthAnchor.constraint(equalToConstant: 60),
                header.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
        header.clipsToBounds = true
        header.layer.cornerRadius = 30

        view.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leftAnchor.constraint(equalTo: header.rightAnchor, constant: 15),
            nameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: header.topAnchor)
        ])

        view.addSubview(idLabel)
        NSLayoutConstraint.activate([
            idLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            idLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
            idLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8)
        ])

        //更新个人信息
        updateUserInfo()

        
        let divider = UIView()
        view.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor(hexString: "EFF1F4")
        NSLayoutConstraint.activate([
            divider.leftAnchor.constraint(equalTo: view.leftAnchor),
            divider.heightAnchor.constraint(equalToConstant: 6),
            divider.rightAnchor.constraint(equalTo: view.rightAnchor),
            divider.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 32)
        ])
        
        view.addSubview(tableView)
        view.addSubview(arrow)
        view.addSubview(personInfoBtn)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            arrow.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            arrow.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -20),
        ])
        
        NSLayoutConstraint.activate([
            personInfoBtn.topAnchor.constraint(equalTo: header.topAnchor),
            personInfoBtn.leftAnchor.constraint(equalTo: view.leftAnchor),
            personInfoBtn.rightAnchor.constraint(equalTo: view.rightAnchor),
            personInfoBtn.bottomAnchor.constraint(equalTo: divider.topAnchor)
        ])
    }
    
    func updateUserInfo(){
        let user = userProvider.getUserInfo(userId: IMKitLoginManager.instance.imAccid)
        idLabel.text = "账号:\(user?.userId ?? "")"
        nameLabel.text = user?.userInfo?.nickName
        header.configHeadData(headUrl: user?.userInfo?.avatarUrl, name: user?.showName() ?? "")
    }
    
    //MAKR: lazy method
    private lazy var tableView:UITableView = {
        let tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MineTableViewCell.self, forCellReuseIdentifier: "\(NSStringFromClass(MineTableViewCell.self))")
        tableView.rowHeight = 52
        tableView.backgroundColor = .white
        return tableView
    }()
    
    private lazy var arrow: UIImageView = {
        let imageView = UIImageView(image:UIImage.init(named: "arrow_right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var personInfoBtn:UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(personInfoBtnClick), for: .touchUpInside)
        return btn
        
    }()
    
    
    @objc func personInfoBtnClick(sender:UIButton){
        let personInfo = PersonInfoViewController()
        navigationController?.pushViewController(personInfo, animated: true)
    }

}

extension MeViewController:UITableViewDelegate,UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mineData.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(NSStringFromClass(MineTableViewCell.self))", for: indexPath) as! MineTableViewCell
        cell.configCell(data: mineData[indexPath.row])
        return cell
        
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        if indexPath.row == 0 {
//
//        }else if indexPath.row == 1{
//            let ctrl = IntroduceBrandViewController()
//            navigationController?.pushViewController(ctrl, animated: true)
//        }else if indexPath.row == 2{
//            let ctrl = MineSettingViewController()
//            navigationController?.pushViewController(ctrl, animated: true)
//        }
        
        if indexPath.row == 0 {
            let ctrl = IntroduceBrandViewController()
            navigationController?.pushViewController(ctrl, animated: true)
        }else if indexPath.row == 1{
            let ctrl = MineSettingViewController()
            navigationController?.pushViewController(ctrl, animated: true)
        }else if indexPath.row == 2{
         
        }
        
        

    }
}
