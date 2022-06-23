
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NIMSDK

@objcMembers
open class ConversationListViewController: UIViewController {

    private var viewModel = ConversationViewModel()
    private let className = "ConversationListViewController"
    private var tableViewTopConstraint:NSLayoutConstraint?
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        requestData()
        initialConfig()
    }

    public override func viewWillAppear(_ animated: Bool) {
        weak var weakSelf = self
        viewModel.loadStickTopSessionInfos { error, sessionInfos in
            if let infos = sessionInfos {
                weakSelf?.viewModel.stickTopInfos = infos
                weakSelf?.reloadTableView()
            }
        }
        NEChatDetectNetworkTool.shareInstance.netWorkReachability() { status in
            if status == .notReachable{
                weakSelf?.brokenNetworkView.isHidden = false
                weakSelf?.tableViewTopConstraint?.constant = 36
            }else {
                weakSelf?.brokenNetworkView.isHidden = true
                weakSelf?.tableViewTopConstraint?.constant = 0
            }
        }
    }
    
    func initialConfig(){
        viewModel.delegate = self
    }
    
    
    func setupSubviews(){
        self.view.addSubview(tableView)
        self.view.addSubview(brokenNetworkView)
        
        NSLayoutConstraint.activate([
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        tableViewTopConstraint =  tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        tableViewTopConstraint?.isActive = true
    }
    
    func requestData(){
        let params = NIMFetchServerSessionOption()
        params.minTimestamp = 0
        params.maxTimestamp = Date().timeIntervalSince1970*1000
        params.limit = 50
        weak var weakSelf = self
        viewModel.fetchServerSessions(option: params) { error, recentSessions in
            if error == nil {
                DispatchQueue.main.async{
                    weakSelf?.tableView.reloadData()
                }

            }else {
                QChatLog.errorLog(self.className, desc: "❌fetchServerSessions failed，error = \(error!)")
            }
        }
    }
    
    //MARK: lazy method
    private lazy var tableView:UITableView = {
        let tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConversationListCell.self, forCellReuseIdentifier: "\(NSStringFromClass(ConversationListCell.self))")
        tableView.rowHeight = 62
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tableView.backgroundColor = .white
        return tableView
    }()
    
    private lazy var brokenNetworkView:NEBrokenNetworkView = {
        let view = NEBrokenNetworkView.init(frame: CGRect.init(x: 0, y: 0, width: NEConstant.screenWidth, height: 36))
        view.isHidden = true
        return view
    }()
    
}

//MARK: ====================== private method===========================
extension ConversationListViewController{
    func onTopRecentAtIndexPath(rencent:NIMRecentSession,indexPath:IndexPath,isTop:Bool){
        
        guard let session = rencent.session else {
            QChatLog.errorLog(className , desc: "❌session is nil")
            return
        }
        weak var weakSelf = self
        if isTop {
            guard let params = viewModel.stickTopInfos[session] else {
                return
            }
            
            viewModel.removeStickTopSession(params: params) { error, topSessionInfo in
                if let err = error {
                    QChatLog.errorLog(weakSelf?.className ?? "ConversationListViewController", desc: "❌removeStickTopSession failed，error = \(err)")
                    return
                }
                weakSelf?.viewModel.stickTopInfos[session] = nil
               
                weakSelf?.viewModel.sortRecentSession()
                weakSelf?.tableView.reloadData()
            }

        }else {
            
            viewModel.addStickTopSession(session: session, { error, newInfo in
                if let err = error {
                    QChatLog.errorLog(weakSelf?.className ?? "ConversationListViewController", desc: "❌addStickTopSession failed，error = \(err)")
                    return
                }
                weakSelf?.viewModel.stickTopInfos[session] = newInfo
                weakSelf?.viewModel.sortRecentSession()
                weakSelf?.tableView.reloadData()
            })
        }
    }
}

extension ConversationListViewController:UITableViewDelegate,UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.conversationListArray?.count ?? 0
        
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(NSStringFromClass(ConversationListCell.self))", for: indexPath) as! ConversationListCell
        let conversationModel = self.viewModel.conversationListArray?[indexPath.row]
        cell.topStickInfos = viewModel.stickTopInfos
        cell.configData(sessionModel: conversationModel)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversationModel = viewModel.conversationListArray?[indexPath.row]

        guard let commonId = conversationModel?.recentSession?.session?.sessionId else {
            return
        }

        if conversationModel?.recentSession?.session?.sessionType == .P2P {
            let session = NIMSession(commonId, type: .P2P)
            Router.shared.use("pushChatVC", parameters: ["nav": self.navigationController as Any, "session" : session as Any], closure: nil)
        }else if conversationModel?.recentSession?.session?.sessionType == .team {
           
            let session = NIMSession(commonId, type: .team)
            Router.shared.use(ChatPushGroupVC, parameters: ["nav": self.navigationController as Any, "session" : session as Any], closure: nil)
        }
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        weak var weakSelf = self
        var rowActions = [UITableViewRowAction]()
        
        let conversationModel = weakSelf?.viewModel.conversationListArray?[indexPath.row]
        guard let recentSession = conversationModel?.recentSession,let session = recentSession.session else {
            return rowActions
        }
       
        let deleteAction = UITableViewRowAction.init(style: .destructive, title: "删除") { action, indexPath in

            weakSelf?.viewModel.deleteRecentSession(recentSession: recentSession)
            
            //删除置顶
            if let stickTopInfo = weakSelf?.viewModel.stickTopInfoForSession(session: session) {
                weakSelf?.viewModel.removeStickTopSession(params: stickTopInfo) { error, topSessionInfo in
                    if let err = error {
                        QChatLog.errorLog(weakSelf?.className ?? "ConversationListViewController", desc: "❌removeStickTopSession failed，error = \(err)")
                        return
                    }
                    weakSelf?.viewModel.stickTopInfos[session] = nil
                }
            }

        }
        
       
        let isTop = viewModel.stickTopInfos[session] != nil
        let topAction = UITableViewRowAction.init(style: .destructive, title: isTop ? "取消置顶":"置顶") { action, indexPath in
            if let recentSesstion = conversationModel?.recentSession {
                weakSelf?.onTopRecentAtIndexPath(rencent: recentSesstion, indexPath: indexPath, isTop: isTop)
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

//MARK: ================= ConversationViewModelDelegate===================
extension ConversationListViewController:ConversationViewModelDelegate{
    
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
