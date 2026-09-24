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
    for language in languageDatas {
      let model = NElanguageCellModel()
      model.language = language
      datas.append(model)
    }
  }
}
