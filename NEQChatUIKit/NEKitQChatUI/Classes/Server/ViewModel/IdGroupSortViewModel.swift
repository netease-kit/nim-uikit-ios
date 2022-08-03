
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitQChat
import NEKitCoreIM
import AVFoundation
public class IdGroupSortViewModel {
    
    let repo = QChatRepo()
    
    var datas = NSMutableArray()
    
//    var lockData = [IdGroupModel]()
    
    weak var delegate: ViewModelDelegate?
    
    var isOwner = false
    
    func getData(_ serverId: UInt64?){
        var param = GetServerRoleParam()
        param.limit = 200
        param.serverId = serverId
        weak var weakSelf = self

        repo.getRoles(param) { error, roles, sets in
            if let err = error {
                weakSelf?.delegate?.dataDidError(err)
            }else {
                weakSelf?.filterData(roles, sets)
            }
        }
    }
    
    func filterData(_ roles: [ServerRole]?, _ sets: Set<NSNumber>?){
        weak var weakSelf = self
        roles?.forEach({ role in
            if role.type == .everyone {
                return
            }
            let model = IdGroupModel(role)
            model.hasPermission = isOwner
            if let rid = role.roleId, let s = sets, s.contains(NSNumber(value: rid)) == true {
                isOwner = true
            }
            weakSelf?.datas.add(model)
//            if model.hasPermission == true {
//                weakSelf?.datas.add(model)
//            }else {
//                weakSelf?.lockData.append(model)
//            }
        })
        weakSelf?.delegate?.dataDidChange()
    }
    
    func removeRole(_ serverId: UInt64?, _ roleId: UInt64?, _ model: IdGroupModel, _ completion: @escaping () -> Void){
        
        var param = DeleteServerRoleParam()
        param.serverId = serverId
        param.roleId = roleId
        weak var weakSelf = self
        repo.deleteRoles(param) { error in
            if let err = error {
                weakSelf?.delegate?.dataDidError(err)
            }else {
                weakSelf?.datas.remove(model)
                weakSelf?.delegate?.dataDidChange()
                completion()
            }
        }
    }
    
    func saveSort(_ serverId: UInt64?,  _ completion: @escaping () -> Void){
        
        var startIndex = 0
        
        var startSort = false
        var last: IdGroupModel?
        var items = [UpdateServerRolePriorityItem]()
        
        var min: Int?
        
        datas.forEach { data in

            if let model = data as? IdGroupModel, model.hasPermission == true {
                print("model p : ", model.role?.priority as Any)
                if let m = min, let p = model.role?.priority {
                    if m > p {
                        min = p
                    }
                }else {
                    min = model.role?.priority
                }
            }
        }
        
        print("print min : ", min as Any)
                
        for index in 0..<datas.count {
            if let m = datas[index] as? IdGroupModel, let r = m.role {
                if startSort == false && m.hasPermission == true {
                    startSort = true
                    if let m = min {
                        startIndex = m
                    }
                }
                if startSort == false {
                    
                    
                }else {
                    let item = UpdateServerRolePriorityItem(r, startIndex)
                    items.append(item)
                    startIndex = startIndex + 1
                    print("item priority : ", startIndex)
                }
                last = m
                print("item name : ", m.idName as Any)
            }
        }
        
        var param = UpdateServerRolePrioritiesParam()
        param.updateItems = items
        param.serverId = serverId
        weak var weakSelf = self
        
        if items.count <= 1 {
            completion()
            return
        }
        
        repo.updateServerRolePriorities(param) { error in
            if let err = error {
                weakSelf?.delegate?.dataDidError(err)
            }else {
                completion()
            }
        }
    }
    
}
