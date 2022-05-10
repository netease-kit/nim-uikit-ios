
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitQChat
import UIKit
import NEKitCoreIM

class PermissionViewModel {
    
    let permission = PermissionModel()
    
    var commons = [PermissionCellModel]()
    
    var messages = [PermissionCellModel]()
    
    var members = [PermissionCellModel]()
    
    let repo = QChatRepo()
    
    var delegate: ViewModelDelegate?
    
    var hasPermissionKey = [String: String]()
        
    init(){
        
    }
    
    func getData(_ serverRole: ServerRole){
        weak var weakSelf = self
//        print("get data authors : ", serverRole.auths as Any)
        serverRole.auths?.forEach({ info in
            if info.status == .Allow {
                if let key = info.permissionType?.rawValue {
                    weakSelf?.hasPermissionKey[key] = key
                }
            }
        })
        loadData(permission.commonPermission, permission.commonPermissionDic, &commons)
        loadData(permission.messagePermission, permission.messagePermissionDic, &messages)
        loadData(permission.memberPermission, permission.memberPermissionDic, &members)
        
//        delegate?.dataDidChange()
    }
    
    func loadData(_ keys:[String], _ keyValues: [String: String], _ datas: inout [PermissionCellModel] ){
    
        for index in 0..<keys.count {
            let model = PermissionCellModel()
            model.permission = permission
            let key = keys[index]
            let name = keyValues[key]
            model.showName = name
            model.permissionKey = key
            if let value = permission.value(forKey: key) as? String {
                if hasPermissionKey[value] != nil {
                    model.hasPermission = true
                }
            }
            datas.append(model)
            if index == 0 {
                model.cornerType = CornerType.topLeft.union(CornerType.topRight)
            }
            if index == keys.count - 1 {
                model.cornerType = model.cornerType.union(.bottomLeft).union(.bottomRight)
            }
        }
    }
}
