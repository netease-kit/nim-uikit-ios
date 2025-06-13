// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import UIKit

@objcMembers
open class FunContactViewController: NEBaseContactViewController {
  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchButton.setImage(coreLoader.loadImage("fun_search"), for: .normal)
    view.searchButton.setTitle(commonLocalizable("search"), for: .normal)
    return view
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
    cellRegisterDic = [
      ContactCellType.ContactPerson.rawValue: FunContactTableViewCell.self,
      ContactCellType.ContactOthers.rawValue: FunContactTableViewCell.self,
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
      if let searchViewGestures = searchView.gestureRecognizers {
        for gesture in searchViewGestures {
          searchView.removeGestureRecognizer(gesture)
        }
      }
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
          imageName: "fun_valid_message"
        ),
        ContactHeadItem(
          router: ContactBlackListRouter,
          name: localizable("blacklist"),
          imageName: "fun_blacklist"
        ),
      ]

      if IMKitConfigCenter.shared.enableTeam {
        contactHeaders.append(ContactHeadItem(
          router: ContactTeamListRouter,
          name: localizable("my_teams"),
          imageName: "fun_my_team"
        ))
      }

      if IMKitConfigCenter.shared.enableAIUser {
        contactHeaders.append(ContactHeadItem(
          router: ContactAIUserListRouter,
          name: localizable("my_ai_user"),
          imageName: "fun_ai_user"
        ))
      }

      if let headerDataCallback = ContactUIConfig.shared.headerData {
        headerDataCallback(self, &contactHeaders)
      }
    }
    viewModel = ContactViewModel(contactHeaders: contactHeaders)

    searchView.searchButton.setTitle(commonLocalizable("search"), for: .normal)
    initSystemNav()
  }

  override open func commonUI() {
    super.commonUI()
    view.backgroundColor = .funContactBackgroundColor
    bodyTopView.backgroundColor = .funContactBodyTopViewBackgroundColor
    bodyView.backgroundColor = .funContactBodyViewBackgroundColor
    tableView.backgroundColor = .funContactTableViewBackgroundColor
    tableView.sectionIndexColor = .funContactTableViewSectionIndexColor
    bodyBottomView.backgroundColor = .funContactBodyBottomViewBackgroundColor

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

    tableView.register(
      ContactSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
    )

    for (key, value) in cellRegisterDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView? {
    if let sectionView = super.tableView(tableView, viewForHeaderInSection: section) as? ContactSectionView {
      sectionView.line.isHidden = true
      sectionView.backView.backgroundColor = .funContactSectionViewBackgroundColor
      sectionView.titleLabel.textColor = .funContactSectionViewTitleLabelTextColor
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

extension FunContactViewController {
  override open func initSystemNav() {
    edgesForExtendedLayout = []

    if ContactUIConfig.shared.showTitleBarRightIcon {
      let addItem = UIBarButtonItem(
        image: ContactUIConfig.shared.titleBarRightRes ?? contactCoreLoader.loadImage("fun_nav_add"),
        style: .plain,
        target: self,
        action: #selector(goToFindFriend)
      )
      addItem.tintColor = UIColor(hexString: "333333")

      navigationItem.rightBarButtonItems = [addItem]
      navigationView.addBtn.setImage(ContactUIConfig.shared.titleBarRightRes ?? contactCoreLoader.loadImage("fun_nav_add"), for: .normal)
    } else {
      navigationView.addBtn.isHidden = true
    }

    title = localizable("contact")
    navigationView.navigationTitle.text = localizable("contact")
    navigationView.backgroundColor = .funContactNavigationBackgroundColor
    navigationView.titleBarBottomLine.isHidden = true
    navigationView.brandBtn.isHidden = true
    navigationView.navigationTitle.isHidden = false
    navigationView.searchBtn.isHidden = true
  }
}
