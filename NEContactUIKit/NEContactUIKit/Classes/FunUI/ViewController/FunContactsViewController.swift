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
    viewModel = ContactViewModel(contactHeaders: [
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
      ContactHeadItem(
        name: localizable("mine_groupchat"),
        imageName: "funGroup",
        router: ContactGroupRouter,
        color: UIColor(hexString: "#BE65D9")
      ),
    ])
    customCells = [
      ContactCellType.ContactPerson.rawValue: FunContactTableViewCell.self,
      ContactCellType.ContactOthers.rawValue: FunContactTableViewCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funContactBackgroundColor
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

    let tap = UITapGestureRecognizer(target: self, action: #selector(searchAction))
    tap.cancelsTouchesInView = false
    searchView.addGestureRecognizer(tap)
    view.addSubview(searchView)
    NSLayoutConstraint.activate([
      searchView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 12),
      searchView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      searchView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
      searchView.heightAnchor.constraint(equalToConstant: 36),
    ])

    NSLayoutConstraint.activate([
      topView.topAnchor.constraint(equalTo: searchView.bottomAnchor, constant: 12),
      topView.leftAnchor.constraint(equalTo: view.leftAnchor),
      topView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    tableView.backgroundColor = .clear

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    customCells.forEach { (key: Int, value: NEBaseContactTableViewCell.Type) in
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

  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    if let callBack = clickCallBacks[info.contactCellType] {
      callBack(indexPath.row, indexPath.section)
      return
    }
    if info.contactCellType == ContactCellType.ContactOthers.rawValue {
      switch info.router {
      case ValidationMessageRouter:
        let validationController = FunValidationMessageViewController()
        validationController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(validationController, animated: true)
      case ContactBlackListRouter:
        let blackVC = FunBlackListViewController()
        blackVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(blackVC, animated: true)

      case ContactGroupRouter:
        // My Team
        let teamVC = FunTeamListViewController()
        teamVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(teamVC, animated: true)

      case ContactPersonRouter:

        break

      case ContactComputerRouter:
        //                let select = ContactsSelectedViewController()
        //                select.CallBack = { contacts in
        //                    print("select contacs : ", contacts)
        //                }
        //                select.hidesBottomBarWhenPushed = true
        //                self.navigationController?.pushViewController(select, animated: true)
        break
      default:
        break
      }
    } else {
      let userInfoVC = FunContactUserViewController(user: info.user)
      userInfoVC.hidesBottomBarWhenPushed = true
      navigationController?.pushViewController(userInfoVC, animated: true)
    }
  }

  override open func getFindFriendViewController() -> NEBaseFindFriendViewController {
    FunFindFriendViewController()
  }
}

extension FunContactsViewController {
  override open func initSystemNav() {
    edgesForExtendedLayout = []
    let addItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "funAdd"),
      style: .plain,
      target: self,
      action: #selector(goToFindFriend)
    )
    addItem.tintColor = UIColor(hexString: "333333")

    navigationItem.rightBarButtonItems = [addItem]
    navView.addBtn.setImage(UIImage.ne_imageNamed(name: "funAdd"), for: .normal)

    if NEKitContactConfig.shared.ui.hiddenRightBtns {
      navigationItem.rightBarButtonItems = []
      navView.addBtn.isHidden = true
    }

    title = localizable("contact")
    navView.navigationTitle.text = localizable("contact")
    navView.backgroundColor = .funContactBackgroundColor
    navView.bottomLine.isHidden = true
    navView.brandBtn.isHidden = true
    navView.navigationTitle.isHidden = false
    navView.searchBtn.isHidden = true
  }
}
