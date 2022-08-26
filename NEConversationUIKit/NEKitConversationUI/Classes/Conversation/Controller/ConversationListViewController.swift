
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class ConversationListViewController: UIViewController {
  private var viewModel = ConversationViewModel()
  private let className = "ConversationListViewController"
  private var tableViewTopConstraint: NSLayoutConstraint?

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    requestData()
    initialConfig()
  }

  override open func viewWillAppear(_ animated: Bool) {
    weak var weakSelf = self
    viewModel.loadStickTopSessionInfos { error, sessionInfos in
      if let infos = sessionInfos {
        weakSelf?.viewModel.stickTopInfos = infos
        weakSelf?.reloadTableView()
      }
    }
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable {
        weakSelf?.brokenNetworkView.isHidden = false
        weakSelf?.tableViewTopConstraint?.constant = 36
      } else {
        weakSelf?.brokenNetworkView.isHidden = true
        weakSelf?.tableViewTopConstraint?.constant = 0
      }
    }
  }

  open func initialConfig() {
    viewModel.delegate = self
  }

  open func setupSubviews() {
    view.addSubview(tableView)
    view.addSubview(brokenNetworkView)

    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
    tableViewTopConstraint?.isActive = true
  }

  func requestData() {
    let params = NIMFetchServerSessionOption()
    params.minTimestamp = 0
    params.maxTimestamp = Date().timeIntervalSince1970 * 1000
    params.limit = 50
    weak var weakSelf = self
    viewModel.fetchServerSessions(option: params) { error, recentSessions in
      if error == nil {
        DispatchQueue.main.async {
          weakSelf?.tableView.reloadData()
        }

      } else {
        NELog.errorLog(
          self.className,
          desc: "❌fetchServerSessions failed，error = \(error!)"
        )
      }
    }
  }

  // MARK: lazy method

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      ConversationListCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(ConversationListCell.self))"
    )
    tableView.rowHeight = 62
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.backgroundColor = .white
    return tableView
  }()

  private lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view =
      NEBrokenNetworkView(frame: CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: 36))
    view.isHidden = true
    return view
  }()
}

// MARK: ====================== private method===========================

extension ConversationListViewController {
  private func onTopRecentAtIndexPath(rencent: NIMRecentSession, indexPath: IndexPath,
                                      isTop: Bool,
                                      _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                        -> Void) {
    guard let session = rencent.session else {
      NELog.errorLog(className, desc: "❌session is nil")
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
            weakSelf?.className ?? "ConversationListViewController",
            desc: "❌removeStickTopSession failed，error = \(err)"
          )
          completion(error as NSError?, nil)

          return
        } else {
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
            weakSelf?.className ?? "ConversationListViewController",
            desc: "❌addStickTopSession failed，error = \(err)"
          )
          completion(error as NSError?, nil)
          return
        } else {
          weakSelf?.viewModel.stickTopInfos[session] = newInfo
          weakSelf?.viewModel.sortRecentSession()
          weakSelf?.tableView.reloadData()
          completion(nil, newInfo)
        }
      }
    }
  }
}

extension ConversationListViewController: UITableViewDelegate, UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.conversationListArray?.count ?? 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(ConversationListCell.self))",
      for: indexPath
    ) as! ConversationListCell
    let conversationModel = viewModel.conversationListArray?[indexPath.row]
    cell.topStickInfos = viewModel.stickTopInfos
    cell.configData(sessionModel: conversationModel)
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let conversationModel = viewModel.conversationListArray?[indexPath.row]

    guard let sid = conversationModel?.recentSession?.session?.sessionId else {
      return
    }
    guard let sessionType = conversationModel?.recentSession?.session?.sessionType else {
      return
    }
    onselectedTableRow(sessionType: sessionType, sessionId: sid, indexPath: indexPath)
  }

  public func tableView(_ tableView: UITableView,
                        editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    weak var weakSelf = self
    var rowActions = [UITableViewRowAction]()

    let conversationModel = weakSelf?.viewModel.conversationListArray?[indexPath.row]
    guard let recentSession = conversationModel?.recentSession,
          let session = recentSession.session else {
      return rowActions
    }

    let deleteAction = UITableViewRowAction(style: .destructive,
                                            title: "删除") { action, indexPath in

      weakSelf?.viewModel.deleteRecentSession(recentSession: recentSession)
      weakSelf?.didDeleteConversationCell(
        model: conversationModel ?? ConversationListModel(),
        indexPath: indexPath
      )

      // 删除cell
      if let stickTopInfo = weakSelf?.viewModel.stickTopInfoForSession(session: session) {
        weakSelf?.viewModel
          .removeStickTopSession(params: stickTopInfo) { error, topSessionInfo in
            if let err = error {
              NELog.errorLog(
                weakSelf?.className ?? "ConversationListViewController",
                desc: "❌removeStickTopSession failed，error = \(err)"
              )
              return
            }
            weakSelf?.viewModel.stickTopInfos[session] = nil
          }
      }
    }

    // 置顶和取消置顶
    let isTop = viewModel.stickTopInfos[session] != nil
    let topAction = UITableViewRowAction(style: .destructive,
                                         title: isTop ? "取消置顶" : "置顶") { action, indexPath in
      if let recentSesstion = conversationModel?.recentSession {
        weakSelf?.onTopRecentAtIndexPath(
          rencent: recentSesstion,
          indexPath: indexPath,
          isTop: isTop
        ) { error, sessionInfo in
          if error == nil {
            if isTop {
              weakSelf?.didRemoveStickTopSession(
                model: conversationModel ?? ConversationListModel(),
                indexPath: indexPath
              )
            } else {
              weakSelf?.didAddStickTopSession(
                model: conversationModel ?? ConversationListModel(),
                indexPath: indexPath
              )
            }
          }
        }
      }
    }
    deleteAction.backgroundColor = NEConstant.hexRGB(0xA8ABB6)
    topAction.backgroundColor = NEConstant.hexRGB(0x337EFF)
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
}

// MARK: UI UIKit提供的重写方法

extension ConversationListViewController {
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

extension ConversationListViewController: ConversationViewModelDelegate {
  public func didAddRecentSession() {
    viewModel.sortRecentSession()
    tableView.reloadData()
  }

  public func didUpdateRecentSession(index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView.reloadRows(at: [indexPath], with: .none)
  }

  public func reloadTableView() {
    viewModel.sortRecentSession()
    tableView.reloadData()
  }
}
