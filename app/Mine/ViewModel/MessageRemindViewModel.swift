
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit

@objcMembers
public class MessageRemindViewModel: NSObject {
  var sectionData = [SettingSectionModel]()

  let repo = SettingRepo.shared

  func getData() {
    sectionData.append(getFirstSection())
//        sectionData.append(getSecondSection())
    sectionData.append(getThirdSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    // 新消息通知
    let messageNotify = SettingCellModel()
    messageNotify.cellName = NSLocalizedString("new_message_remind", comment: "")
    messageNotify.type = SettingCellType.SettingSwitchCell.rawValue
    messageNotify.switchOpen = repo.getPushEnable()
    messageNotify.swichChange = { isOpen in
      weakSelf?.repo.setPushEnable(isOpen)
    }
    model.cellModels.append(contentsOf: [
      messageNotify, // 新消息通知
    ])
    model.setCornerType()
    return model
  }

  private func getSecondSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self
    let ringBellItem = SettingCellModel()
    ringBellItem.cellName = NSLocalizedString("ring_mode", comment: "")
    ringBellItem.type = SettingCellType.SettingSwitchCell.rawValue
    ringBellItem.switchOpen = repo.getRingMode()
    ringBellItem.swichChange = { isOpen in
      weakSelf?.repo.setRingMode(isOpen)
    }

    let vibrationItem = SettingCellModel()
    vibrationItem.cellName = NSLocalizedString("vibration_mode", comment: "")
    vibrationItem.type = SettingCellType.SettingSwitchCell.rawValue
    vibrationItem.switchOpen = repo.getVibrateMode()
    vibrationItem.swichChange = { isOpen in
      weakSelf?.repo.setVibrateMode(isOpen)
    }
    model.cellModels.append(contentsOf: [
      ringBellItem,
      vibrationItem,
    ])
    model.setCornerType()
    return model
  }

  private func getThirdSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self
//    let receiveItem = SettingCellModel()
//    receiveItem.cellName = NSLocalizedString("syn_receive_push", comment: "")
//    receiveItem.type = SettingCellType.SettingSwitchCell.rawValue
//    receiveItem.switchOpen = repo.getPcWebPushEnable()
//    receiveItem.swichChange = { isOpen in
//      weakSelf?.repo.updatePcWebPushEnable(isOpen)
//    }

    let messageDetailItem = SettingCellModel()
    messageDetailItem.cellName = NSLocalizedString("display_message_detail", comment: "")
    messageDetailItem.type = SettingCellType.SettingSwitchCell.rawValue
    messageDetailItem.switchOpen = repo.getPushShowDetail()
    messageDetailItem.swichChange = { isOpen in
      weakSelf?.repo.setPushShowDetail(isOpen)
    }

    model.cellModels.append(contentsOf: [messageDetailItem])
    model.setCornerType()
    return model
  }
}
