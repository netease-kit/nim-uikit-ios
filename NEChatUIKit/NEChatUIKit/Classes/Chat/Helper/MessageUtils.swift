
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NIMSDK

@objcMembers
open class MessageUtils: NSObject {
  open class func textMessage(text: String) -> NIMMessage {
    let message = NIMMessage()
    message.setting = messageSetting()
    message.text = text
    return message
  }

  open class func textMessage(text: String, remoteExt: [String: Any]?) -> NIMMessage {
    let message = NIMMessage()
    message.setting = messageSetting()
    message.text = text
    if remoteExt?.count ?? 0 > 0 {
      message.remoteExt = remoteExt
    }
    return message
  }

  open class func imageMessage(image: UIImage) -> NIMMessage {
    imageMessage(imageObject: NIMImageObject(image: image))
  }

  open class func imageMessage(path: String) -> NIMMessage {
    imageMessage(imageObject: NIMImageObject(filepath: path))
  }

  open class func imageMessage(data: Data, ext: String) -> NIMMessage {
    imageMessage(imageObject: NIMImageObject(data: data, extension: ext))
  }

  open class func imageMessage(imageObject: NIMImageObject) -> NIMMessage {
    let message = NIMMessage()
    let option = NIMImageOption()
    option.compressQuality = 0.8
    imageObject.option = option
    message.messageObject = imageObject
    message.apnsContent = chatLocalizable("send_picture")
    message.setting = messageSetting()
    return message
  }

  open class func audioMessage(filePath: String) -> NIMMessage {
    let messageObject = NIMAudioObject(sourcePath: filePath)
    let message = NIMMessage()
    message.messageObject = messageObject
    message.apnsContent = chatLocalizable("send_voice")
    message.setting = messageSetting()
    return message
  }

  open class func videoMessage(filePath: String) -> NIMMessage {
    let messageObject = NIMVideoObject(sourcePath: filePath)
    let message = NIMMessage()
    message.messageObject = messageObject
    message.apnsContent = chatLocalizable("send_video")
    message.setting = messageSetting()
    return message
  }

  open class func locationMessage(_ lat: Double, _ lng: Double, _ title: String, _ address: String) -> NIMMessage {
    let messageObject = NIMLocationObject(latitude: lat, longitude: lng, title: address)
    let message = NIMMessage()
    message.messageObject = messageObject
    message.text = title
    message.apnsContent = chatLocalizable("send_location")
    message.setting = messageSetting()
    return message
  }

  open class func fileMessage(filePath: String, displayName: String?) -> NIMMessage {
    let messageObject = NIMFileObject(sourcePath: filePath)
    if let dpName = displayName {
      messageObject.displayName = dpName
    }
    let message = NIMMessage()
    message.messageObject = messageObject
    message.apnsContent = chatLocalizable("send_file")
    message.setting = messageSetting()
    return message
  }

  open class func fileMessage(data: Data, displayName: String?) -> NIMMessage {
    let dpName = displayName ?? ""
    let pointIndex = dpName.lastIndex(of: ".") ?? dpName.startIndex
    let suffix = dpName[dpName.index(after: pointIndex) ..< dpName.endIndex]
    let messageObject = NIMFileObject(data: data, extension: String(suffix))
    messageObject.displayName = dpName
    let message = NIMMessage()
    message.messageObject = messageObject
    message.apnsContent = chatLocalizable("send_file")
    message.setting = messageSetting()
    return message
  }

  open class func customMessage(attachment: NIMCustomAttachment?,
                                remoteExt: [String: Any]?,
                                apnsContent: String?) -> NIMMessage {
    let messageObject = NIMCustomObject()
    messageObject.attachment = attachment
    let message = NIMMessage()
    message.messageObject = messageObject
    message.apnsContent = apnsContent
    message.remoteExt = remoteExt
    message.setting = messageSetting()
    return message
  }

  open class func messageSetting() -> NIMMessageSetting {
    let setting = NIMMessageSetting()
    setting.teamReceiptEnabled = SettingProvider.shared.getMessageRead()
    return setting
  }
}
