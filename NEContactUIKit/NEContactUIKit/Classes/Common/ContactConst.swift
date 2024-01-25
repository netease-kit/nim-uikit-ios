
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreText
import Foundation
import NECoreKit

@objc
public enum ContactCellType: Int {
  case ContactOthers = 1 // blacklist groups computer and so on
  case ContactPerson = 2 // contact person
  case ContactCutom = 50 // custom type start with 50
}

public typealias ContactsSelectCompletion = ([ContactInfo]) -> Void?

let coreLoader = CoreLoader<NEBaseContactViewController>()
func localizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

public let ModuleName = "NEContactUIKit"
