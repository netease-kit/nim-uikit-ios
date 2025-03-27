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
    view.searchButton.setImage(UIImage.ne_imageNamed(name: "funSearch"), for: .normal)
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

      if IMKitConfigCenter.shared.enableTeam {
        contactHeaders.append(ContactHeadItem(
          name: localizable("my_teams"),
          imageName: "funGroup",
          router: ContactTeamListRouter,
          color: UIColor(hexString: "#BE65D9")
        ))
      }

      if IMKitConfigCenter.shared.enableAIUser {
        contactHeaders.append(ContactHeadItem(
          name: localizable("my_ai_user"),
          imageName: "funAIUser",
          router: ContactAIUserListRouter,
          color: UIColor(hexString: "#BE65D9")
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

    for (key, value) in cellRegisterDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let info = viewModel.contacts[indexPath.section].contacts[indexPath.row]
    let reusedId = "\(info.contactCellType)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? FunContactTableViewCell {
      if IMKitConfigCenter.shared.onlineStatusEnable {
        if indexPath.section != 0 {
          c.avatarImageView.alpha = 0.5
          if let accountId = info.user?.user?.accountId {
            if let event = viewModel.onlineStatusDic[accountId] {
              if event.value == NIMSubscribeEventOnlineValue.login.rawValue {
                c.avatarImageView.alpha = 1.0
              }
            }
          }
        } else {
          c.avatarImageView.alpha = 1.0
        }
      }
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

extension FunContactViewController {
  override open func initSystemNav() {
    edgesForExtendedLayout = []
    let addItem = UIBarButtonItem(
      image: ContactUIConfig.shared.titleBarRightRes ?? UIImage.ne_imageNamed(name: "funAdd"),
      style: .plain,
      target: self,
      action: #selector(goToFindFriend)
    )
    addItem.tintColor = UIColor(hexString: "333333")

    navigationItem.rightBarButtonItems = [addItem]
    navigationView.addBtn.setImage(UIImage.ne_imageNamed(name: "funAdd"), for: .normal)

    if !ContactUIConfig.shared.showTitleBarRightIcon {
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
