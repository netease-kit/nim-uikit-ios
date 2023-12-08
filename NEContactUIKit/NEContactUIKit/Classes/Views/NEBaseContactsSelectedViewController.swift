// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseContactsSelectedViewController: NEBaseContactViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
  public var callBack: ContactsSelectCompletion?

  public var filterUsers: Set<String>?
  var lastTitleIndex = 0
  public var limit = 10 // max select count

  // 单聊中对方的userId
  public var userId: String?

  public var selectArray = [ContactInfo]()
  public let selectDic = [String: ContactInfo]()

  public lazy var collectionBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.layer.cornerRadius = 4
    view.isHidden = true
    return view
  }()

  public lazy var collection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collect = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collect.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    collect.accessibilityIdentifier = "id.selected"
    return collect
  }()

  public var sureBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 76, height: 32))

  var collectionBackViewTopMargin: CGFloat = 0
  var collectionBackViewHeight: CGFloat = 52

  public var customCells = [Int: NEBaseContactTableViewCell.Type]() // custom ui cell

  public let viewModel = ContactViewModel(contactHeaders: nil)

  public lazy var tableView: UITableView = {
    let table = UITableView(frame: .zero, style: .plain)
    table.backgroundColor = .clear
    table.sectionIndexColor = .ne_greyText
    table.delegate = self
    table.dataSource = self
    table.translatesAutoresizingMaskIntoConstraints = false
    table.separatorStyle = .none
    table.contentInset = .init(top: -10, left: 0, bottom: 0, right: 0)
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0
    }

    return table
  }()

  var tableViewTopAnchor: NSLayoutConstraint?

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    weak var weakSelf = self
    viewModel.loadData(filterUsers) { error, userSectionCount in
      weakSelf?.emptyView.isHidden = userSectionCount > 0
      weakSelf?.tableView.reloadData()
      weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.contacts.count ?? 0) > 0
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("select")
    navigationView.navTitle.text = title
    emptyView.settingContent(content: localizable("no_friend"))
    setupUI()
    setupNavRightItem()
  }

  open func setupUI() {
    view.addSubview(collectionBackView)
    NSLayoutConstraint.activate([
      collectionBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + collectionBackViewTopMargin),
      collectionBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      collectionBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      collectionBackView.heightAnchor.constraint(equalToConstant: collectionBackViewHeight),
    ])

    collection.backgroundColor = .clear
    collection.delegate = self
    collection.dataSource = self
    collection.allowsMultipleSelection = false
    collection.translatesAutoresizingMaskIntoConstraints = false
    collectionBackView.addSubview(collection)
    NSLayoutConstraint.activate([
      collection.centerYAnchor.constraint(equalTo: collectionBackView.centerYAnchor),
      collection.leftAnchor.constraint(equalTo: collectionBackView.leftAnchor),
      collection.rightAnchor.constraint(equalTo: collectionBackView.rightAnchor),
      collection.heightAnchor.constraint(equalToConstant: collectionBackViewHeight),
    ])

    view.addSubview(tableView)

    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableViewTopAnchor!,
    ])

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    customCells.forEach { (key: Int, value: AnyClass) in
      if value is ContactCellDataProtrol.Type {
        self.tableView.register(
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
      let rightItem = UIBarButtonItem(customView: sureBtn)
      navigationItem.rightBarButtonItem = rightItem
      sureBtn.addTarget(self, action: #selector(sureClick(_:)), for: .touchUpInside)
      sureBtn.setTitle(localizable("alert_sure"), for: .normal)
      sureBtn.setTitleColor(.white, for: .normal)
      sureBtn.layer.cornerRadius = 4
      sureBtn.contentHorizontalAlignment = .center
      sureBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    } else {
      navigationView.setMoreButtonTitle(localizable("alert_sure"))
      navigationView.moreButton.setTitleColor(.white, for: .normal)
      navigationView.moreButton.layer.cornerRadius = 4
      navigationView.moreButton.contentHorizontalAlignment = .center
      navigationView.addMoreButtonTarget(target: self, selector: #selector(sureClick(_:)))
      navigationView.setBackButtonTitle(localizable("close"))
      navigationView.backButton.setTitleColor(.ne_darkText, for: .normal)
      sureBtn = navigationView.moreButton
    }
  }

  open func sureClick(_ sender: UIButton) {
    if selectArray.count <= 0 {
      showToast(localizable("select_contact"))
      return
    }

    if !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      showToast(localizable("network_error"))
      return
    }

    if let completion = callBack {
      completion(selectArray)
    }
    var accids = [String]()
    var names = [String]()

    names.append(viewModel.contactRepo.getUserName())

    var users = [NIMUser]()
    for c in selectArray {
      accids.append(c.user?.userId ?? "")
      if let name = c.user?.userInfo?.nickName {
        names.append(name)
      } else if let accid = c.user?.userId {
        names.append(accid)
      }
      if let user = c.user?.imUser {
        users.append(user)
      }
    }

    if let uid = userId {
      accids.append(uid)
    }
    let nameString = names.joined(separator: "、")
    print("name string : ", nameString)
    Router.shared.use(
      ContactSelectedUsersRouter,
      parameters: ["accids": accids, "names": nameString, "im_user": users],
      closure: nil
    )
    navigationController?.popViewController(animated: true)
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
    let cell = tableView.cellForRow(at: indexPath) as? NEBaseContactSelectedCell
    if info.isSelected == true {
      didUnselectContact(info)
      cell?.setSelect()
    } else {
      if selectArray.count >= limit {
        view.makeToast("超出\(limit)人限制")
        return
      }
      didSelectContact(info)
      cell?.setUnselect()
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
    collection.reloadData()
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
    collection.reloadData()
    tableView.reloadData()
    refreshSelectCount()
  }

  func refreshSelectCount() {
    if selectArray.count > 0 {
      sureBtn.setTitle("确定(\(selectArray.count))", for: .normal)
    } else {
      sureBtn.setTitle(localizable("alert_sure"), for: .normal)
    }
  }
}
