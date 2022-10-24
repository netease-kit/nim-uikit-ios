
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit

@objcMembers
public class IntroduceViewModel: NSObject {
  var sectionData = [SettingCellModel]()

  func getData() {
    let versionItem = SettingCellModel()
    versionItem.cellName = NSLocalizedString("version", comment: "")
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    if let version = appVersion {
      versionItem.subTitle = "V\(version)"
    }

    let introduceItem = SettingCellModel()
    introduceItem.cellName = NSLocalizedString("product_intro", comment: "")
    sectionData.append(contentsOf: [versionItem, introduceItem])
  }
}
