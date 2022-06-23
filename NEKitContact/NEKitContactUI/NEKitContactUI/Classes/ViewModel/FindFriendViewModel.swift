
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitContact
import NEKitCoreIM

class FindFriendViewModel {
    
    let contactRepo = ContactRepo()
    
    func searchFriend(_ text: String, _ completion: @escaping ([User]?, NSError?)->()){
        contactRepo.getUserInfo(accountList: [text], completion)
    }
    
}
