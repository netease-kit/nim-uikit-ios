
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitTeamUI

public class MessageRemindViewModel {
    var sectionData = [SettingSectionModel]()
    
    let repo = SettingRepo()

    func getData(){
        sectionData.append(getFirstSection())
//        sectionData.append(getSecondSection())
        sectionData.append(getThirdSection())

    }

    
    private func getFirstSection() -> SettingSectionModel {
        
        let model = SettingSectionModel()
        weak var weakSelf = self
        let messageNotify = SettingCellModel()
        messageNotify.cellName = "新消息通知"
        messageNotify.type = SettingCellType.SettingSwitchCell.rawValue
        messageNotify.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
        messageNotify.switchOpen = repo.getPushEnable()
        messageNotify.swichChange = { isOpen in
            weakSelf?.repo.setPushEnable(isOpen)
        }
        model.cellModels.append(contentsOf: [messageNotify])
        return model
        
        
    }
    
    private func getSecondSection() -> SettingSectionModel {
        let model = SettingSectionModel()
        weak var weakSelf = self
        let ringBellItem = SettingCellModel()
        ringBellItem.cellName = "响铃模式"
        ringBellItem.type = SettingCellType.SettingSwitchCell.rawValue
        ringBellItem.cornerType = .topLeft.union(.topRight)
        ringBellItem.switchOpen = repo.getPushAudioEnable()
        ringBellItem.swichChange = { isOpen in
            weakSelf?.repo.setPushAudioEnable(isOpen)
        }
        
        let vibrationItem = SettingCellModel()
        vibrationItem.cellName = "震动模式"
        vibrationItem.type = SettingCellType.SettingSwitchCell.rawValue
        vibrationItem.cornerType = .bottomLeft.union(.bottomRight)
        vibrationItem.switchOpen = repo.getPushShakeEnable()
        vibrationItem.swichChange = { isOpen in
            weakSelf?.repo.setPushShakeEnable(isOpen)
        }
        model.cellModels.append(contentsOf: [ringBellItem, vibrationItem])
        return model
    }
    
    private func getThirdSection() -> SettingSectionModel {
        let model = SettingSectionModel()
        weak var weakSelf = self
        let receiveItem = SettingCellModel()
        receiveItem.cellName = "PC/Web同步接收推送"
        receiveItem.type = SettingCellType.SettingSwitchCell.rawValue
        receiveItem.cornerType = .topLeft.union(.topRight)
        receiveItem.switchOpen = repo.getPcWebPushEnable()
        receiveItem.swichChange = { isOpen in
            weakSelf?.repo.updatePcWebPushEnable(isOpen)
        }
        
        let messageDetailItem = SettingCellModel()
        messageDetailItem.cellName = "通知栏显示消息详情"
        messageDetailItem.type = SettingCellType.SettingSwitchCell.rawValue
        messageDetailItem.cornerType = .bottomLeft.union(.bottomRight)
        messageDetailItem.switchOpen = repo.getPushDetailEnable()
        messageDetailItem.swichChange = { isOpen in
            weakSelf?.repo.settingProvider.setPushDetailEnable(isOpen)
        }
        
        model.cellModels.append(contentsOf: [receiveItem, messageDetailItem])
        return model
    }
    
    
}
