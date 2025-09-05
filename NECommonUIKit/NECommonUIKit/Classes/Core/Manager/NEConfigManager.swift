// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
public class NEConfigManager: NSObject {
  public static let instance = NEConfigManager()
  var configParameter = [String: Any?]()

  open func setParameter(key: String, value: Any?) {
    configParameter[key] = value
  }

  open func getParameter(key: String) -> Any? {
    configParameter[key] as Any?
  }
}
