// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseAddApplicationViewController: NEContactBaseViewController {
  public let viewModel = AddApplicationViewModel()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    title = localizable("contact_friend")
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    title = localizable("contact_friend")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.removeFromSuperview()
    topConstant = 0

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
  override open func appEnterBackground() {
    super.appEnterBackground()
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

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }

    return tableView
  }()

  /// 加载数据
  open func loadData() {
    viewModel.loadApplicationList(true) { [weak self] error in
      if let err = error {
        NEALog.errorLog(ModuleName + " " + NEBaseAddApplicationViewController.className(), desc: "loadApplicationList CALLBACK error: \(err.localizedDescription)")
      } else {
        self?.emptyView.isHidden = (self?.viewModel.friendAddApplications.count ?? 0) > 0
      }
    }
  }

  /// 控件初始化
  open func setupUI() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.setText(localizable("no_add_application"))
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
    guard view.isVisibleInWindow else {
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    showAlert(message: localizable("clear_all_add_application")) { [weak self] in
      self?.viewModel.clearNotification { error in
        self?.emptyView.isHidden = (self?.viewModel.friendAddApplications.count ?? 0) > 0
        self?.tableView.reloadData()
      }
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension NEBaseAddApplicationViewController: UITableViewDelegate, UITableViewDataSource {
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

// MARK: - AddApplicationViewModelDelegate

extension NEBaseAddApplicationViewController: AddApplicationViewModelDelegate {
  open func tableviewReload() {
    tableView.reloadData()
    emptyView.isHidden = !viewModel.friendAddApplications.isEmpty
  }
}

// MARK: - SystemNotificationCellDelegate

extension NEBaseAddApplicationViewController: SystemNotificationCellDelegate {
  /// 同意好友申请
  /// - Parameter notifiModel: 申请模型
  open func onAccept(application: NEAddApplication) {
    weak var weakSelf = self
    let info = application.v2Notification

    viewModel.agreeRequest(application: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseAddApplicationViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
        case friendAlreadyExist:
          weakSelf?.viewModel.changeApplicationStatus(info, .FRIEND_ADD_APPLICATION_STATUS_AGREED)
          weakSelf?.showToast(localizable("verification_processed"))
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
  open func onRefuse(application: NEAddApplication) {
    weak var weakSelf = self
    let info = application.v2Notification

    viewModel.refuseRequest(application: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseAddApplicationViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
        case friendAlreadyExist:
          weakSelf?.viewModel.changeApplicationStatus(info, .FRIEND_ADD_APPLICATION_STATUS_AGREED)
          weakSelf?.showToast(localizable("verification_processed"))
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
