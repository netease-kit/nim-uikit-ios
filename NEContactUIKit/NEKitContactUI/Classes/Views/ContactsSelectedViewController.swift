
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import Toast_Swift
import NEKitCore
import NIMSDK

open class ContactsSelectedViewController: ContactBaseViewController {
  public var callBack: ContactsSelectCompletion?

  public var filterUsers: Set<String>?

  public var limit = 10 // max select count

  var selectArray = [ContactInfo]()
  let selectDic = [String: ContactInfo]()
  lazy var collection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collect = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collect.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    return collect
  }()

  let sureBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 44))

  var collectionHeight: NSLayoutConstraint?

  public var customCells: [Int: ContactTableViewCell.Type] =
    [ContactCellType.ContactPerson.rawValue: ContactSelectedCell.self] // custom ui cell

  let viewModel = ContactViewModel(contactHeaders: nil)

  let tableView = UITableView()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    title = "选择"
    setupUI()
    setupNavRightItem()

    viewModel.loadData(filterUsers)
    tableView.reloadData()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = false
  }

  func setupUI() {
    view.addSubview(collection)
    collection.delegate = self
    collection.dataSource = self
    collection.allowsMultipleSelection = false
    collection.translatesAutoresizingMaskIntoConstraints = false
    collectionHeight = collection.heightAnchor.constraint(equalToConstant: 0)
    collectionHeight?.isActive = true
    collection.backgroundColor = UIColor(hexString: "F2F4F5")
    NSLayoutConstraint.activate([
      collection.topAnchor.constraint(equalTo: view.topAnchor),
      collection.leftAnchor.constraint(equalTo: view.leftAnchor),
      collection.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
    collection.register(
      ContactUnCheckCell.self,
      forCellWithReuseIdentifier: "\(NSStringFromClass(ContactUnCheckCell.self))"
    )

    view.addSubview(tableView)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: collection.bottomAnchor),
    ])

    customCells.forEach { (key: Int, value: AnyClass) in
      if value is ContactCellDataProtrol.Type {
        self.tableView.register(
          value,
          forCellReuseIdentifier: "\(NSStringFromClass(value))"
        )
      }
    }
    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )
    tableView.rowHeight = 52
    tableView.sectionHeaderHeight = 40
    tableView.sectionFooterHeight = 0
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.separatorStyle = .none
  }

  func setupNavRightItem() {
    let rightItem = UIBarButtonItem(customView: sureBtn)
    navigationItem.rightBarButtonItem = rightItem
    sureBtn.addTarget(self, action: #selector(sureClick(_:)), for: .touchUpInside)
    sureBtn.setTitle("确定", for: .normal)
    sureBtn.setTitleColor(UIColor(hexString: "337EFF"), for: .normal)
    sureBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    sureBtn.contentHorizontalAlignment = .right
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

// action
extension ContactsSelectedViewController {
  @objc func sureClick(_ sender: UIButton) {
    if selectArray.count <= 0 {
      view.makeToast("请选择联系人")
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

    let nameString = names.joined(separator: "、")
    print("name string : ", nameString)
    Router.shared.use(
      ContactSelectedUsersRouter,
      parameters: ["accids": accids, "names": nameString, "im_user": users],
      closure: nil
    )
    navigationController?.popViewController(animated: true)
  }
}

extension ContactsSelectedViewController: UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
  // MARK: - Table View DataSource And Delegate

  public func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.contacts.count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.contacts[section].contacts.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    if let cellClass = customCells[info.contactCellType] {
      let anyCell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(cellClass))",
        for: indexPath
      ) as? ContactTableViewCell
      anyCell?.setModel(info)
      if let cell = anyCell {
        return cell
      }
    }
    return UITableViewCell()
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    let sectionView: ContactSectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
      ) as! ContactSectionView
    sectionView.titleLabel.text = viewModel.contacts[section].initial
    return sectionView
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.contacts[section].initial.count > 0 {
      return 40
    }
    return 0
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    let cell = tableView.cellForRow(at: indexPath) as? ContactSelectedCell
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

  public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    viewModel.indexs
  }

  // MARK: Collection View DataSource And Delegate

  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    selectArray.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             didSelectItemAt indexPath: IndexPath) {
    let contactInfo = selectArray[indexPath.row]
    didUnselectContact(contactInfo)
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let contactInfo = selectArray[indexPath.row]
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(NSStringFromClass(ContactUnCheckCell.self))",
      for: indexPath
    ) as? ContactUnCheckCell
    cell?.configure(contactInfo)
    return cell ?? UICollectionViewCell()
  }

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 46, height: 52)
  }

  func didSelectContact(_ contact: ContactInfo) {
    contact.isSelected = true
    if selectArray.contains(where: { c in
      contact === c
    }) == false {
      selectArray.append(contact)
      if let height = collectionHeight?.constant, height <= 0 {
        collectionHeight?.constant = 52
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
      collection.reloadData()
      collectionHeight?.constant = 0
    }
    collection.reloadData()
    tableView.reloadData()
    refreshSelectCount()
  }

  func refreshSelectCount() {
    if selectArray.count > 0 {
      sureBtn.setTitle("确定(\(selectArray.count))", for: .normal)
    } else {
      sureBtn.setTitle("确定", for: .normal)
    }
  }
}
