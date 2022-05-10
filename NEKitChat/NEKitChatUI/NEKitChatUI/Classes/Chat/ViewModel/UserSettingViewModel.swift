
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitChat
import NEKitCoreIM
import NIMSDK

protocol UserSettingViewModelDelegate: AnyObject {

    func didNeedRefreshUI()
    func didError(_ error: Error)
}

public class UserSettingViewModel {
    
    var repo = ChatRepo()
    
    var userInfo: User?
    
    var cellDatas = [UserSettingCellModel]()
    
    var delegate: UserSettingViewModelDelegate?
    
    func getUserSettingModel(_ userId: String) {
        guard let user = repo.getUserInfo(userId: userId) else {
            return
        }
        userInfo = user
        weak var weakSelf = self
        let remind = UserSettingCellModel()
        remind.cellName = localizable("message_remind")
        remind.cornerType = .topLeft.union(.topRight)
        if let isNotiMsg = user.imUser?.notifyForNewMsg() {
            remind.switchOpen = isNotiMsg
        }
        
        remind.swichChange = { isOpen in
            if let uid = weakSelf?.userInfo?.userId {
                weakSelf?.repo.updateNotifyState(uid, isOpen, { error in
                    if let err = error {
                        weakSelf?.delegate?.didNeedRefreshUI()
                        weakSelf?.delegate?.didError(err)
                    }else {
                        remind.switchOpen = isOpen
                    }
                })
            }
        }
        
        let setTop = UserSettingCellModel()
        setTop.cellName = localizable("session_set_top")
        setTop.cornerType = .bottomRight.union(.bottomLeft)

        if let uid = user.userId {
            let session = NIMSession(uid, type: .P2P)
            setTop.switchOpen = repo.sessionIsTop(session)
        }
        
        setTop.swichChange = { isOpen in
            if let uid = weakSelf?.userInfo?.userId {
                let session = NIMSession(uid, type: .P2P)
                if isOpen {
                    let params = NIMAddStickTopSessionParams.init(session: session)
                    weakSelf?.repo.chatExtendProvider.addStickTopSession(params: params) { error, info in
                        print("add stick : ",error as Any)
                        if let err = error {
                            weakSelf?.delegate?.didNeedRefreshUI()
                            weakSelf?.delegate?.didError(err)
                        }else {
                            setTop.switchOpen = false
                        }
                    }
                }else {
                    if  let info = weakSelf?.repo.chatExtendProvider.getTopSessionInfo(session) {
                        weakSelf?.repo.chatExtendProvider.removeStickTopSession(params: info) { error, info in
                            print("remote stick : ",error as Any)
                            if let err = error {
                                weakSelf?.delegate?.didNeedRefreshUI()
                                weakSelf?.delegate?.didError(err)
                            }else {
                                setTop.switchOpen = true
                            }
                        }
                    }
                }
            }
        }
        
        /*
        let blackList = UserSettingCellModel()
        blackList.cornerType = .bottomRight.union(.bottomLeft)
        blackList.cellName = "加入黑名单"
        if let isBlack = user.imUser?.isInMyBlackList() {
            blackList.switchOpen = isBlack
        }
        blackList.swichChange = { isOpen in
            if let uid = weakSelf?.userInfo?.userId {
                if isOpen {
                    weakSelf?.repo.addBlackList(account: uid, { error in
                        print("add black list : ", error as Any)
                    })
                }else {
                    weakSelf?.repo.removeFromBlackList(account: uid, { error in
                        print("remo black list : ", error as Any)
                    })
                }
            }
        }
        */
        cellDatas.append(contentsOf: [remind, setTop])
        
    }
}
