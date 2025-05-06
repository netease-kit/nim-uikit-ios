// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NIMSDK
import UIKit

// 自定义消息类型，用于绑定 cell 和内部标识
public let customMessageType = 20

public class CustomAttachment: NECustomAttachment {
  public var goodsName = "name"

  public var goodsURL = "url"

  public init(_ neCustomAttachment: NECustomAttachment? = nil) {
    super.init()
    if let neCustomAttachment = neCustomAttachment {
      customType = neCustomAttachment.customType
      cellHeight = neCustomAttachment.cellHeight
      data = neCustomAttachment.data
    }
  }

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
      let customAttachment = CustomAttachment(neCustomAttachment)
    // 对自定义消息高度进行解析
    if customAttachment.customType == customMessageType {
      customAttachment.cellHeight = 50
    }
      
    customAttachment.goodsName = info["goodsName"] as? String ?? ""
    customAttachment.goodsURL = info["goodsURL"] as? String ?? ""

    return customAttachment
  }
}
