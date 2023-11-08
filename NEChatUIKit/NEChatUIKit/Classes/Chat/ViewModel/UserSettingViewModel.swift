// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NIMSDK

protocol UserSettingViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
  func didError(_ error: Error)
}

@objcMembers
public class UserSettingViewModel: NSObject {
  var repo = ChatRepo.shared

  var userInfo: User?

  var cellDatas = [UserSettingCellModel]()

  var delegate: UserSettingViewModelDelegate?

  private let className = "UserSettingViewModel"

  func getUserSettingModel(_ userId: String) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + userId)
    guard let user = repo.getUserInfo(userId: userId) else {
      return
    }
    userInfo = user
    weak var weakSelf = self

    let mark = UserSettingCellModel()
    mark.cellName = chatLocalizable("operation_pin")
    mark.type = UserSettingType.SelectType.rawValue
    mark.cornerType = .topLeft.union(.topRight)

    let remind = UserSettingCellModel()
    remind.cellName = chatLocalizable("message_remind")
    if let isNotiMsg = user.imUser?.notifyForNewMsg() {
      remind.switchOpen = isNotiMsg
    }

    remind.swichChange = { isOpen in
      if let uid = weakSelf?.userInfo?.userId {
        weakSelf?.repo.setNotify(uid, isOpen) { error in
          if let err = error {
            weakSelf?.delegate?.didNeedRefreshUI()
            weakSelf?.delegate?.didError(err)
          } else {
            remind.switchOpen = isOpen
          }
        }
      }
    }

    let setTop = UserSettingCellModel()
    setTop.cellName = chatLocalizable("session_set_top")
    setTop.cornerType = .bottomRight.union(.bottomLeft)

    if let uid = user.userId {
      let session = NIMSession(uid, type: .P2P)
      setTop.switchOpen = repo.isStickTop(session)
    }

    setTop.swichChange = { isOpen in
      if let uid = weakSelf?.userInfo?.userId {
        let session = NIMSession(uid, type: .P2P)
        if isOpen {
          let params = NIMAddStickTopSessionParams(session: session)
          weakSelf?.repo.chatExtendProvider
            .addStickTopSession(params: params) { error, info in
              print("add stick : ", error as Any)
              if let err = error {
                weakSelf?.delegate?.didNeedRefreshUI()
                weakSelf?.delegate?.didError(err)
              } else {
                setTop.switchOpen = false
              }
            }
        } else {
          if let info = weakSelf?.repo.chatExtendProvider.getTopSessionInfo(session) {
            weakSelf?.repo.chatExtendProvider
              .removeStickTopSession(params: info) { error, info in
                print("remote stick : ", error as Any)
                if let err = error {
                  weakSelf?.delegate?.didNeedRefreshUI()
                  weakSelf?.delegate?.didError(err)
                } else {
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
    cellDatas.append(contentsOf: [mark, remind, setTop])
  }
}
