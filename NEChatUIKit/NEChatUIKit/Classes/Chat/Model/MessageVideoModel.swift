
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objc
public enum DownloadState: Int {
  case Success = 1
  case Downalod
}

@objcMembers
open class MessageVideoModel: MessageImageModel {
  public var state = DownloadState.Success
  public var progress: UInt = 0

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .video
    if let videoObject = message?.attachment as? V2NIMMessageVideoAttachment {
      contentSize = ChatMessageHelper.getSizeWithMaxSize(
        chat_pic_size,
        size: CGSize(width: videoObject.width, height: videoObject.height),
        miniWH: chat_min_h
      )
    } else {
      contentSize = chat_pic_size
    }
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  /// 设置（视频、文件）消息模型（上传、下载）进度
  /// - Parameters:
  ///   - progress:（上传、下载）进度
  public func setModelProgress(_ progress: UInt) {
    if progress == 100 {
      state = .Success
    } else {
      state = .Downalod
    }

    cell?.uploadProgress(progress)
  }
}
