
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class MessageUtils: NSObject {
  @nonobjc
  open class func textMessage(text: String, remoteExt: [String: Any]?) -> V2NIMMessage {
    let message = V2NIMMessageCreator.createTextMessage(text)
    if let remoteExt = remoteExt {
      message.serverExtension = getJSONStringFromDictionary(remoteExt)
    }
    return message
  }

  @nonobjc
  open class func textMessage(text: String) -> V2NIMMessage {
    V2NIMMessageCreator.createTextMessage(text)
  }

  @nonobjc
  open class func forwardMessage(message: V2NIMMessage) -> V2NIMMessage {
    let forwardMessage = V2NIMMessageCreator.createForwardMessage(message)
    // 译文是本地展示缓存，不属于消息正文；转发时只带走原文，避免被转发方看到译文。
    if let cleared = TranslationInfo.cleared(from: forwardMessage.localExtension) {
      forwardMessage.localExtension = cleared
    }
    return forwardMessage
  }

  @nonobjc
  open class func imageMessage(path: String,
                               name: String?,
                               sceneName: String?,
                               width: Int32,
                               height: Int32) -> V2NIMMessage {
    V2NIMMessageCreator.createImageMessage(path,
                                           name: name,
                                           sceneName: sceneName ?? V2NIMStorageSceneConfig.default_IM().sceneName,
                                           width: width,
                                           height: height)
  }

  @nonobjc
  open class func audioMessage(filePath: String,
                               name: String?,
                               sceneName: String?,
                               duration: Int32) -> V2NIMMessage {
    V2NIMMessageCreator.createAudioMessage(filePath, name: name,
                                           sceneName: sceneName ?? V2NIMStorageSceneConfig.default_IM().sceneName,
                                           duration: duration)
  }

  @nonobjc
  open class func videoMessage(filePath: String,
                               name: String?,
                               sceneName: String?,
                               width: Int32,
                               height: Int32,
                               duration: Int32) -> V2NIMMessage {
    V2NIMMessageCreator.createVideoMessage(filePath,
                                           name: name,
                                           sceneName: sceneName ?? V2NIMStorageSceneConfig.default_IM().sceneName,
                                           duration: duration,
                                           width: width,
                                           height: height)
  }

  @nonobjc
  open class func locationMessage(lat: Double,
                                  lng: Double,
                                  address: String) -> V2NIMMessage {
    V2NIMMessageCreator.createLocationMessage(lat, longitude: lng, address: address)
  }

  @nonobjc
  open class func fileMessage(filePath: String,
                              displayName: String?,
                              sceneName: String?) -> V2NIMMessage {
    V2NIMMessageCreator.createFileMessage(filePath,
                                          name: displayName,
                                          sceneName: sceneName ?? V2NIMStorageSceneConfig.default_IM().sceneName)
  }

  @nonobjc
  open class func customMessage(text: String,
                                rawAttachment: String) -> V2NIMMessage {
    V2NIMMessageCreator.createCustomMessage(text, rawAttachment: rawAttachment)
  }

  @nonobjc
  open class func tipMessage(text: String) -> V2NIMMessage {
    V2NIMMessageCreator.createTipsMessage(text)
  }

  @objc(textMessageWithText:remoteExt:)
  open class func objc_textMessage(withText text: String,
                                   remoteExt: [String: Any]?) -> V2NIMMessage {
    textMessage(text: text, remoteExt: remoteExt)
  }

  @objc(textMessageWithText:)
  open class func objc_textMessage(withText text: String) -> V2NIMMessage {
    textMessage(text: text)
  }

  @objc(forwardMessageWithMessage:)
  open class func objc_forwardMessage(withMessage message: V2NIMMessage) -> V2NIMMessage {
    forwardMessage(message: message)
  }

  @objc(imageMessageWithPath:name:sceneName:width:height:)
  open class func objc_imageMessage(withPath path: String,
                                    name: String?,
                                    sceneName: String?,
                                    width: Int32,
                                    height: Int32) -> V2NIMMessage {
    imageMessage(path: path, name: name, sceneName: sceneName, width: width, height: height)
  }

  @objc(audioMessageWithFilePath:name:sceneName:duration:)
  open class func objc_audioMessage(withFilePath filePath: String,
                                    name: String?,
                                    sceneName: String?,
                                    duration: Int32) -> V2NIMMessage {
    audioMessage(filePath: filePath, name: name, sceneName: sceneName, duration: duration)
  }

  @objc(videoMessageWithFilePath:name:sceneName:width:height:duration:)
  open class func objc_videoMessage(withFilePath filePath: String,
                                    name: String?,
                                    sceneName: String?,
                                    width: Int32,
                                    height: Int32,
                                    duration: Int32) -> V2NIMMessage {
    videoMessage(filePath: filePath,
                 name: name,
                 sceneName: sceneName,
                 width: width,
                 height: height,
                 duration: duration)
  }

  @objc(locationMessageWithLat:lng:address:)
  open class func objc_locationMessage(withLat lat: Double,
                                       lng: Double,
                                       address: String) -> V2NIMMessage {
    locationMessage(lat: lat, lng: lng, address: address)
  }

  @objc(fileMessageWithFilePath:displayName:sceneName:)
  open class func objc_fileMessage(withFilePath filePath: String,
                                   displayName: String?,
                                   sceneName: String?) -> V2NIMMessage {
    fileMessage(filePath: filePath, displayName: displayName, sceneName: sceneName)
  }

  @objc(customMessageWithText:rawAttachment:)
  open class func objc_customMessage(withText text: String,
                                     rawAttachment: String) -> V2NIMMessage {
    customMessage(text: text, rawAttachment: rawAttachment)
  }

  @objc(tipMessageWithText:)
  open class func objc_tipMessage(withText text: String) -> V2NIMMessage {
    tipMessage(text: text)
  }
}
