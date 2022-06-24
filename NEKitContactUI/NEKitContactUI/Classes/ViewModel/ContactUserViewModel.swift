
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitContact
import NEKitCoreIM
import CoreMedia
class ContactUserViewModel {
    
    let contactRepo = ContactRepo()

    func addFriend(_ account: String, _ completion: @escaping (NSError?)->()){
        let request = AddFriendRequest()
        request.account = account
        request.operationType = .addRequest
        contactRepo.addFriend(request: request, completion)
    }
    
    public func deleteFriend(account: String ,_ completion: @escaping (NSError?)->()) {
        return contactRepo.deleteFriend(account: account, completion)
    }

    public func isFriend(account: String) -> Bool {
        return contactRepo.isFriend(account: account)
    }
    
    public func isBlack(account: String) -> Bool {
        return contactRepo.isBlackList(account: account)
    }
    
    public func update(_ user: User, _ completion: @escaping (Error?) -> Void){
        contactRepo.updateUser(user, completion)
    }
    
    public func getUserInfo(_ uid: String, _ completion: @escaping (Error?, User?) -> Void){
        contactRepo.getUserInfo(uid) { error, users in
            completion(error, users.first)
        }
    }
    
}
