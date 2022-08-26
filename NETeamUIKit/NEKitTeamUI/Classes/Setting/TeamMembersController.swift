
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitTeam
import NEKitCore
//

public class TeamMembersController: NEBaseViewController,UITableViewDelegate, UITableViewDataSource {
  var datas: [TeamMemberInfoModel]?

  var ownerId: String?

  var isSenior = false

  var searchDatas = [TeamMemberInfoModel]()

  lazy var searchTextField: UITextField = {
    let field = UITextField()
    field.translatesAutoresizingMaskIntoConstraints = false
    field.placeholder = "搜索好友"
    field.textColor = .ne_greyText
    field.font = UIFont.systemFont(ofSize: 14.0)
    field.backgroundColor = UIColor.ne_backcolor
    return field
  }()

  lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
//        table.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    table.backgroundColor = .white
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    table
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    table.keyboardDismissMode = .onDrag
//        table.bounces = false
    return table
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupUI()
  }

  func setupUI() {
    if isSenior {
      title = "群成员"
    } else {
      title = "讨论组成员"
    }

    let back = UIView()
    back.backgroundColor = .ne_backcolor
    back.translatesAutoresizingMaskIntoConstraints = false
    back.clipsToBounds = true
    back.layer.cornerRadius = 4.0

    view.addSubview(back)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        back.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 4.0
        ),
        back.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        back.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        back.heightAnchor.constraint(equalToConstant: 32),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        back.topAnchor.constraint(equalTo: view.topAnchor, constant: 4.0),
        back.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        back.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        back.heightAnchor.constraint(equalToConstant: 32),
      ])
    }

    let searchIcon = UIImageView()
    searchIcon.image = coreLoader.loadImage("search_icon")
    searchIcon.translatesAutoresizingMaskIntoConstraints = false
    back.addSubview(searchIcon)
    NSLayoutConstraint.activate([
      searchIcon.centerYAnchor.constraint(equalTo: back.centerYAnchor),
      searchIcon.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 16.0),
    ])

    back.addSubview(searchTextField)
    NSLayoutConstraint.activate([
      searchTextField.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 36.0),
      searchTextField.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -16.0),
      searchTextField.topAnchor.constraint(equalTo: back.topAnchor),
      searchTextField.bottomAnchor.constraint(equalTo: back.bottomAnchor),
    ])

    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: back.bottomAnchor, constant: 10),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentTable.register(TeamMemberCell.self, forCellReuseIdentifier: "\(TeamMemberCell.self)")

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  func isOwner(_ userId: String?) -> Bool {
    if isSenior == false {
      return false
    }
    if let uid = userId, let oid = ownerId, uid == oid {
      return true
    }
    return false
  }

  @objc func textChange() {
    searchDatas.removeAll()
    if let text = searchTextField.text, text.count > 0 {
      datas?.forEach { model in
        if let uid = model.nimUser?.userId, uid.contains(text) {
          searchDatas.append(model)
        } else if let nick = model.nimUser?.userInfo?.nickName, nick.contains(text) {
          searchDatas.append(model)
        } else if let alias = model.nimUser?.alias, alias.contains(text) {
          searchDatas.append(model)
        } else if let tNick = model.teamMember?.nickname, tNick.contains(text) {
          searchDatas.append(model)
        }
      }
    }
    contentTable.reloadData()
  }
    func getRealModel(_ index: Int) -> TeamMemberInfoModel? {
      if let text = searchTextField.text, text.count > 0 {
        return searchDatas[index]
      }
      return datas?[index]
    }
    
    
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
    
    
    //MARK: UITableViewDelegate, UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if let text = searchTextField.text, text.count > 0 {
        return searchDatas.count
      }
      return datas?.count ?? 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(TeamMemberCell.self)",
        for: indexPath
      ) as? TeamMemberCell {
        if let model = getRealModel(indexPath.row) {
          cell.configure(model)
          cell.ownerLabel.isHidden = !isOwner(model.nimUser?.userId)
        }
        return cell
      }
      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      62.0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if let model = getRealModel(indexPath.row), let user = model.nimUser {
        if IMKitLoginManager.instance.isMySelf(user.userId) {
          Router.shared.use(
            MeSettingRouter,
            parameters: ["nav": navigationController as Any],
            closure: nil
          )
        } else {
          Router.shared.use(
            ContactUserInfoPageRouter,
            parameters: ["nav": navigationController as Any, "nim_user": user],
            closure: nil
          )
        }
      }
    }
}
