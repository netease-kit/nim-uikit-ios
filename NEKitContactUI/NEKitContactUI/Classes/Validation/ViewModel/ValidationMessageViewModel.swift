
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitContact
import NEKitCoreIM
import NEKitCore

public class ValidationMessageViewModel: ContactRepoSystemNotiDelegate {
    
    typealias DataRefresh = () -> Void
    
    var dataRefresh: DataRefresh?
    private let className = "ValidationMessageViewModel"
    let contactRepo = ContactRepo()
    var datas = [XNotification]()
    
    init(){
        contactRepo.notiDelegate = self
    }
    
    public func onNotificationUnreadCountChanged(_ count: Int) {
        
    }
    
    public func onRecieveNotification(_ notification: XNotification) {
//        if notification.type == .addFriendDirectly {
//            datas.insert(notification, at: 0)
//        }
        datas.insert(notification, at: 0)
        contactRepo.clearNotificationUnreadCount()
        if let block = dataRefresh {
            block()
        }
    }
    
    func getValidationMessage(_ completin: () -> Void ){
        let data = contactRepo.getNotificationList(limit: 500)
        datas = data
        if datas.count > 0 {
            completin()
        }else {
            QChatLog.warn(className, desc: "⚠️NotificationList is empty")
        }
    }
    
    func clearAllNoti(_ completion: () -> Void){
        contactRepo.clearNotification()
        datas.removeAll()
        completion()
    }
    
    public func acceptInviteWithTeam(_ teamId:String,_ invitorId:String,_ completion: @escaping (Error?) -> Void){
        contactRepo.acceptTeamInvite(teamId, invitorId, completion)
    }

    public func rejectInviteWithTeam(_ teamId:String,_ invitorId:String,_ completion: @escaping (Error?) -> Void){
        contactRepo.rejectTeamInvite(teamId, invitorId, completion)
    }
    
    func agreeRequest(_ account: String, _ completion: @escaping (NSError?)->()){
        let request = AddFriendRequest()
        request.account = account
        request.operationType = .verify
        contactRepo.addFriend(request: request, completion)
        
    }
    
    func refuseRequest(_ account: String, _ completion: @escaping (NSError?)->()){
        print("account : ", account)
        let request = AddFriendRequest()
        request.account = account
        request.operationType = .reject
        contactRepo.addFriend(request: request, completion)
    }
    
}
