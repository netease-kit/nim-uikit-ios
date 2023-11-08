// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public protocol NECustomAttachmentProtocol: NSObjectProtocol {
  var customType: Int { get set }
  var cellHeight: CGFloat { get set }
}
