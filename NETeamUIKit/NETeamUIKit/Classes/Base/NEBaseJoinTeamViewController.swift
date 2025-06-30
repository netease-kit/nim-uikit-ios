
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseJoinTeamViewController: NETeamBaseViewController, UITextFieldDelegate {
  public let viewModel = JoinTeamViewModel()
  public let hasRequest = false

  /// 搜索输入框
  public let searchInput: UITextField = {
    let searchInput = UITextField()
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    searchInput.textColor = .ne_darkText
    searchInput.placeholder = localizable("input_team_id")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.clearButtonMode = .always
    searchInput.accessibilityIdentifier = "id.joinTeamAccount"
    return searchInput
  }()

  public var isRequesting = false

  public var searchBackViewTopAnchor: NSLayoutConstraint?

  /// 搜索背景
  public lazy var searchBackView: UIView = {
    let searchBackView = UIView()
    searchBackView.backgroundColor = UIColor(hexString: "F2F4F5")
    searchBackView.translatesAutoresizingMaskIntoConstraints = false
    searchBackView.clipsToBounds = true
    searchBackView.layer.cornerRadius = 4.0
    return searchBackView
  }()

  /// 搜索图片
  public lazy var searchImageView: UIImageView = {
    let searchImageView = UIImageView()
    searchImageView.image = coreLoader.loadImage("textField_search_icon")
    searchImageView.translatesAutoresizingMaskIntoConstraints = false
    return searchImageView
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    searchBackViewTopAnchor?.constant = 20 + topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = commonLocalizable("join_team")
    navigationView.moreButton.isHidden = true
    emptyView.setText(localizable("no_team_find"))
    setupUI()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
      self?.searchInput.becomeFirstResponder()
    }))
  }

  /// UI 初始化
  open func setupUI() {
    view.addSubview(searchBackView)
    searchBackViewTopAnchor = searchBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20 + topConstant)
    searchBackViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      searchBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBackView.heightAnchor.constraint(equalToConstant: 32),
    ])

    searchBackView.addSubview(searchImageView)
    NSLayoutConstraint.activate([
      searchImageView.centerYAnchor.constraint(equalTo: searchBackView.centerYAnchor),
      searchImageView.leftAnchor.constraint(equalTo: searchBackView.leftAnchor, constant: 18),
      searchImageView.widthAnchor.constraint(equalToConstant: 13),
      searchImageView.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBackView.addSubview(searchInput)
    searchInput.delegate = self

    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImageView.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBackView.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBackView.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBackView.bottomAnchor),
    ])

    if let clearButton = searchInput.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textFieldChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
      emptyView.widthAnchor.constraint(equalToConstant: 200),
      emptyView.heightAnchor.constraint(equalToConstant: 200),
    ])
  }

  open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text else {
      return false
    }
    if text.count <= 0 {
      return false
    }
    if hasRequest == false {
      startSearch(text)
    }
    return true
  }

  open func textFieldChange() {
    if let text = searchInput.text, text.count <= 0 {
      emptyView.isHidden = true
    }
  }

  open func startSearch(_ text: String) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if isRequesting == true {
      return
    }
    isRequesting = true

    weak var weakSelf = self
    viewModel.getTeamInfo(text) { team, error in
      weakSelf?.isRequesting = false
      NEALog.infoLog(
        "NEBaseJoinTeamViewController",
        desc: "CALLBACK getTeamInfo " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as? NSError {
        weakSelf?.emptyView.isHidden = false
      } else {
        if let team = team {
          // go to detail
          Router.shared.use(
            TeamDetailInfoPageRouter,
            parameters: ["nav": weakSelf?.navigationController as Any,
                         "team": team],
            closure: nil
          )
          weakSelf?.emptyView.isHidden = true
        } else {
          weakSelf?.emptyView.isHidden = false
        }
      }
    }
  }
}
