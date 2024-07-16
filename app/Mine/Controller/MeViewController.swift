
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

class MeViewController: UIViewController, UIGestureRecognizerDelegate {
  private var mineData = [
    [NSLocalizedString("setting", comment: ""): "mine_setting"],
    [NSLocalizedString("about_yunxin", comment: ""): "about_yunxin"],
  ]

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      MineTableViewCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(MineTableViewCell.self))"
    )
    tableView.rowHeight = 52
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

  private lazy var arrowImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.accessibilityIdentifier = "id.rightArrow"
    return imageView
  }()

  private lazy var personInfoButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(personInfoButtonClick), for: .touchUpInside)
    return button
  }()

  @objc func personInfoButtonClick(sender: UIButton) {
    let personInfo = PersonInfoViewController()
    navigationController?.pushViewController(personInfo, animated: true)
  }

  lazy var headerView: UIView = {
    let view = UIView(frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    return view
  }()

  lazy var header: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.font = UIFont.systemFont(ofSize: 22.0)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  lazy var nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textColor = .ne_darkText
    nameLabel.font = UIFont.systemFont(ofSize: 22.0)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.accessibilityIdentifier = "id.name"
    return nameLabel
  }()

  lazy var idLabel: UILabel = {
    let label = UILabel()
    label.textColor = .ne_darkText
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.account"
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NEStyleManager.instance.isNormalStyle() ? UIColor(hexString: "#EFF1F4") : UIColor(hexString: "#EDEDED")
    setupSubviews()
    if IMKitConfigCenter.shared.enableCollectionMessage {
      mineData.insert([NSLocalizedString("mine_collection", comment: ""): "mine_collection"], at: 1)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    navigationController?.setNavigationBarHidden(true, animated: false)
    updateUserInfo()
    super.viewWillAppear(animated)
    if navigationController?.viewControllers.count ?? 0 > 0 {
      if let root = navigationController?.viewControllers[0] as? UIViewController {
        if root.isKind(of: MeViewController.self) {
          navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
      }
    }
  }

  func setupSubviews() {
    // 顶部视图
    view.addSubview(header)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        header.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        header.topAnchor.constraint(
          equalTo: self.view.safeAreaLayoutGuide.topAnchor,
          constant: 32
        ),
        header.widthAnchor.constraint(equalToConstant: 60),
        header.heightAnchor.constraint(equalToConstant: 60),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        header.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        header.topAnchor.constraint(equalTo: view.topAnchor, constant: 32),
        header.widthAnchor.constraint(equalToConstant: 60),
        header.heightAnchor.constraint(equalToConstant: 60),
      ])
    }
    header.clipsToBounds = true
    if NEStyleManager.instance.isNormalStyle() {
      header.layer.cornerRadius = 30
    } else {
      header.layer.cornerRadius = 4
    }

    view.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: header.rightAnchor, constant: 15),
      nameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
      nameLabel.topAnchor.constraint(equalTo: header.topAnchor),
    ])

    view.addSubview(idLabel)
    NSLayoutConstraint.activate([
      idLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
      idLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
      idLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
    ])

    // 更新个人信息
    updateUserInfo()

    let divider = UIView()
    view.addSubview(divider)
    divider.translatesAutoresizingMaskIntoConstraints = false
    divider.backgroundColor = .clear
    NSLayoutConstraint.activate([
      divider.leftAnchor.constraint(equalTo: view.leftAnchor),
      divider.heightAnchor.constraint(equalToConstant: 6),
      divider.rightAnchor.constraint(equalTo: view.rightAnchor),
      divider.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 32),
    ])

    view.addSubview(tableView)
    view.addSubview(arrowImageView)
    view.addSubview(personInfoButton)

    tableView.backgroundColor = NEStyleManager.instance.isNormalStyle() ? UIColor.white : UIColor.clear
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: divider.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      arrowImageView.centerYAnchor.constraint(equalTo: header.centerYAnchor),
      arrowImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
    ])

    NSLayoutConstraint.activate([
      personInfoButton.topAnchor.constraint(equalTo: header.topAnchor),
      personInfoButton.leftAnchor.constraint(equalTo: view.leftAnchor),
      personInfoButton.rightAnchor.constraint(equalTo: view.rightAnchor),
      personInfoButton.bottomAnchor.constraint(equalTo: divider.topAnchor),
    ])

    view.insertSubview(headerView, belowSubview: header)
    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.topAnchor),
      headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
      headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
      headerView.bottomAnchor.constraint(equalTo: divider.topAnchor),
    ])
  }

  func setupUserInfo(_ userFriend: NEUserWithFriend?) {
    idLabel.text = "\(NSLocalizedString("account", comment: "")):\(userFriend?.user?.accountId ?? "")"
    nameLabel.text = userFriend?.showName()
    header.configHeadData(headUrl: userFriend?.user?.avatar,
                          name: userFriend?.showName() ?? "",
                          uid: userFriend?.user?.accountId ?? "")
  }

  func updateUserInfo() {
    if let userFriend = NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) {
      setupUserInfo(userFriend)
    } else {
      ContactRepo.shared.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { [weak self] users, error in
        self?.setupUserInfo(users?.first)
      }
    }
  }
}

extension MeViewController: UITableViewDelegate, UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    mineData.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(MineTableViewCell.self))",
      for: indexPath
    ) as? MineTableViewCell {
      let cellTitle = mineData[indexPath.row]
      cell.configCell(data: cellTitle)
      return cell
    }
    return MineTableViewCell()
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if IMKitConfigCenter.shared.enableCollectionMessage {
      if indexPath.row == 0 {
        let ctrl = MineSettingViewController()
        navigationController?.pushViewController(ctrl, animated: true)
      } else if indexPath.row == 1 {
        if NEStyleManager.instance.isNormalStyle() == true {
          let collectionCtrl = CollectionMessageController()
          navigationController?.pushViewController(collectionCtrl, animated: true)
        } else {
          let collectionCtrl = FunCollectionMessageController()
          navigationController?.pushViewController(collectionCtrl, animated: true)
        }
      } else if indexPath.row == 2 {
        let ctrl = IntroduceBrandViewController()
        navigationController?.pushViewController(ctrl, animated: true)
      }
    } else {
      if indexPath.row == 0 {
        let ctrl = MineSettingViewController()
        navigationController?.pushViewController(ctrl, animated: true)
      } else if indexPath.row == 1 {
        let ctrl = IntroduceBrandViewController()
        navigationController?.pushViewController(ctrl, animated: true)
      }
    }
  }

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let navigationController = navigationController,
       navigationController.responds(to: #selector(getter: UINavigationController.interactivePopGestureRecognizer)),
       gestureRecognizer == navigationController.interactivePopGestureRecognizer,
       navigationController.visibleViewController == navigationController.viewControllers.first {
      return false
    }
    return true
  }
}
