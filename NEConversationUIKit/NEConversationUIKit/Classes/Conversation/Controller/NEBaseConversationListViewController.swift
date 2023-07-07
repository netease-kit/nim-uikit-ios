// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objc
public protocol ConversationListViewControllerDelegate {
  func onDataLoaded()
}

@objcMembers
open class NEBaseConversationListViewController: UIViewController {
  public var viewModel = ConversationViewModel()
  var className = "ConversationListViewController"
  public var networkToolHeight: CGFloat = 36
  public var topViewHeight: CGFloat = 0 {
    didSet {
      topViewHeightAnchor?.constant = brokenNetworkView.isHidden ? topViewHeight : networkToolHeight
      topView.isHidden = topViewHeight <= 0
    }
  }

  public var deleteBottonColor: UIColor = NEConstant.hexRGB(0xA8ABB6)
  public var topViewHeightAnchor: NSLayoutConstraint?
  public var delegate: ConversationListViewControllerDelegate?

  public var registerCellDic = [0: NEBaseConversationListCell.self]

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    requestData()
    initialConfig()
  }

  override open func viewWillAppear(_ animated: Bool) {
    weak var weakSelf = self

    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable {
        weakSelf?.brokenNetworkView.isHidden = false
        weakSelf?.topView.isHidden = true
        weakSelf?.topViewHeightAnchor?.constant = weakSelf?.networkToolHeight ?? 0
      } else {
        weakSelf?.brokenNetworkView.isHidden = true
        weakSelf?.topView.isHidden = false
        weakSelf?.topViewHeightAnchor?.constant = weakSelf?.topViewHeight ?? 0
      }
    }

    viewModel.loadStickTopSessionInfos { error, sessionInfos in
      NELog.infoLog(
        ModuleName + " " + self.className,
        desc: "CALLBACK loadStickTopSessionInfos " + (error?.localizedDescription ?? "no error")
      )
      if let infos = sessionInfos {
        weakSelf?.viewModel.stickTopInfos = infos
        weakSelf?.reloadTableView()
        weakSelf?.delegate?.onDataLoaded()
      }
    }
  }

  open func initialConfig() {
    viewModel.delegate = self
  }

  open func setupSubviews() {
    view.addSubview(topView)
    view.addSubview(tableView)
    view.addSubview(emptyView)
    view.addSubview(brokenNetworkView)

    NSLayoutConstraint.activate([
      topView.rightAnchor.constraint(equalTo: view.rightAnchor),
      topView.leftAnchor.constraint(equalTo: view.leftAnchor),
      topView.topAnchor.constraint(equalTo: view.topAnchor),

    ])
    topViewHeightAnchor = topView.heightAnchor.constraint(equalToConstant: topViewHeight)
    topViewHeightAnchor?.isActive = true

    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.topAnchor.constraint(equalTo: topView.bottomAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    registerCellDic.forEach { (key: Int, value: NEBaseConversationListCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])
  }

  func requestData() {
    let params = NIMFetchServerSessionOption()
    params.minTimestamp = 0
    params.maxTimestamp = Date().timeIntervalSince1970 * 1000
    params.limit = 50
    weak var weakSelf = self
    viewModel.fetchServerSessions(option: params) { error, recentSessions in
      if error == nil {
        NELog.infoLog(ModuleName + " " + self.className, desc: "✅CALLBACK fetchServerSessions SUCCESS")
        if let recentList = recentSessions {
          NELog.infoLog(ModuleName + " " + self.className, desc: "✅CALLBACK fetchServerSessions SUCCESS count : \(recentList.count)")
          if recentList.count > 0 {
            weakSelf?.emptyView.isHidden = true
            weakSelf?.reloadTableView()
            weakSelf?.delegate?.onDataLoaded()
          } else {
            weakSelf?.emptyView.isHidden = false
          }
        }

      } else {
        NELog.errorLog(
          ModuleName + " " + self.className,
          desc: "❌CALLBACK fetchServerSessions failed，error = \(error!)"
        )
        weakSelf?.emptyView.isHidden = false
      }
    }
  }

  // MARK: lazy method

  public lazy var topView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  public lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view =
      NEBrokenNetworkView(frame: CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: networkToolHeight))
    view.isHidden = true
    return view
  }()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: localizable("session_empty"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    view.backgroundColor = .clear
    return view

  }()
}

