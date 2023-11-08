// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class ContactsViewController: NEBaseContactsViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
    viewModel = ContactViewModel(contactHeaders: [
      ContactHeadItem(
        name: localizable("validation_message"),
        imageName: "valid",
        router: ValidationMessageRouter,
        color: UIColor(hexString: "#60CFA7")
      ),
      ContactHeadItem(
        name: localizable("blacklist"),
        imageName: "blackName",
        router: ContactBlackListRouter,
        color: UIColor(hexString: "#53C3F3")
      ),
      ContactHeadItem(
        name: localizable("mine_groupchat"),
        imageName: "group",
        router: ContactGroupRouter,
        color: UIColor(hexString: "#BE65D9")
      ),
    ])
    customCells = [
      ContactCellType.ContactPerson.rawValue: ContactTableViewCell.self,
      ContactCellType.ContactOthers.rawValue: ContactTableViewCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
  }

  override open func commonUI() {
    super.commonUI()

    NSLayoutConstraint.activate([
      topView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      topView.leftAnchor.constraint(equalTo: view.leftAnchor),
      topView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    customCells.forEach { (key: Int, value: NEBaseContactTableViewCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  override open func getFindFriendViewController() -> NEBaseFindFriendViewController {
    FindFriendViewController()
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    var reusedId = "\(info.contactCellType)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? ContactTableViewCell {
      return configCell(info: info, c, indexPath)
    }
    return cell
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
        let validationController = ValidationMessageViewController()
        validationController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(validationController, animated: true)
      case ContactBlackListRouter:
        let blackVC = BlackListViewController()
        blackVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(blackVC, animated: true)

      case ContactGroupRouter:
        // My Team
        let teamVC = TeamListViewController()
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
      let userInfoVC = ContactUserViewController(user: info.user)
      userInfoVC.hidesBottomBarWhenPushed = true
      navigationController?.pushViewController(userInfoVC, animated: true)
    }
  }
}

extension ContactsViewController {
  override open func initSystemNav() {
    super.initSystemNav()
    let addItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "add"),
      style: .plain,
      target: self,
      action: #selector(goToFindFriend)
    )
    addItem.tintColor = UIColor(hexString: "333333")
    let searchItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "contact_search"),
      style: .plain,
      target: self,
      action: #selector(searchContact)
    )
    searchItem.imageInsets = UIEdgeInsets(top: 0, left: 35, bottom: 0, right: 0)
    searchItem.tintColor = UIColor(hexString: "333333")

    navigationItem.rightBarButtonItems = [addItem, searchItem]
    if NEKitContactConfig.shared.ui.hiddenSearchBtn {
      navigationItem.rightBarButtonItems = [addItem]
      navView.searchBtn.isHidden = true
    }
    if NEKitContactConfig.shared.ui.hiddenRightBtns {
      navigationItem.rightBarButtonItems = []
      navView.searchBtn.isHidden = true
      navView.addBtn.isHidden = true
    }

    let brandBarBtn = UIButton()
    brandBarBtn.setTitle(localizable("contact"), for: .normal)
    brandBarBtn.setTitleColor(UIColor.black, for: .normal)
    brandBarBtn.titleLabel?.font = NEConstant.textFont("PingFangSC-Medium", 20)
    let brandBtn = UIBarButtonItem(customView: brandBarBtn)
    navigationItem.leftBarButtonItem = brandBtn

    navView.brandBtn.setImage(nil, for: .normal)
    navView.brandBtn.setTitle(localizable("contact"), for: .normal)
    navView.brandBtn.titleEdgeInsets = UIEdgeInsets.zero
  }
}
