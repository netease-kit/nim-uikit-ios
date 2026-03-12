//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NElanguageCellModel: NSObject {
  public var language: String = ""
  public var isSelect: Bool = false
  var cornerType: CornerType = .none
}

@objcMembers
open class SelectLanguageViewModel: NSObject {
  public var datas = [NElanguageCellModel]()

  func setupData(_ isFun: Bool) {
    let languageDatas = NETranslateLanguageManager.shared.languageDatas

    if isFun {
      for index in 0 ..< languageDatas.count {
        let model = NElanguageCellModel()
        model.language = languageDatas[index]
        datas.append(model)
        if index == 0 {
          model.cornerType = .topLeft.union(.topRight)
        } else if index == languageDatas.count - 1 {
          model.cornerType = .bottomLeft.union(.bottomRight)
        }
      }
    } else {
      for index in 0 ..< languageDatas.count {
        let model = NElanguageCellModel()
        model.language = languageDatas[index]
        datas.append(model)
      }
    }
  }
}