// MARK: ====================== private method===========================

extension NEBaseConversationListViewController {
  private func onTopRecentAtIndexPath(rencent: NIMRecentSession, indexPath: IndexPath,
                                      isTop: Bool,
                                      _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                        -> Void) {
    guard let session = rencent.session else {
      NELog.errorLog(ModuleName + " " + className, desc: "❌session is nil")
      return
    }
    weak var weakSelf = self
    if isTop {
      guard let params = viewModel.stickTopInfos[session] else {
        return
      }

      viewModel.removeStickTopSession(params: params) { error, topSessionInfo in
        if let err = error {
          NELog.errorLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationListViewController"),
            desc: "❌CALLBACK removeStickTopSession failed，error = \(err)"
          )
          completion(error as NSError?, nil)

          return
        } else {
          NELog.infoLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationListViewController"),
            desc: "✅CALLBACK removeStickTopSession SUCCESS"
          )
          weakSelf?.viewModel.stickTopInfos[session] = nil
          weakSelf?.viewModel.sortRecentSession()
          weakSelf?.tableView.reloadData()
          completion(nil, topSessionInfo)
        }
      }

    } else {
      viewModel.addStickTopSession(session: session) { error, newInfo in
        if let err = error {
          NELog.errorLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationListViewController"),
            desc: "❌CALLBACK addStickTopSession failed，error = \(err)"
          )
          completion(error as NSError?, nil)
          return
        } else {
          NELog.infoLog(ModuleName + " " + (weakSelf?.className ?? "ConversationListViewController"),
                        desc: "✅CALLBACK addStickTopSession callback SUCCESS")
          weakSelf?.viewModel.stickTopInfos[session] = newInfo
          weakSelf?.viewModel.sortRecentSession()
          weakSelf?.tableView.reloadData()
          completion(nil, newInfo)
        }
      }
    }
  }
}

extension NEBaseConversationListViewController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = viewModel.conversationListArray?.count ?? 0
    NELog.infoLog(ModuleName + " " + "ConversationListViewController",
                  desc: "numberOfRowsInSection count : \(count)")
    return count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.conversationListArray?[indexPath.row]
    let reusedId = "\(model?.customType ?? 0)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? NEBaseConversationListCell {
      c.topStickInfos = viewModel.stickTopInfos
      c.configData(sessionModel: model)
    }

    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let conversationModel = viewModel.conversationListArray?[indexPath.row]

    guard let sid = conversationModel?.recentSession?.session?.sessionId else {
      return
    }
    guard let sessionType = conversationModel?.recentSession?.session?.sessionType else {
      return
    }
    onselectedTableRow(sessionType: sessionType, sessionId: sid, indexPath: indexPath)
  }

  open func tableView(_ tableView: UITableView,
                      editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    weak var weakSelf = self
    var rowActions = [UITableViewRowAction]()

    let conversationModel = weakSelf?.viewModel.conversationListArray?[indexPath.row]
    guard let recentSession = conversationModel?.recentSession,
          let session = recentSession.session else {
      return rowActions
    }

    let deleteAction = UITableViewRowAction(style: .destructive,
                                            title: NEKitConversationConfig.shared.ui.deleteBottonTitle) { action, indexPath in
      weakSelf?.deleteActionHandler(action: action, indexPath: indexPath)
    }

    // 置顶和取消置顶
    let isTop = viewModel.stickTopInfos[session] != nil
    let topAction = UITableViewRowAction(style: .destructive,
                                         title: isTop ? NEKitConversationConfig.shared.ui.stickTopBottonCancelTitle :
                                           NEKitConversationConfig.shared.ui.stickTopBottonTitle) { action, indexPath in
      weakSelf?.topActionHandler(action: action, indexPath: indexPath, isTop: isTop)
    }
    deleteAction.backgroundColor = NEKitConversationConfig.shared.ui.deleteBottonColor ?? deleteBottonColor
    topAction.backgroundColor = NEKitConversationConfig.shared.ui.stickTopBottonColor
    rowActions.append(deleteAction)
    rowActions.append(topAction)

    return rowActions
  }

  /*
   @available(iOS 11.0, *)
   public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

   var rowActions = [UIContextualAction]()

   let deleteAction = UIContextualAction(style: .normal, title: "删除") { (action, sourceView, completionHandler) in

   //            self.dataSource.remove(at: indexPath.row)
   //            tableView.deleteRows(at: [indexPath], with: .automatic)
   // 需要返回true，否则没有反应
   completionHandler(true)
   }
   deleteAction.backgroundColor = NEConstant.hexRGB(0xA8ABB6)
   rowActions.append(deleteAction)

   let topAction = UIContextualAction(style: .normal, title: "置顶") { (action, sourceView, completionHandler) in

   //            self.dataSource.remove(at: indexPath.row)
   //            tableView.deleteRows(at: [indexPath], with: .automatic)
   // 需要返回true，否则没有反应
   completionHandler(true)
   }
   topAction.backgroundColor = NEConstant.hexRGB(0x337EFF)
   rowActions.append(topAction)

   let actionConfig = UISwipeActionsConfiguration.init(actions: rowActions)
   actionConfig.performsFirstActionWithFullSwipe = false

   return actionConfig
   }
   */

  open func deleteActionHandler(action: UITableViewRowAction?, indexPath: IndexPath) {
    let conversationModel = viewModel.conversationListArray?[indexPath.row]
    if let recentSession = conversationModel?.recentSession {
      viewModel.deleteRecentSession(recentSession: recentSession)
      didDeleteConversationCell(
        model: conversationModel ?? ConversationListModel(),
        indexPath: indexPath
      )
    }
  }

  open func topActionHandler(action: UITableViewRowAction?, indexPath: IndexPath, isTop: Bool) {
    if !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      showToast(localizable("network_error"))
      return
    }
    let conversationModel = viewModel.conversationListArray?[indexPath.row]
    if let recentSession = conversationModel?.recentSession {
      onTopRecentAtIndexPath(
        rencent: recentSession,
        indexPath: indexPath,
        isTop: isTop
      ) { [weak self] error, sessionInfo in
        if error == nil {
          if isTop {
            self?.didRemoveStickTopSession(
              model: conversationModel ?? ConversationListModel(),
              indexPath: indexPath
            )
          } else {
            self?.didAddStickTopSession(
              model: conversationModel ?? ConversationListModel(),
              indexPath: indexPath
            )
          }
        }
      }
    }
  }
}

