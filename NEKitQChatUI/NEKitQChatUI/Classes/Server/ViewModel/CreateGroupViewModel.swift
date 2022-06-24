
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitQChat
import NEKitCoreIM

class CreateGroupViewModel {
    
//    var limit = 7
    
//    var limitUsers = [UserInfo]()
    var allUsers = [UserInfo]()
    let repo = QChatRepo()
    
    weak var delegate: ViewModelDelegate?
    
    init(){}
    
    func loadAllData(){
//        limitUsers.removeAll()
//        limitUsers.append(contentsOf: allUsers)
    }
    
    private func addUser(_ user: UserInfo){
        allUsers.append(user)
//        if limitUsers.count <= limit {
//            limitUsers.append(user)
//        }
    }
    
    func addNewUser(_ user: UserInfo){
        addUser(user)
        filterData()
    }
    
    func filterData(){
        allUsers.forEach { user in
            user.cornerType = .none
        }
        if allUsers.count == 1, let first = allUsers.first {
            first.cornerType = CornerType.topLeft.union(CornerType.topRight).union(.bottomLeft).union(.bottomRight)
        }
        
        if allUsers.count > 1 , let first = allUsers.first, let last = allUsers.last {
            first.cornerType = .topLeft.union(.topRight)
            last.cornerType = .bottomLeft.union(.bottomRight)
        }
        
        /*
        if limitUsers.count < limit {
            if let last = limitUsers.last {
                if limitUsers.count == 1 {
                    last.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft).union(CornerType.bottomRight)
                }else {
                    last.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
                }
            }
        }else {
            if let last = limitUsers.last {
                last.cornerType = .none
            }
        } */
        
        delegate?.dataDidChange()
    }
    
    func removeData(_ index: Int){
        allUsers.remove(at: index)
        filterData()
        delegate?.dataDidChange()
    }
    
    func addMembers(_ members: [UserInfo]){
        
        members.forEach { user in
            if allUsers.contains(where: { lUser in
                if let cid = lUser.serverMember?.accid, let mid = user.serverMember?.accid {
                    if cid == mid {
                        return true
                    }
                }
                return false
            }) == false {
                addUser(user)
            }
        }
        filterData()
    }
    
    func removeMember(_ member: UserInfo){
        
        delegate?.dataDidChange()
    }
}
