
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class NEChatKitClient: NSObject {
  public static let instance = NEChatKitClient()
  // 地图代理
  public weak var delegate: NEChatMapProtocol?

  /// 表情代理
  public weak var emojDelegate: NEChatEmojProtocol?

  /// 添加地图代理
  open func addMapDelegate(_ delegate: NEChatMapProtocol) {
    self.delegate = delegate
  }

  /// 移除地图代理
  open func removeMapDelegate(_ delegate: NEChatMapProtocol) {
    self.delegate = nil
  }

  /// 添加表情代理
  open func addEmojDelegate(_ delegate: NEChatEmojProtocol) {
    emojDelegate = delegate
  }

  /// 移除表情代理
  open func removeEmojDelegate() {
    emojDelegate = nil
  }

  /// 获取表情解析字符串
  /// - Parameter content: 待解析字符串
  open func getEmojString(_ content: String, _ fontSize: CGFloat, _ color: UIColor) -> NSAttributedString? {
    emojDelegate?.getEmojAttributeString?(content, fontSize, color)
  }
}
