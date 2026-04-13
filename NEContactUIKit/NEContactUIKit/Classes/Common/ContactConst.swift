
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreText
import Foundation
import NECommonKit
import NECoreIM2Kit

@objc
public enum ContactCellType: Int {
  case ContactOthers = 1 // blacklist groups computer and so on
  case ContactPerson = 2 // contact person
  case ContactCutom = 50 // custom type start with 50
}

public typealias ContactsSelectCompletion = ([ContactInfo]) -> Void?

let contactCoreLoader = CommonLoader<NEContactBaseViewController>()
func localizable(_ key: String) -> String {
  contactCoreLoader.localizable(key)
}

public let ModuleName = "NEContactUIKit"

/// 将 AI 机器人操作的 NSError 转换为用户友好的提示文案
/// 优先匹配已知错误码，未匹配时降级使用 error.localizedDescription
public func robotErrorMessage(_ error: Error) -> String {
  let code = (error as NSError).code
  switch code {
  case robotFunctionNotEnabled:
    return localizable("robot_error_403")
  case failedOperation:
    return localizable("robot_error_414")
  case inValidTokenCode:
    return localizable("robot_error_102302")
  case userNotExistCode:
    return localizable("robot_error_102404")
  case robotNotAIAccount:
    return localizable("robot_error_102308")
  case robotBindCodeNotExist:
    return localizable("robot_error_102309")
  case robotNotBelongToUser:
    return localizable("robot_error_102310")
  case robotQRCodeAlreadyBound:
    return localizable("robot_error_102311")
  default:
    return error.localizedDescription
  }
}
