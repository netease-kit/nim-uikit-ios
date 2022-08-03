
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitQChat
import NEKitCoreIM

public class MemberListViewModel {
    
    let repo = QChatRepo()
    public var memberInfomationArray:[QChatMember]?
    weak var delegate: ViewModelDelegate?
    
    init(){}
    
    func requestServerMemebersByPage(param:QChatGetServerMembersByPageParam,_ completion: @escaping (NSError?,[ServerMemeber]?)->()){
        repo.getServerMembersByPage(param) { error, memberResult in
            
            if error == nil {
                guard let memberArr = memberResult?.memberArray else { return  }
                var accidList = [String]()
                var dic = [String: ServerMemeber]()
                
                for memberModel in memberArr {
                    accidList.append(memberModel.accid ?? "")
                    if let accid = memberModel.accid {
                        dic[accid] = memberModel
                    }
                }
                
                let roleParam = QChatGetExistingAccidsInServerRoleParam(serverId: param.serverId!, accids: accidList)
                self.repo.getExistingServerRolesByAccids(roleParam) { error, serverRolesDict in
                    serverRolesDict?.forEach({ key,roleArray in
                        dic[key]?.roles = roleArray
                    })
                    var tempServerArray = [ServerMemeber]()
                    for var memberModel in memberArr {
                        if let accid = memberModel.accid,let dicMember = dic[accid] {
                            memberModel.roles = dicMember.roles
                            memberModel.imName = dicMember.imName
                            tempServerArray.append(memberModel)
                        }
                    }
                    completion(nil,tempServerArray)
                }
  
            }else {
                completion(error,nil)
                print("getServerMembersByPage failed,error = \(error!)")
            }
        }
    }

    
    
    func getRoles(){
        
    }
    
}
