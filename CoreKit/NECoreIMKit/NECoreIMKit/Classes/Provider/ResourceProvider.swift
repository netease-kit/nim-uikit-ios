
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
public class ResourceProvider: NSObject {
  public static let shared = ResourceProvider()

  override public init() {}

  // 使用短链换源链
  public func fetchNOSURL(targetUrl: String, _ completion: @escaping (Error?, String?) -> Void) {
    NIMSDK.shared().resourceManager.fetchNOSURL(withURL: targetUrl) { error, url in
      completion(error, url)
    }
  }
}
