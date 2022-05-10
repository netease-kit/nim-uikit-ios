
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitQChat
import NEKitCoreIM

typealias IdGroupViewModelBlock = () -> Void
public class IdGroupViewModel {
    
    let repo = QChatRepo()
    var topDatas = [IdGroupModel]()
    var datas = [IdGroupModel]()
    var sortBtnCellDatas = [IdGroupModel]()  // only one
    weak var delegate: ViewModelDelegate?
    
    var limitCount = 20
    
    init(){}
    
    func getRoles(_ serverId: UInt64?, _ refresh: Bool = false, _ block: IdGroupViewModelBlock? ){
        var param = GetServerRoleParam()
        param.serverId = serverId
        param.limit = limitCount
        if let last = datas.last, let pri = last.role?.priority, refresh == false {
            param.priority = pri
        }
        weak var weakSelf = self
        print("param : ", param)
        
        repo.getRoles(param) { error, roles, sets in
            if let err = error {
                weakSelf?.delegate?.dataDidError(err)
            }else if let rs = roles {
                print("get roles success : ", rs.count)
                weakSelf?.parseData(rs, refresh)
            }
            if let completion = block {
                completion()
            }
        }
    }
    
    func parseData(_ roles: [ServerRole], _ refresh: Bool){
        
        var models = [IdGroupModel]()
        roles.forEach { role in
            print("get data proprity : ", role.priority as Any)
            let model = IdGroupModel(role)
            models.append(model)
        }
        filterData(models, refresh)
        if roles.count < limitCount {
            delegate?.dataNoMore?()
        }
    }
    
    func filterData(_ models: [IdGroupModel], _ refresh: Bool){
        
        if refresh == true {
            topDatas.removeAll()
            datas.removeAll()
            sortBtnCellDatas.removeAll()
        }
        
        if let first = models.first {
            topDatas.append(first)
        }
        if models.count >= 2 {
            datas.append(contentsOf: models.suffix(models.count - 1))
        }
        
        if datas.count > 0 {
            if let first = sortBtnCellDatas.first {
                first.idName = "身份组(\(datas.count))"
            }else {
                let data = IdGroupModel()
                data.idName = "身份组(\(datas.count))"
                sortBtnCellDatas.append(data)
            }
        }
        delegate?.dataDidChange()
    }
    
    func addRole(_ role: ServerRole){
        var models = [IdGroupModel]()
        models.append(contentsOf: topDatas)
        models.append(contentsOf: datas)
        models.append(IdGroupModel(role))
        topDatas.removeAll()
        datas.removeAll()
        filterData(models, false)
    }
}
