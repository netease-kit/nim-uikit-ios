//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

public typealias NESelectTeamMemberBlock = ([NETeamMemberInfoModel]) -> Void

@objcMembers
open class NEBaseTeamMemberSelectController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, TeamMemberSelectViewModelDelegate {
  public var selectMemberBlock: NESelectTeamMemberBlock?

  let viewModel = TeamMemberSelectViewModel()

  /// 群id
  var teamId: String?

  public var cellClassDic = [Int: UITableViewCell.Type]() // key 值为 table section 值

  /// 搜索输入框
  public lazy var searchInput: UITextField = {
    let searchInput = UITextField()
    searchInput.textColor = UIColor(hexString: "333333")
    searchInput.placeholder = localizable("search_member")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.delegate = self
    searchInput.clearButtonMode = .always
    return searchInput
  }()

  /// 选择数量限制
  public var selectCountLimit = 10

  /// 内容列表
  public lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  /// 搜索框背景视图
  let searchBackView = UIView()

  /// 数据为空占位图
  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: localizable("member_select_no_member"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view

  }()

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    viewModel.delegate = self
    setupUI()
    if let tid = teamId {
      viewModel.getTeamInfo(tid) { [weak self] error in
        if let err = error {
          self?.view.makeToast(err.localizedDescription)
        } else {
          self?.didReloadTableData()
          print("获取群信息成功 : ", self?.viewModel.teamInfoModel?.users.count as Any)
        }
      }
    }
  }

  /// 刷新列表
  open func didReloadTableData() {
    if viewModel.showDatas.count <= 0 {
      emptyView.isHidden = false
    } else {
      emptyView.isHidden = true
    }
    contentTableView.reloadData()
  }

  let searchImageView: UIImageView = {
    let searchImageView = UIImageView()
    searchImageView.image = coreLoader.loadImage("search")
    searchImageView.translatesAutoresizingMaskIntoConstraints = false
    return searchImageView
  }()

  open func setupUI() {
    title = localizable("team_member_select")
    view.backgroundColor = .white
    view.addSubview(contentTableView)

    view.addSubview(searchBackView)
    searchBackView.backgroundColor = UIColor(hexString: "F2F4F5")
    searchBackView.translatesAutoresizingMaskIntoConstraints = false
    searchBackView.clipsToBounds = true
    searchBackView.layer.cornerRadius = 4.0
    NSLayoutConstraint.activate([
      searchBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 13 + topConstant),
      searchBackView.heightAnchor.constraint(equalToConstant: 32),
    ])

    searchBackView.addSubview(searchImageView)
    NSLayoutConstraint.activate([
      searchImageView.centerYAnchor.constraint(equalTo: searchBackView.centerYAnchor),
      searchImageView.leftAnchor.constraint(equalTo: searchBackView.leftAnchor, constant: 18),
      searchImageView.widthAnchor.constraint(equalToConstant: 13),
      searchImageView.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBackView.addSubview(searchInput)
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImageView.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBackView.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBackView.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBackView.bottomAnchor),
    ])

    if let clearButton = searchInput.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    searchInput.accessibilityIdentifier = "id.addFriendAccount"

    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: searchBackView.bottomAnchor),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    for (key, value) in cellClassDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
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
    viewModel.showDatas.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewModel.showDatas[indexPath.row]
    guard let cell = tableView.cellForRow(at: indexPath) as? NEBaseTeamMemberSelectCell else {
      return
    }
    if let member = model.member, let accid = member.teamMember?.accountId {
      if viewModel.selectDic[accid] != nil {
        viewModel.selectDic[accid] = nil
        model.isSelected = false
        cell.checkImageView.isHighlighted = false
      } else {
        viewModel.selectDic[accid] = member
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
    viewModel.showDatas = viewModel.datas
    didReloadTableData()
    return true
  }

  /// 文本输入变更
  open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let finalString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
    if string.count <= 0 {
      if finalString.count <= 0 {
        viewModel.showDatas = viewModel.datas
        didReloadTableData()
      } else {
        viewModel.showDatas = viewModel.searchAllData(finalString)
        didReloadTableData()
      }
    } else {
      viewModel.showDatas = viewModel.searchAllData(finalString)
      didReloadTableData()
    }
    return true
  }

  /// 选择成员变更回调，内部根据选择数量来做右上角状态变更
  func didChangeSelectMember() {
    if viewModel.selectDic.count > 0 {
      let title = localizable("member_select_sure") + "(\(viewModel.selectDic.count))"
      navigationView.moreButton.setTitle(title, for: .normal)
    } else {
      navigationView.moreButton.setTitle(localizable("member_select_sure"), for: .normal)
    }
  }

  /// 刷新回调
  open func didNeedRefresh() {
    contentTableView.reloadData()
    didChangeSelectMember()
  }

  /// 点击确定添加回调
  open func didClickSure() {
    print("sure click")

    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      view.makeToast(localizable("network_error"))
      return
    }

    if viewModel.selectDic.count + viewModel.managerSet.count > selectCountLimit {
      view.makeToast(localizable("max_managers_tip"))
      return
    }

    if viewModel.selectDic.count <= 0 {
      view.makeToast(localizable("member_empty_tip"))
      return
    }

    var retArray = [NETeamMemberInfoModel]()
    for (_, value) in viewModel.selectDic {
      retArray.append(value)
    }
    if let block = selectMemberBlock {
      block(retArray)
    }
    navigationController?.popViewController(animated: true)
  }
}
