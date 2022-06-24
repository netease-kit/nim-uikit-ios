
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitConversation
import NIMSDK

public protocol ConversationViewModelDelegate: AnyObject{
    func didAddRecentSession()
    func didUpdateRecentSession(index:Int)
    func reloadTableView()
}

public class ConversationViewModel:NSObject,ConversationRepoDelegate,NIMConversationManagerDelegate,NIMTeamManagerDelegate,NIMUserManagerDelegate {
    
    public var conversationListArray:[ConversationListModel]?
    public var stickTopInfos = [NIMSession:NIMStickTopSessionInfo]()
    public weak var delegate: ConversationViewModelDelegate?
    private let className = "ConversationViewModel"
    let repo = ConversationRepo()
    
    public override init() {
        super.init()
        repo.delegate = self
        repo.addSessionDelegate(delegate: self)
        repo.addTeamDelegate(delegate: self)
        stickTopInfos = repo.getStickTopInfos()
        NIMSDK.shared().userManager.add(self)
    }
    
    public func fetchServerSessions(option:NIMFetchServerSessionOption,_ completion:@escaping (NSError?,[ConversationListModel]?)->()) {
        
        weak var weakSelf = self
        repo.getSessionList(option: option) { error, conversaitonList in
            weakSelf?.conversationListArray = conversaitonList
            completion(error,weakSelf?.conversationListArray)
        }
    }
    
    public func deleteRecentSession(recentSession:NIMRecentSession){
        repo.deleteLocalSession(recentSession: recentSession)
    }
    
    public func stickTopInfoForSession(session:NIMSession) -> NIMStickTopSessionInfo?{
        return repo.getStickTopSessionInfo(session: session)
    }
    
    public func addStickTopSession(session:NIMSession,_ completion:@escaping (NSError?,NIMStickTopSessionInfo?)->()){
        let params = NIMAddStickTopSessionParams.init(session: session)
        repo.addStickTop(params: params) { error, stickTopSessionInfo in
            completion(error as NSError?,stickTopSessionInfo)
        }
    }
    
    public func removeStickTopSession(params:NIMStickTopSessionInfo,_ completion:@escaping (NSError?,NIMStickTopSessionInfo?)->()) {
        repo.removeStickTop(params: params) { error, stickTopSessionInfo in
            completion(error as NSError?,stickTopSessionInfo)
        }
    }
    
    public func loadStickTopSessionInfos(_ completion:@escaping (NSError?,[NIMSession:NIMStickTopSessionInfo]?)->()){
        repo.getStickTopSessions(completion)
    }
    
    public func notifyForNewMsg(userId:String?) -> Bool{
        return repo.notifyForNewMsg(userId: userId)
    }
    
    
    public func notifyStateForNewMsg(teamId:String?) -> NIMTeamNotifyState{
        return repo.getNotifyStateForNewMsg(teamId: teamId)
    }
    
    deinit {
        NIMSDK.shared().userManager.remove(self)
        repo.removeSessionDelegate(delegate: self)
        repo.removeTeamDelegate(delegate: self)
    }
    
    //MARK: ======================== private method ==============================
    public func sortRecentSession(){
        
        var tempArr = [NIMRecentSession]()
        var dic = [String:ConversationListModel]()
        conversationListArray?.forEach({ listModel in
            if let session = listModel.recentSession {
                tempArr.append(session)
                if let sessionId = session.session?.sessionId {
                    dic[sessionId] = listModel
                }
            }
        })
        
        let resultArr = repo.sortSessionList(recentSessions: tempArr, stickTopInfo: stickTopInfos)
        var sortResultArr = [ConversationListModel]()
        resultArr.forEach { recentSession in
            let listModel = ConversationListModel()
            listModel.recentSession = recentSession
            if recentSession.session?.sessionType == .P2P {
                if let sessionId = recentSession.session?.sessionId,let userInfo = dic[sessionId]?.userInfo {
                    listModel.userInfo = userInfo
                }
                
            }else if recentSession.session?.sessionType == .team {
                
                if let sessionId = recentSession.session?.sessionId,let teamInfo = dic[sessionId]?.teamInfo {
                    listModel.teamInfo = teamInfo
                }
            }
            sortResultArr.append(listModel)
        }
        conversationListArray = sortResultArr
        
    }
    