// MARK: UI UIKit提供的重写方法

extension NEBaseConversationListViewController {
  /// cell点击事件,可重写该事件处理自己的逻辑业务，例如跳转到指定的会话页面
  /// - Parameters:
  ///   - sessionType: 会话类型
  ///   - sessionId: 会话id
  ///   - indexPath: indexpath
  open func onselectedTableRow(sessionType: NIMSessionType, sessionId: String,
                               indexPath: IndexPath) {
    if sessionType == .P2P {
      let session = NIMSession(sessionId, type: .P2P)
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any],
        closure: nil
      )
    } else if sessionType == .team {
      let session = NIMSession(sessionId, type: .team)
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any],
        closure: nil
      )
    }
  }

  /// 删除会话
  /// - Parameters:
  ///   - model: 会话模型
  ///   - indexPath: indexpath
  open func didDeleteConversationCell(model: ConversationListModel, indexPath: IndexPath) {}

  /// 删除一条置顶记录
  /// - Parameters:
  ///   - model: 会话模型
  ///   - indexPath: indexpath
  open func didRemoveStickTopSession(model: ConversationListModel, indexPath: IndexPath) {}

  /// 添加一条置顶记录
  /// - Parameters:
  ///   - model: 会话模型
  ///   - indexPath: indexpath
  open func didAddStickTopSession(model: ConversationListModel, indexPath: IndexPath) {}
}

// MARK: ================= ConversationViewModelDelegate===================

extension NEBaseConversationListViewController: ConversationViewModelDelegate {
  open func didAddRecentSession() {
    NELog.infoLog("ConversationListViewController", desc: "didAddRecentSession")
    emptyView.isHidden = (viewModel.conversationListArray?.count ?? 0) > 0
    viewModel.sortRecentSession()
    tableView.reloadData()
  }

  open func didUpdateRecentSession(index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView.reloadRows(at: [indexPath], with: .none)
  }

  open func reloadData() {
    delegate?.onDataLoaded()
  }

  open func reloadTableView() {
    emptyView.isHidden = (viewModel.conversationListArray?.count ?? 0) > 0
    viewModel.sortRecentSession()
    tableView.reloadData()
  }
}
