//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public protocol NEChatEmojProtocol: NSObjectProtocol {
  @objc optional func getEmojAttributeString(_ content: String, _ font: CGFloat, _ color: UIColor) -> NSAttributedString?
}
