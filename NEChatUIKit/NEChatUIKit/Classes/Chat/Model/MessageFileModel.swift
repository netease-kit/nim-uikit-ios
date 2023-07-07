
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
class MessageFileModel: MessageContentModel {
  public var displayName: String?
  public var path: String?
  public var url: String?
  public var fileLength: Int64?

  public var progress: Float = 0
  public var size: Float = 0
  public var state = DownloadState.Success
  public weak var cell: NEChatBaseCell?

  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .file
    if let fileObject = message?.messageObject as? NIMFileObject {
      displayName = fileObject.displayName
      path = fileObject.path
      url = fileObject.url
      fileLength = fileObject.fileLength
    }
    contentSize = chat_file_size
    height = Float(contentSize.height + chat_content_margin) + fullNameHeight
  }
}
