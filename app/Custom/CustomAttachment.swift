// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NIMSDK
import UIKit
public class CustomAttachment: NECustomAttachment {
  public var goodsName = "name"

  public var goodsURL = "url"

  override public func encode() -> String {
    // 自定义序列化方法之前必须调用父类的序列化方法
    let neContent = super.encode()
    var info: [String: Any] = getDictionaryFromJSONString(neContent) as? [String: Any] ?? [:]
    info["goodsName"] = goodsName
    info["goodsURL"] = goodsURL

    let jsonData = try? JSONSerialization.data(withJSONObject: info, options: [])
    var content = ""
    if let data = jsonData {
      content = String(data: data, encoding: .utf8) ?? ""
    }
    return content
  }
}

public class CustomAttachmentDecoder: NECustomAttachmentDecoder {
  override public func decodeCustomMessage(info: [String: Any]) -> CustomAttachment {
    // 自定义反序列化方法之前必须调用父类的反序列化方法
    let neCustomAttachment = super.decodeCustomMessage(info: info)
    let customAttachment = CustomAttachment(customType: neCustomAttachment.customType,
                                            cellHeight: neCustomAttachment.cellHeight,
                                            data: neCustomAttachment.data)
    if customAttachment.customType == 20 {
      customAttachment.cellHeight = 50
    }
    customAttachment.goodsName = info["goodsName"] as? String ?? ""
    customAttachment.goodsURL = info["goodsURL"] as? String ?? ""

    return customAttachment
  }
}
