// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 人员选择页面 - 基类
@objcMembers
open class NEBaseContactSelectedViewController: NEContactBaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
  public var callBack: ContactsSelectCompletion?

  public var filterUsers: Set<String>?
  var lastTitleIndex = 0
  public var limit = 10 // max select count

  // 单聊中对方的userId
  public var userId: String?

  public var selectArray = [ContactInfo]()
  public let selectDic = [String: ContactInfo]()
  public var isCreating = false // 是否正在创建群组

  public var collectionBackViewTopAnchor: NSLayoutConstraint?
  public lazy var collectionBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.layer.cornerRadius = 4
    view.isHidden = true
    return view
  }()

  public lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collectView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    collectView.accessibilityIdentifier = "id.selected"
    return collectView
  }()

  public var sureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 76, height: 32))

  var collectionBackViewTopMargin: CGFloat = 0
  var collectionBackViewHeight: CGFloat = 52

  public var customCells = [Int: NEBaseContactTableViewCell.Type]() // custom ui cell

  public let viewModel = ContactViewModel(contactHeaders: nil)

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.backgroundColor = .clear
    tableView.sectionIndexColor = .ne_greyText
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.contentInset = .init(top: -10, left: 0, bottom: 0, right: 0)
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

  var tableViewTopAnchor: NSLayoutConstraint?

  init(filterUsers: Set<String>? = nil) {
    super.init(nibName: nil, bundle: nil)
    self.filterUsers = filterUsers
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionBackViewTopAnchor?.constant = topConstant + collectionBackViewTopMargin
    tableViewTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("select")
    emptyView.setText(localizable("no_friend"))
    setupUI()
    setupNavRightItem()

    weak var weakSelf = self
    viewModel.loadData(filterUsers) { error, userSectionCount in
      weakSelf?.emptyView.isHidden = userSectionCount > 0
      weakSelf?.tableView.reloadData()
    }
  }

  open func setupUI() {
    view.addSubview(collectionBackView)
    collectionBackViewTopAnchor = collectionBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + collectionBackViewTopMargin)
    collectionBackViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      collectionBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      collectionBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      collectionBackView.heightAnchor.constraint(equalToConstant: collectionBackViewHeight),
    ])

    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.allowsMultipleSelection = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionBackView.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.centerYAnchor.constraint(equalTo: collectionBackView.centerYAnchor),
      collectionView.leftAnchor.constraint(equalTo: collectionBackView.leftAnchor),
      collectionView.rightAnchor.constraint(equalTo: collectionBackView.rightAnchor),
      collectionView.heightAnchor.constraint(equalToConstant: collectionBackViewHeight),
    ])

    view.addSubview(tableView)

    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    for (key, value) in customCells {
      if value is ContactCellDataProtrol.Type {
        tableView.register(
          value,
          forCellReuseIdentifier: "\(NSStringFromClass(value))"
        )
      }
    }

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  open func setupNavRightItem() {
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      let rightItem = UIBarButtonItem(customView: sureButton)
      navigationItem.rightBarButtonItem = rightItem
      sureButton.addTarget(self, action: #selector(sureClick(_:)), for: .touchUpInside)
      sureButton.setTitle(localizable("alert_sure"), for: .normal)
      sureButton.setTitleColor(.white, for: .normal)
      sureButton.layer.cornerRadius = 4
      sureButton.contentHorizontalAlignment = .center
      sureButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    } else {
      navigationView.setMoreButtonTitle(localizable("alert_sure"))
      navigationView.moreButton.setTitleColor(.white, for: .normal)
      navigationView.moreButton.layer.cornerRadius = 4
      navigationView.moreButton.contentHorizontalAlignment = .center
      navigationView.addMoreButtonTarget(target: self, selector: #selector(sureClick(_:)))
      sureButton = navigationView.moreButton
    }
  }

  open func sureClick(_ sender: UIButton) {
    // 防止多次点击确定按钮会多次创建群聊
    if isCreating {
      return
    }

    if selectArray.count <= 0 {
      showToast(localizable("select_contact"))
      return
    }

    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(localizable("network_error"))
      return
    }

    if let completion = callBack {
      completion(selectArray)
      navigationController?.popViewController(animated: true)
      return
    }

    isCreating = true
    var accids = [String]()
    var names = [String]()
    let group = DispatchGroup()
    var mine: NEUserWithFriend?

    if let mineInfo = NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) {
      mine = mineInfo
    } else {
      group.enter()
      ContactRepo.shared.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { users, error in
        mine = users?.first
        group.leave()
      }
    }

    group.notify(queue: .main) { [weak self] in
      let myName = mine?.showName() ?? IMKitClient.instance.account()
      names.append(myName)
      var users = [V2NIMUser]()
      for c in self?.selectArray ?? [] {
        accids.append(c.user?.user?.accountId ?? "")
        if let name = c.user?.user?.name {
          names.append(name)
        } else if let accid = c.user?.user?.accountId {
          names.append(accid)
        }
        if let user = c.user?.user {
          users.append(user)
        }
      }

      if let uid = self?.userId {
        accids.append(uid)
      }
      let nameString = names.joined(separator: "、")
      print("name string : ", nameString)
      Router.shared.use(
        ContactSelectedUsersRouter,
        parameters: ["accids": accids, "names": nameString, "im_user": users],
        closure: nil
      )
      self?.navigationController?.popViewController(animated: true)
      self?.isCreating = false
    }
  }

  // MARK: - Table View DataSource And Delegate

  open func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.contacts.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.contacts[section].contacts.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    if let cellClass = customCells[info.contactCellType] {
      let anyCell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(cellClass))",
        for: indexPath
      ) as? NEBaseContactTableViewCell
      anyCell?.setModel(info)
      if let cell = anyCell {
        return cell
      }
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    nil
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.contacts[section].initial.count > 0 {
      return 40
    }
    return 0
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    if info.isSelected == true {
      didUnselectContact(info)
    } else {
      if selectArray.count >= limit {
        view.makeToast(String(format: localizable("exceeded_limit"), limit))
        return
      }
      didSelectContact(info)
    }
  }

  open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    viewModel.indexs
  }

  open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    for (i, t) in viewModel.contacts.enumerated() {
      if t.initial == title {
        lastTitleIndex = i
        return i
      }
    }
    return lastTitleIndex
  }

  // MARK: Collection View DataSource And Delegate

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    selectArray.count
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didSelectItemAt indexPath: IndexPath) {
    let contactInfo = selectArray[indexPath.row]
    didUnselectContact(contactInfo)
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 46, height: collectionBackViewHeight)
  }

  func didSelectContact(_ contact: ContactInfo) {
    contact.isSelected = true
    if selectArray.contains(where: { c in
      contact === c
    }) == false {
      selectArray.append(contact)
      if collectionBackView.isHidden {
        collectionBackView.isHidden = false
        tableViewTopAnchor?.constant += collectionBackViewHeight + collectionBackViewTopMargin * 2
      }
    }
    collectionView.reloadData()
    tableView.reloadData()
    refreshSelectCount()
  }

  func didUnselectContact(_ contact: ContactInfo) {
    contact.isSelected = false
    selectArray.removeAll { c in
      contact === c
    }
    if selectArray.count <= 0 {
      collectionBackView.isHidden = true
      tableViewTopAnchor?.constant -= collectionBackViewHeight + collectionBackViewTopMargin * 2
    }
    collectionView.reloadData()
    tableView.reloadData()
    refreshSelectCount()
  }

  func refreshSelectCount() {
    if selectArray.count > 0 {
      sureButton.setTitle("确定(\(selectArray.count))", for: .normal)
    } else {
      sureButton.setTitle(localizable("alert_sure"), for: .normal)
    }
  }
}
