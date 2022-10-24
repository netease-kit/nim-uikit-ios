
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

public class CustomAttachment: NSObject, NIMCustomAttachment {
  public var type = 0

  public var goodsName = "name"

  public var goodsURL = "url"

  public func encode() -> String {
    let info = ["goodsName": goodsName, "goodsURL": goodsURL, "type": type] as [String: Any]

    let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
    var content = ""
    if let data = jsonData {
      content = String(data: data, encoding: .utf8) ?? ""
    }
    return content
  }
}

public class CustomAttachmentDecoder: NSObject, NIMCustomAttachmentCoding {
  public func decodeAttachment(_ content: String?) -> NIMCustomAttachment? {
    var attachment: NIMCustomAttachment?
    let data = content?.data(using: .utf8)
    guard let dataInfo = data else {
      return attachment
    }

    let infoDict = try? JSONSerialization.jsonObject(
      with: dataInfo,
      options: .mutableContainers
    )
    let infoResult = infoDict as? [String: Any]
    let type = infoResult?["type"] as? Int

    switch type {
    case 0:
      attachment =
        decodeCustomMessage(info: infoDict as? [String: Any] ?? [String(): String()])
    default:
      print("test")
    }

    return attachment
  }

  func decodeCustomMessage(info: [String: Any]) -> CustomAttachment {
    let customAttachment = CustomAttachment()
    customAttachment.goodsName = info["goodsName"] as? String ?? ""
    customAttachment.goodsURL = info["goodsURL"] as? String ?? ""
    if let type = info["type"] as? Int {
      customAttachment.type = type
    }

    return customAttachment
  }
}
