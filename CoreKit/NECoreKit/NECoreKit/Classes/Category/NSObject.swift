
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension NSObject {
  func className() -> String {
    if let name = object_getClass(self) {
      let className = String(describing: name)
      return className
    }
    return "unknow class"
  }
}
