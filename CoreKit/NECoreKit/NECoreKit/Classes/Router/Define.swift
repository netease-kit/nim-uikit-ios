
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// Routing state
@objc public enum RouterState: NSInteger {
  case businessError = -1
  case systemError = 0
  case success = 1
}

/// Asynchronous processing
public typealias RouteAsyncHandle = ([String: Any]) -> Void
/// Handle callback asynchronously
public typealias RouteHandleCallbackClosure = (Any?, RouterState, String) -> Void
