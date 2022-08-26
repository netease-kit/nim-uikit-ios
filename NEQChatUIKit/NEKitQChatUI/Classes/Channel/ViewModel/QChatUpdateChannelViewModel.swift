
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitCoreIM
import NEKitQChat

public class QChatUpdateChannelViewModel {
  public var channel: ChatChannel?
  // 临时记录修改的值
  public var channelTmp: ChatChannel?
  init(channel: ChatChannel?) {
    self.channel = channel
    channelTmp = channel
  }

  func updateChannelInfo(completion: @escaping (NSError?, ChatChannel?) -> Void) {
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
    QChatChannelProvider.shared.deleteChannel(channelId: channel?.channelId, completion)
  }
}
