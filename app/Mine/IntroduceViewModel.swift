
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitTeamUI
public class IntroduceViewModel {
    var sectionData = [SettingCellModel]()

    func getData(){
        let versionItem = SettingCellModel()
        versionItem.cellName = "版本号"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let version = appVersion  {
            versionItem.subTitle = "V\(version)"
        }
        
        let introduceItem = SettingCellModel()
        introduceItem.cellName = "产品介绍"
        sectionData.append(contentsOf: [versionItem,introduceItem])
    }
    
    
    
}
