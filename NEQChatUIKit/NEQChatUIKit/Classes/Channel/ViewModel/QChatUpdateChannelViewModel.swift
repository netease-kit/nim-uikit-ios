// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NEQChatKit

@objcMembers
public class QChatUpdateChannelViewModel: NSObject {
  public var channel: ChatChannel?
  // 临时记录修改的值
  public var channelTmp: ChatChannel?
  private let className = "QChatUpdateChannelViewModel"

  init(channel: ChatChannel?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    self.channel = channel
    channelTmp = channel
  }

  func updateChannelInfo(completion: @escaping (NSError?, ChatChannel?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    var param = UpdateChannelParam(channelId: channel?.channelId)
    param.name = channelTmp?.name
    param.topic = channelTmp?.topic
    param.custom = channelTmp?.custom
    QChatRepo().updateChannelInfo(param) { [weak self] error, channel in
      if error == nil {
        self?.channel = channel
      }
      completion(error, channel)
    }
  }

  func deleteChannel(completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    QChatChannelProvider.shared.deleteChannel(channelId: channel?.channelId, completion)
  }
}
