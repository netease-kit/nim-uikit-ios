
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class QChatSearchVC: NEBaseViewController, UITableViewDelegate, UITableViewDataSource {
    var textField = UITextField()
    var tableView = UITableView(frame: .zero, style: .plain)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonUI()
    }
    
    func commonUI() {
//        textField.placeholder = "ddd";
//        textField.leftView = UIImageView(image: UIImage.ne_imageNamed(name: "search"))
//        textField.leftViewMode = .always
//        textField.layer.cornerRadius = 8;
//        textField.clipsToBounds = true
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        textField.backgroundColor = .ne_lightBackgroundColor
//        self.view.addSubview(textField)
//        if #available(iOS 11.0, *) {
//            NSLayoutConstraint.activate([
//                textField.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
//                textField.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20),
//                textField.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20),
//                textField.heightAnchor.constraint(equalToConstant: 32),
//            ])
//        } else {
//            NSLayoutConstraint.activate([
//                textField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),
//                textField.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20),
//                textField.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20),
//                textField.heightAnchor.constraint(equalToConstant: 32),
//            ])
//        }
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }else {
            NSLayoutConstraint.activate([
                self.tableView.topAnchor.constraint(equalTo: self.textField.bottomAnchor),
                self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ])
        }
        self.tableView.sectionHeaderHeight = 0
        self.tableView.sectionFooterHeight = 0
        self.tableView.rowHeight = 40
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(UITableViewCell.self)")
    }
    
//    MARK:UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(UITableViewCell.self)", for: indexPath)
        return cell
    }

}
