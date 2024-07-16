// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import NETeamUIKit
import UIKit

class IntroduceBrandViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  private var viewModel = IntroduceViewModel()

  /// 网易云信IM Logo
  private lazy var headImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "yunxin_logo"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.accessibilityIdentifier = "id.aboutLogo"
    return imageView
  }()

  /// 网易云信  文本
  private lazy var headLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = NSLocalizedString("brand_des", comment: "")
    label.font = UIFont.systemFont(ofSize: 20.0)
    label.textColor = UIColor(hexString: "333333")
    label.accessibilityIdentifier = "id.aboutApp"
    return label
  }()

  /// 内容列表控件
  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .white
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none
    tableView.register(VersionCell.self, forCellReuseIdentifier: "VersionCell")
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

  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.getData()
    setupSubviews()
  }

  /// UI 初始化
  func setupSubviews() {
    view.addSubview(headImageView)
    view.addSubview(headLabel)
    view.addSubview(tableView)
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.moreButton.isHidden = true
    NSLayoutConstraint.activate([
      headImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      headImageView.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: topConstant + 20
      ),
      headImageView.widthAnchor.constraint(equalToConstant: 72),
      headImageView.heightAnchor.constraint(equalToConstant: 53),
    ])

    NSLayoutConstraint.activate([
      headLabel.centerXAnchor.constraint(equalTo: headImageView.centerXAnchor),
      headLabel.topAnchor.constraint(equalTo: headImageView.bottomAnchor, constant: 10),
    ])

    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: headImageView.bottomAnchor, constant: 45),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.sectionData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.sectionData[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "VersionCell",
      for: indexPath
    ) as? VersionCell {
      cell.configData(model: model)
      if indexPath.row == 0 || indexPath.row == 1 {
        cell.cellType = .version
      } else {
        cell.cellType = .productIntroduce
      }
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 2 {
      let ctrl = NEAboutWebViewController(url: "https://netease.im/m/")
      navigationController?.pushViewController(ctrl, animated: true)
    }
  }
}
