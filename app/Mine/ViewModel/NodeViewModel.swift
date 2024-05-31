
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class NodeViewModel: NSObject {
  var sectionData = [SettingSectionModel]()

  public func getData() {
    sectionData.append(getSection())
  }

  private func getSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    // 国内节点配置
    let home = SettingCellModel()
    home.subTitle = NSLocalizedString("domestic_node", comment: "")
    home.rowHeight = 44.0
    home.switchOpen = SettingRepo.shared.getNodeValue() == true ? true : false

    // 海外节点配置
    let overseas = SettingCellModel()
    overseas.subTitle = NSLocalizedString("overseas_node", comment: "")
    overseas.switchOpen = SettingRepo.shared.getNodeValue() == true ? false : true
    overseas.rowHeight = 44.0

    model.cellModels.append(contentsOf: [
      home, // 国内节点配置
      overseas, // 海外节点配置
    ])
    model.setCornerType()
    return model
  }
}
