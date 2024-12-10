// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseValidationMessageViewController: NEContactBaseViewController {
  public let viewModel = ValidationMessageViewModel()
  public var tableViewTopAnchor: NSLayoutConstraint?

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableViewTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    viewModel.delegate = self
    loadData()

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewModel.setAddApplicationRead(nil)
  }

  /// 返回上一级页面
  override open func backEvent() {
    super.backEvent()
    viewModel.setAddApplicationRead(nil)
  }

  /// 进入后台，清空未读
  func appEnterBackground() {
    viewModel.setAddApplicationRead { [weak self] success, error in
      if success {
        self?.tableviewReload()
      }
    }
  }

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
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

  /// 加载数据
  func loadData() {
    viewModel.loadApplicationList(true) { [weak self] error in
      if let err = error {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "loadApplicationList CALLBACK error: \(err.localizedDescription)")
      } else {
        self?.emptyView.isHidden = (self?.viewModel.friendAddApplications.count ?? 0) > 0
      }
    }
  }

  func initNav() {
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(toSetting)
    )
    clearItem.tintColor = UIColor(hexString: "666666")
    var textAttributes = [NSAttributedString.Key: Any]()
    textAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    navigationView.setMoreButtonTitle(localizable("clear"))
    navigationView.setMoreButtonWidth(NEAppLanguageUtil.getCurrentLanguage() == .english ? 60 : 34)
    navigationView.moreButton.setTitleColor(.ne_darkText, for: .normal)
  }

  /// 控件初始化
  open func setupUI() {
    title = localizable("validation_message")
    initNav()

    view.addSubview(tableView)
    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.setText(localizable("no_validation_message"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  /// 清空好友申请
  override open func toSetting() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    viewModel.clearNotification()
    emptyView.isHidden = viewModel.friendAddApplications.count > 0
    tableView.reloadData()
  }

  open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension NEBaseValidationMessageViewController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.friendAddApplications.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    60
  }
}

// MARK: - ValidationMessageViewModelDelegate

extension NEBaseValidationMessageViewController: ValidationMessageViewModelDelegate {
  public func tableviewReload() {
    tableView.reloadData()
    emptyView.isHidden = viewModel.friendAddApplications.count > 0
  }
}

// MARK: - SystemNotificationCellDelegate

extension NEBaseValidationMessageViewController: SystemNotificationCellDelegate {
  /// 同意好友申请
  /// - Parameter notifiModel: 申请模型
  open func onAccept(_ notifiModel: NENotification) {
    weak var weakSelf = self
    let info = notifiModel.v2Notification

    viewModel.agreeRequest(application: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
        case friendAlreadyExist:
          weakSelf?.viewModel.changeApplicationStatus(info, .FRIEND_ADD_APPLICATION_STATUS_AGREED)
          weakSelf?.showToast(localizable("validate_processed"))
          weakSelf?.tableviewReload()
        default:
          weakSelf?.showToast(commonLocalizable("failed_operation"))
        }
      } else {
        weakSelf?.tableviewReload()
      }
    }
  }

  /// 拒绝好友申请
  /// - Parameter notifiModel: 申请模型
  open func onRefuse(_ notifiModel: NENotification) {
    weak var weakSelf = self
    let info = notifiModel.v2Notification

    viewModel.refuseRequest(application: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
        case friendAlreadyExist:
          weakSelf?.viewModel.changeApplicationStatus(info, .FRIEND_ADD_APPLICATION_STATUS_AGREED)
          weakSelf?.showToast(localizable("validate_processed"))
          weakSelf?.tableviewReload()
        default:
          weakSelf?.showToast(commonLocalizable("failed_operation"))
        }
      } else {
        weakSelf?.tableviewReload()
      }
    }
  }
}