    //本地排序 在didUpdate的时候如有需要在打开
    func findInsertPlace(recentSession:NIMRecentSession) -> NSInteger{
        var matchIndex = 0
        var find = false
        if let conversationArr = conversationListArray{
            for (i, listModel) in conversationArr.enumerated() {
                if let enumTime = listModel.recentSession?.lastMessage?.timestamp,let targetTime = recentSession.lastMessage?.timestamp {
                    if enumTime <= targetTime {
                        find = true
                        matchIndex = i
                        break
                    }
                }
            }
        }
        
        if find {
            return matchIndex
        }else {
            return conversationListArray?.count ?? 0
        }
        
        
    }
    
    //MARK: ==================== ConversationRepoDelegate ==========================
    public func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo) {
        stickTopInfos[newInfo.session] = newInfo
        delegate?.reloadTableView()
        
    }
    
    public func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo) {
        stickTopInfos[removedInfo.session] = nil
        delegate?.reloadTableView()
    }
   
    
    public func didServerSessionUpdated(_ recentSession: NIMRecentSession?) {
        
    }
    
    //MARK: ====================NIMConversationManagerDelegate=====================
    public func didAdd(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
        
        guard let targetId = recentSession.session?.sessionId else {
            QChatLog.errorLog(className, desc: "❌sessionId is nil")
            return
        }
        weak var weakSelf = self
        let listModel = ConversationListModel()
        listModel.recentSession = recentSession
        if recentSession.session?.sessionType == .P2P {
            listModel.userInfo = repo.getUserInfo(userId: targetId)
            conversationListArray?.append(listModel)
            delegate?.didAddRecentSession()
        }else if recentSession.session?.sessionType == .team {
             repo.getTeamInfo(teamId: targetId, { error, teamInfo in
                 listModel.teamInfo = teamInfo
                 weakSelf?.conversationListArray?.append(listModel)
                 weakSelf?.delegate?.didAddRecentSession()
            })
        }

    }
    
    public func didUpdate(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
        if let _ = conversationListArray {
            for i in 0..<conversationListArray!.count{
                let listModel = conversationListArray![i]
                if recentSession.session?.sessionId ==  listModel.recentSession?.session?.sessionId{
//                    conversationListArray?.remove(at: i)
                    listModel.recentSession = recentSession
                    delegate?.reloadTableView()
//                    delegate?.didUpdateRecentSession(index: i)
                    break
                }
            }
        }
        
    }
    
    public func didRemove(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
        
        if let conversationArr = conversationListArray {
            for i in 0..<conversationArr.count{
                if conversationArr[i].recentSession?.session?.sessionId == recentSession.session?.sessionId {
                    conversationListArray?.remove(at: i)
                    break
                }
            }
        }
        delegate?.reloadTableView()
    }
    
    
    //MARK: ========================NIMTeamManagerDelegate=========================
    public func onFriendChanged(_ user: NIMUser) {
        
        if let listArr = conversationListArray {
            for (i,listModel) in listArr.enumerated() {
                if listModel.recentSession?.session?.sessionType == .P2P{
                    if listModel.userInfo?.userId == user.userId {
                        listModel.userInfo = User.init(user: user)
                        delegate?.didUpdateRecentSession(index: i)
                        break
                    }
                }
            }
            
        }

       
    }
    
    //MARK: =========================NIMTeamManagerDelegate========================
    public func onTeamUpdated(_ team: NIMTeam) {
        guard let conversationArr = conversationListArray else {
            return
        }
        for (i, listModel) in conversationArr.enumerated() {
            if listModel.recentSession?.session?.sessionId == team.teamId{
                listModel.teamInfo = team
                delegate?.didUpdateRecentSession(index: i)
                break
            }
        }
    }
    
    public func onTeamAdded(_ team: NIMTeam) {
        
    }
    
    public func onTeamRemoved(_ team: NIMTeam) {
        //做删除会话操作(自己退出群聊会触发)
        guard let conversationArr = conversationListArray else {
            return
        }
        
        //Fix sdk bug 
        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
            for (_, listModel) in conversationArr.enumerated() {
                if let teamInfo = listModel.teamInfo,teamInfo.teamId == team.teamId {
                    if let recentSession = listModel.recentSession {
                        self.deleteRecentSession(recentSession: recentSession)
                        break
                    }
                }
            }
        }
    }
    
    
    
}
