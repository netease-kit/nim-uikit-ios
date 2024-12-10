
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class MeViewModel: NSObject {
  public var mineData: [[String: String]] = []

  public func getData() {
    mineData = [
      [localizable("setting"): "mine_setting"],
      [localizable("about_yunxin"): "about_yunxin"],
    ]

    if IMKitConfigCenter.shared.enableCollectionMessage {
      mineData.insert([localizable("mine_collection"): "mine_collection"], at: 1)
    }
  }
}
