
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@available(iOSApplicationExtension, unavailable)
@objc public final class NEInvocation: NSObject {
  @objc public weak var target: AnyObject?
  @objc public var action: Selector

  @objc public init(_ target: AnyObject, _ action: Selector) {
    self.target = target
    self.action = action
  }

  @objc public func invoke(from: Any) {
    if let target = target {
      UIApplication.shared.sendAction(action, to: target, from: from, for: UIEvent())
    }
  }

  deinit {
    target = nil
  }
}
