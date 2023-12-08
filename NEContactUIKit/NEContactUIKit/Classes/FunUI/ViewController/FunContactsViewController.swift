// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class FunContactsViewController: NEBaseContactsViewController {
  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchBotton.setImage(UIImage.ne_imageNamed(name: "funSearch"), for: .normal)
    view.searchBotton.setTitle(localizable("search"), for: .normal)
    return view
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
    var contactHeaders = [ContactHeadItem]()
    if NEKitContactConfig.shared.ui.showHeader {
      contactHeaders = [
        ContactHeadItem(
          name: localizable("validation_message"),
          imageName: "funValid",
          router: ValidationMessageRouter,
          color: UIColor(hexString: "#60CFA7")
        ),
        ContactHeadItem(
          name: localizable("blacklist"),
          imageName: "funBlackName",
          router: ContactBlackListRouter,
          color: UIColor(hexString: "#53C3F3")
        ),
      ]

      if IMKitClient.instance.getConfigCenter().teamEnable {
        contactHeaders.append(ContactHeadItem(
          name: localizable("mine_groupchat"),
          imageName: "funGroup",
          router: ContactTeamListRouter,
          color: UIColor(hexString: "#BE65D9")
        ))
      }

      if let headerDataCallback = NEKitContactConfig.shared.ui.headerData {
        headerDataCallback(contactHeaders)
      }
    }
    viewModel = ContactViewModel(contactHeaders: contactHeaders)
    cellRegisterDic = [
      ContactCellType.ContactPerson.rawValue: FunContactTableViewCell.self,
      ContactCellType.ContactOthers.rawValue: FunContactTableViewCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    if let searchViewGestures = searchView.gestureRecognizers {
      searchViewGestures.forEach { gesture in
        searchView.removeGestureRecognizer(gesture)
      }
    }
  }

  override open func commonUI() {
    super.commonUI()
    view.backgroundColor = .funContactBackgroundColor

    let tap = UITapGestureRecognizer(target: self, action: #selector(searchAction))
    tap.cancelsTouchesInView = false
    searchView.addGestureRecognizer(tap)
    bodyTopView.addSubview(searchView)
    bodyTopViewHeight = 60
    NSLayoutConstraint.activate([
      searchView.topAnchor.constraint(equalTo: bodyTopView.topAnchor, constant: 12),
      searchView.leftAnchor.constraint(equalTo: bodyTopView.leftAnchor, constant: 8),
      searchView.rightAnchor.constraint(equalTo: bodyTopView.rightAnchor, constant: -8),
      searchView.heightAnchor.constraint(equalToConstant: 36),
    ])

    tableView.backgroundColor = .clear

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    cellRegisterDic.forEach { (key: Int, value: NEBaseContactTableViewCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    var reusedId = "\(info.contactCellType)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? FunContactTableViewCell {
      return configCell(info: info, c, indexPath)
    }
    return cell
  }

  override open func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView? {
    if let sectionView = super.tableView(tableView, viewForHeaderInSection: section) as? ContactSectionView {
      sectionView.line.isHidden = true
      return sectionView
    }
    return nil
  }

  override open func tableView(_ tableView: UITableView,
                               heightForRowAt indexPath: IndexPath) -> CGFloat {
    64
  }

  override open func getFindFriendViewController() -> NEBaseFindFriendViewController {
    FunFindFriendViewController()
  }
}

extension FunContactsViewController {
  override open func initSystemNav() {
    edgesForExtendedLayout = []
    let addItem = UIBarButtonItem(
      image: NEKitContactConfig.shared.ui.titleBarRightRes ?? UIImage.ne_imageNamed(name: "funAdd"),
      style: .plain,
      target: self,
      action: #selector(goToFindFriend)
    )
    addItem.tintColor = UIColor(hexString: "333333")

    navigationItem.rightBarButtonItems = [addItem]
    navigationView.addBtn.setImage(UIImage.ne_imageNamed(name: "funAdd"), for: .normal)

    if !NEKitContactConfig.shared.ui.showTitleBarRightIcon {
      navigationItem.rightBarButtonItems = []
      navigationView.addBtn.isHidden = true
    }

    title = localizable("contact")
    navigationView.navigationTitle.text = localizable("contact")
    navigationView.backgroundColor = .funContactBackgroundColor
    navigationView.titleBarBottomLine.isHidden = true
    navigationView.brandBtn.isHidden = true
    navigationView.navigationTitle.isHidden = false
    navigationView.searchBtn.isHidden = true
  }
}
