
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class MessageFileModel: MessageContentModel {
  public var displayName: String?
  public var path: String?
  public var url: String?
  public var fileLength: Int64?

  public var progress: Float = 0
  public var size: Float = 0
  public var state = DownloadState.Success
  public weak var cell: NEChatBaseCell?

  public required init(message: NIMMessage?) {
    super.init(message: message)
    type = .file
    if let fileObject = message?.messageObject as? NIMFileObject {
      displayName = fileObject.displayName
      path = fileObject.path
      url = fileObject.url
      fileLength = fileObject.fileLength
    }
    contentSize = chat_file_size
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight
  }
}
