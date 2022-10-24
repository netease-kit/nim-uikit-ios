// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEQChatKit
import NECoreIMKit

@objcMembers
public class CreateGroupViewModel: NSObject {
//    var limit = 7

//    var limitUsers = [UserInfo]()
  var allUsers = [UserInfo]()
  let repo = QChatRepo()
  private let className = "CreateGroupViewModel"

  weak var delegate: ViewModelDelegate?

  override init() {}

  func loadAllData() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
//        limitUsers.removeAll()
//        limitUsers.append(contentsOf: allUsers)
  }

  private func addUser(_ user: UserInfo) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(user.serverId ?? 0)")
    allUsers.append(user)
//        if limitUsers.count <= limit {
//            limitUsers.append(user)
//        }
  }

  func addNewUser(_ user: UserInfo) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(user.serverId ?? 0)")
    addUser(user)
    filterData()
  }

  func filterData() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    allUsers.forEach { user in
      user.cornerType = .none
    }
    if allUsers.count == 1, let first = allUsers.first {
      first.cornerType = CornerType.topLeft.union(CornerType.topRight).union(.bottomLeft)
        .union(.bottomRight)
    }

    if allUsers.count > 1, let first = allUsers.first, let last = allUsers.last {
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

  func removeData(_ index: Int) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", index:\(index)")
    allUsers.remove(at: index)
    filterData()
    delegate?.dataDidChange()
  }

  func addMembers(_ members: [UserInfo]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", members.count:\(members.count)")
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

  func removeMember(_ member: UserInfo) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(member.serverId ?? 0)")
    delegate?.dataDidChange()
  }
}
