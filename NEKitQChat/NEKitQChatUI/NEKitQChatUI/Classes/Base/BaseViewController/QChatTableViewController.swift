
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCore

public class QChatTableViewController: NEBaseViewController,UITableViewDelegate, UITableViewDataSource {
    
    public var tableView: UITableView = UITableView(frame: .zero, style: .grouped)
    public var topConstraint: NSLayoutConstraint?
    public var bottomConstraint: NSLayoutConstraint?

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        ])
        
        if #available(iOS 11.0, *) {
            self.topConstraint = self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0)
            self.bottomConstraint = self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)

        } else {
            // Fallback on earlier versions
            self.topConstraint = self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
            self.bottomConstraint = self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        }
        self.topConstraint?.isActive = true
        self.bottomConstraint?.isActive = true
        
        self.tableView.sectionHeaderHeight = 38
        self.tableView.sectionFooterHeight = 0
        self.tableView.rowHeight = 62
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier:"UITableViewCell" , for: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
