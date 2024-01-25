//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

public typealias NESelectTeamMemberBlock = ([TeamMemberInfoModel]) -> Void

@objcMembers
open class NEBaseTeamMemberSelectController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, TeamMemberSelectViewModelDelegate {
  public var selectMemberBlock: NESelectTeamMemberBlock?

  let viewmodel = TeamMemberSelectViewModel()

  var teamId: String?

  public var cellClassDic = [Int: UITableViewCell.Type]() // key 值为 table section 值

  public let searchInput = UITextField()

  public var selectCountLimit = 10

  public lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    table.keyboardDismissMode = .onDrag
    table
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: localizable("member_select_no_member"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view

  }()

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    viewmodel.delegate = self
    setupUI()
    if let tid = teamId {
      viewmodel.getTeamInfo(tid) { [weak self] error in
        if let err = error {
          self?.view.makeToast(err.localizedDescription)
        } else {
          self?.contentTable.reloadData()
        }
      }
    }
  }

  open func setupUI() {
    title = localizable("team_member_select")
    view.backgroundColor = .white
    view.addSubview(contentTable)

    let searchBack = UIView()
    view.addSubview(searchBack)
    searchBack.backgroundColor = UIColor(hexString: "F2F4F5")
    searchBack.translatesAutoresizingMaskIntoConstraints = false
    searchBack.clipsToBounds = true
    searchBack.layer.cornerRadius = 4.0
    NSLayoutConstraint.activate([
      searchBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBack.topAnchor.constraint(equalTo: view.topAnchor, constant: 13 + topConstant),
      searchBack.heightAnchor.constraint(equalToConstant: 32),
    ])

    let searchImage = UIImageView()
    searchBack.addSubview(searchImage)
    searchImage.image = coreLoader.loadImage("search")
    searchImage.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchImage.centerYAnchor.constraint(equalTo: searchBack.centerYAnchor),
      searchImage.leftAnchor.constraint(equalTo: searchBack.leftAnchor, constant: 18),
      searchImage.widthAnchor.constraint(equalToConstant: 13),
      searchImage.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBack.addSubview(searchInput)
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImage.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBack.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBack.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBack.bottomAnchor),
    ])
    searchInput.textColor = UIColor(hexString: "333333")
    searchInput.placeholder = localizable("search_member")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.delegate = self
    searchInput.clearButtonMode = .always
    if let clearButton = searchInput.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    searchInput.accessibilityIdentifier = "id.addFriendAccount"

//        NotificationCenter.default.addObserver(
//          self,
//          selector: #selector(textFieldChange),
//          name: UITextField.textDidChangeNotification,
//          object: nil
//        )

    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: searchBack.bottomAnchor),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    cellClassDic.forEach { (key: Int, value: UITableViewCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
      emptyView.widthAnchor.constraint(equalToConstant: 122),
      emptyView.heightAnchor.constraint(equalToConstant: 91),
    ])

    navigationView.moreButton.isHidden = false
    navigationView.moreButton.setImage(nil, for: .normal)
    navigationView.moreButton.addTarget(self, action: #selector(didClickSure), for: .touchUpInside)
    didChangeSelectMember()
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewmodel.showDatas.count <= 0 {
      emptyView.isHidden = false
    } else {
      emptyView.isHidden = true
    }
    return viewmodel.showDatas.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewmodel.showDatas[indexPath.row]
    guard let cell = tableView.cellForRow(at: indexPath) as? NEBaseTeamMemberSelectCell else {
      return
    }
    if let member = model.member, let accid = member.teamMember?.userId {
      if viewmodel.selectDic[accid] != nil {
        viewmodel.selectDic[accid] = nil
        model.isSelected = false
        cell.checkImageView.isHighlighted = false
      } else {
        if viewmodel.selectDic.count >= selectCountLimit {
          let toastString = String(format: localizable("select_limit_tip"), selectCountLimit)
          view.makeToast(toastString)
          return
        }
        viewmodel.selectDic[accid] = member
        model.isSelected = true
        cell.checkImageView.isHighlighted = true
      }
      didChangeSelectMember()
    }
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    0
  }

  open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text else {
      return false
    }
    if text.count <= 0 {
      return false
    }
    return true
  }

  open func textFieldShouldClear(_ textField: UITextField) -> Bool {
    viewmodel.showDatas = viewmodel.datas
    contentTable.reloadData()
    return true
  }

  open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let finalString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
    if string.count <= 0 {
      if finalString.count <= 0 {
        viewmodel.showDatas = viewmodel.datas
        contentTable.reloadData()
      } else {
        viewmodel.showDatas = viewmodel.searchAllData(finalString)
        contentTable.reloadData()
      }
    } else {
      viewmodel.showDatas = viewmodel.searchAllData(finalString)
      contentTable.reloadData()
    }
    return true
  }

  func didChangeSelectMember() {
    if viewmodel.selectDic.count > 0 {
      let title = localizable("member_select_sure") + "(\(viewmodel.selectDic.count))"
      navigationView.moreButton.setTitle(title, for: .normal)
    } else {
      navigationView.moreButton.setTitle(localizable("member_select_sure"), for: .normal)
    }
  }

  open func didNeedRefresh() {
    contentTable.reloadData()
    didChangeSelectMember()
  }

  open func didClickSure() {
    print("sure click")

    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      view.makeToast(localizable("network_error"))
      return
    }

    if viewmodel.selectDic.count + viewmodel.managerSet.count > selectCountLimit {
      view.makeToast(localizable("max_managers_tip"))
      return
    }

    if viewmodel.selectDic.count <= 0 {
      view.makeToast(localizable("member_empty_tip"))
      return
    }

    var retArray = [TeamMemberInfoModel]()
    viewmodel.selectDic.forEach { (key: String, value: TeamMemberInfoModel) in
      retArray.append(value)
    }
    if let block = selectMemberBlock {
      block(retArray)
    }
    navigationController?.popViewController(animated: true)
  }
}
