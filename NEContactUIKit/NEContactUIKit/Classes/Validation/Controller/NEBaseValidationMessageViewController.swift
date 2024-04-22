// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseValidationMessageViewController: NEBaseContactViewController {
  public let viewModel = ValidationMessageViewModel()

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadData()

    weak var weakSelf = self
    viewModel.dataRefresh = {
      weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.datas.count ?? 0) > 0
      weakSelf?.tableView.reloadData()
    }

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewModel.setAddApplicationRead(nil)
  }

  /// 返回上一级页面
  override open func backToPrevious() {
    super.backToPrevious()
    viewModel.setAddApplicationRead(nil)
  }

  /// 进入后台，清空未读
  func appEnterBackground() {
    viewModel.setAddApplicationRead { [weak self] success, error in
      if success {
        self?.loadData()
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

    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadData)
    )
    return tableView
  }()

  /// 表格添加底部 loading
  func addBottomLoadMore() {
    let footer = MJRefreshAutoFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    footer.triggerAutomaticallyRefreshPercent = -10
    tableView.mj_footer = footer
  }

  /// 表格移除底部 loading
  func removeBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil
  }

  /// 加载数据
  func loadData() {
    viewModel.loadApplicationList(true) { [weak self] finished, error in
      if let err = error {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "loadApplicationList CALLBACK error: \(err.localizedDescription)")
      } else {
        if finished {
          self?.removeBottomLoadMore()
        } else {
          self?.addBottomLoadMore()
        }

        self?.tableView.mj_header?.endRefreshing()
        self?.emptyView.isHidden = (self?.viewModel.datas.count ?? 0) > 0
        self?.tableView.reloadData()
      }
    }
  }

  /// 加载更多
  func loadMoreData() {
    viewModel.loadApplicationList(false) { [weak self] finished, error in
      if let err = error {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "loadMoreApplicationList CALLBACK error: \(err.localizedDescription)")
      } else {
        if finished {
          self?.removeBottomLoadMore()
        } else {
          self?.addBottomLoadMore()
        }

        self?.tableView.mj_footer?.endRefreshing()
        self?.tableView.reloadData()
      }
    }
  }

  /// 控件初始化
  open func setupUI() {
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(clearMessage)
    )
    clearItem.tintColor = UIColor(hexString: "666666")
    var textAttributes = [NSAttributedString.Key: Any]()
    textAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    title = localizable("validation_message")
    navigationView.navTitle.text = title
    navigationView.setMoreButtonTitle(localizable("clear"))
    navigationView.moreButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(clearMessage))

    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyView.settingContent(content: localizable("no_validation_message"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  /// 清空好友申请
  func clearMessage() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    viewModel.clearNotification()
  }

  open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }
}

extension NEBaseValidationMessageViewController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.datas.count
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

extension NEBaseValidationMessageViewController: SystemNotificationCellDelegate {
  /// 处理好友申请
  /// - Parameters:
  ///   - notifiModel: 申请模型
  ///   - notiStatus: 处理状态
  public func changeValidationStatus(notifiModel: NENotification, notiStatus: NEHandleStatus) {
    notifiModel.handleStatus = notiStatus
    notifiModel.unReadCount = 0
    for msg in notifiModel.msgList ?? [] {
      msg.handleStatus = notiStatus
    }

    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }

  /// 同意好友申请
  /// - Parameter notifiModel: 申请模型
  open func onAccept(_ notifiModel: NENotification) {
    weak var weakSelf = self
    guard let info = notifiModel.v2Notification else {
      return
    }

    viewModel.agreeRequest(application: info) { error in
      if let err = error as? NSError, err.code != friendAlreadyExist {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
        default:
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeOk)
        weakSelf?.viewModel.setAddApplicationRead(nil)

        if let accid = info.operatorAccountId, let conversationId = V2NIMConversationIdUtil.p2pConversationId(accid) {
          Router.shared.use(ChatAddFriendRouter, parameters: ["text": localizable("let_us_chat"),
                                                              "conversationId": conversationId as Any])
        }
      }
    }
  }

  /// 拒绝好友申请
  /// - Parameter notifiModel: 申请模型
  open func onRefuse(_ notifiModel: NENotification) {
    weak var weakSelf = self
    guard let info = notifiModel.v2Notification else {
      return
    }

    viewModel.refuseRequest(application: info) { error in
      if let err = error as? NSError {
        NEALog.errorLog(ModuleName + " " + NEBaseValidationMessageViewController.className(), desc: "CALLBACK agreeRequest failed,error = \(err.localizedDescription)")
        switch err.code {
        case protocolSendFailed:
          weakSelf?.showToast(commonLocalizable("network_error"))
        case friendAlreadyExist:
          weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeOk)
          weakSelf?.showToast(localizable("validate_processed"))
        default:
          weakSelf?.showToast(localizable("failed_operation"))
        }
      } else {
        weakSelf?.changeValidationStatus(notifiModel: notifiModel, notiStatus: .HandleTypeNo)
        weakSelf?.viewModel.setAddApplicationRead(nil)
      }
    }
  }
}
