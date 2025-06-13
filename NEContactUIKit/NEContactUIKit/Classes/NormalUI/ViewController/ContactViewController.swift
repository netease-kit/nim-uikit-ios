// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreKit
import UIKit

@objcMembers
open class ContactViewController: NEBaseContactViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
    cellRegisterDic = [
      ContactCellType.ContactPerson.rawValue: ContactTableViewCell.self,
      ContactCellType.ContactOthers.rawValue: ContactTableViewCell.self,
    ]
    NotificationCenter.default.addObserver(self, selector: #selector(changeLanguage), name: NENotificationName.changeLanguage, object: nil)
    changeLanguage()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      NotificationCenter.default.removeObserver(self)
    }
  }

  open func changeLanguage() {
    var contactHeaders = [ContactHeadItem]()
    if ContactUIConfig.shared.showHeader {
      contactHeaders = [
        ContactHeadItem(
          router: ValidationMessageRouter,
          name: localizable("validation_message"),
          imageName: "valid_message"
        ),
        ContactHeadItem(
          router: ContactBlackListRouter,
          name: localizable("blacklist"),
          imageName: "blacklist"
        ),
      ]

      if IMKitConfigCenter.shared.enableTeam {
        contactHeaders.append(ContactHeadItem(
          router: ContactTeamListRouter,
          name: localizable("my_teams"),
          imageName: "group"
        ))
      }

      if IMKitConfigCenter.shared.enableAIUser {
        contactHeaders.append(ContactHeadItem(
          router: ContactAIUserListRouter,
          name: localizable("my_ai_user"),
          imageName: "ai_user"
        ))
      }

      if let headerDataCallback = ContactUIConfig.shared.headerData {
        headerDataCallback(self, &contactHeaders)
      }
    }
    viewModel = ContactViewModel(contactHeaders: contactHeaders)
    initSystemNav()
  }

  override open func commonUI() {
    super.commonUI()
    view.backgroundColor = .normalContactBackgroundColor
    bodyTopView.backgroundColor = .normalContactBodyTopViewBackgroundColor
    bodyView.backgroundColor = .normalContactBodyViewBackgroundColor
    tableView.backgroundColor = .normalContactTableViewBackgroundColor
    tableView.sectionIndexColor = .normalContactTableViewSectionIndexColor
    bodyBottomView.backgroundColor = .normalContactBodyBottomViewBackgroundColor

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    for (key, value) in cellRegisterDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  override open func getFindFriendViewController() -> NEBaseFindFriendViewController {
    FindFriendViewController()
  }

  override open func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView? {
    if let sectionView = super.tableView(tableView, viewForHeaderInSection: section) as? ContactSectionView {
      sectionView.backView.backgroundColor = .normalContactSectionViewBackgroundColor
      sectionView.line.backgroundColor = .normalContactSectionViewLineColor
      sectionView.titleLabel.textColor = .normalContactSectionViewTitleLabelTextColor
      return sectionView
    }
    return nil
  }
}

extension ContactViewController {
  override open func initSystemNav() {
    super.initSystemNav()
    let addItem = UIBarButtonItem(
      image: ContactUIConfig.shared.titleBarRightRes ?? coreLoader.loadImage("nav_add"),
      style: .plain,
      target: self,
      action: #selector(goToFindFriend)
    )
    addItem.tintColor = UIColor(hexString: "333333")
    let searchItem = UIBarButtonItem(
      image: ContactUIConfig.shared.titleBarRight2Res ?? coreLoader.loadImage("nav_search"),
      style: .plain,
      target: self,
      action: #selector(searchContact)
    )
    searchItem.imageInsets = UIEdgeInsets(top: 0, left: 35, bottom: 0, right: 0)
    searchItem.tintColor = UIColor(hexString: "333333")

    navigationItem.rightBarButtonItems = [addItem, searchItem]
    if !ContactUIConfig.shared.showTitleBarRight2Icon {
      navigationItem.rightBarButtonItems = [addItem]
      navigationView.searchBtn.isHidden = true
    }
    if !ContactUIConfig.shared.showTitleBarRightIcon {
      navigationItem.rightBarButtonItems = [searchItem]
      navigationView.addBtn.isHidden = true
    }

    let brandBarBtn = UIButton()
    brandBarBtn.setTitle(ContactUIConfig.shared.title ?? localizable("contact"), for: .normal)
    brandBarBtn.setTitleColor(ContactUIConfig.shared.titleColor ?? UIColor.black, for: .normal)
    brandBarBtn.titleLabel?.font = NEConstant.textFont("PingFangSC-Medium", 20)
    let brandBtn = UIBarButtonItem(customView: brandBarBtn)
    navigationItem.leftBarButtonItem = brandBtn

    navigationView.brandBtn.setImage(nil, for: .normal)
    navigationView.brandBtn.setTitle(ContactUIConfig.shared.title ?? localizable("contact"), for: .normal)
    navigationView.brandBtn.setTitleColor(ContactUIConfig.shared.titleColor ?? UIColor.black, for: .normal)
    navigationView.brandBtn.titleEdgeInsets = UIEdgeInsets.zero
    navigationView.backgroundColor = .normalContactNavigationBackgroundColor
    navigationView.titleBarBottomLine.backgroundColor = .normalContactNavigationDivideBg
  }
}
