
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NETeamUIKit

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
    home.cornerType = .topLeft.union(.topRight)
    home.rowHeight = 44.0
    home.switchOpen = IMKitClient.instance.repo.getNodeValue() == true ? true : false

    // 海外节点配置
    let overseas = SettingCellModel()
    overseas.subTitle = NSLocalizedString("overseas_node", comment: "")
    overseas.cornerType = .bottomLeft.union(.bottomRight)
    overseas.switchOpen = IMKitClient.instance.repo.getNodeValue() == true ? false : true
    overseas.rowHeight = 44.0

    model.cellModels.append(contentsOf: [home, overseas])
    return model
  }
}
