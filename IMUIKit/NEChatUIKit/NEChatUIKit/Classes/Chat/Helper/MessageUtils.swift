
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
open class MessageUtils: NSObject {
  open class func textMessage(text: String, remoteExt: [String: Any]?) -> V2NIMMessage {
    let message = V2NIMMessageCreator.createTextMessage(text)
    if let remoteExt = remoteExt {
      message.serverExtension = getJSONStringFromDictionary(remoteExt)
    }
    return message
  }

  open class func textMessage(text: String) -> V2NIMMessage {
    V2NIMMessageCreator.createTextMessage(text)
  }

  open class func forwardMessage(message: V2NIMMessage) -> V2NIMMessage {
    V2NIMMessageCreator.createForwardMessage(message)
  }

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

  open class func audioMessage(filePath: String,
                               name: String?,
                               sceneName: String?,
                               duration: Int32) -> V2NIMMessage {
    V2NIMMessageCreator.createAudioMessage(filePath, name: name,
                                           sceneName: sceneName ?? V2NIMStorageSceneConfig.default_IM().sceneName,
                                           duration: duration)
  }

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

  open class func locationMessage(lat: Double,
                                  lng: Double,
                                  address: String) -> V2NIMMessage {
    V2NIMMessageCreator.createLocationMessage(lat, longitude: lng, address: address)
  }

  open class func fileMessage(filePath: String,
                              displayName: String?,
                              sceneName: String?) -> V2NIMMessage {
    V2NIMMessageCreator.createFileMessage(filePath,
                                          name: displayName,
                                          sceneName: sceneName ?? V2NIMStorageSceneConfig.default_IM().sceneName)
  }

  open class func customMessage(text: String,
                                rawAttachment: String) -> V2NIMMessage {
    V2NIMMessageCreator.createCustomMessage(text, rawAttachment: rawAttachment)
  }

  open class func tipMessage(text: String) -> V2NIMMessage {
    V2NIMMessageCreator.createTipsMessage(text)
  }
}
