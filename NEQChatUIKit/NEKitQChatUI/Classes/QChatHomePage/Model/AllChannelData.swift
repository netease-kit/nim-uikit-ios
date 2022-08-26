
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitQChat
import NEKitCoreIM

protocol AllChannelDataDelegate: AnyObject {
  func dataGetSuccess(_ serverId: UInt64, _ channels: [ChatChannel])
  func dataGetError(_ serverId: UInt64, _ error: Error)
}

public class AllChannelData {
  var repo = QChatRepo()
  let limit = 200
  weak var delegate: AllChannelDataDelegate?
  var serverId: UInt64
  var channelInfos = [ChatChannel]()
  public var nextTimetag: TimeInterval = 0

  init(sid: UInt64) {
    serverId = sid
    getChannelData()
  }

  func getChannelData() {
    var param = QChatGetChannelsByPageParam(timeTag: nextTimetag, serverId: serverId)
    param.limit = 200
    weak var weakSelf = self
    repo.getChannelsByPage(param: param) { error, result in
      if let err = error {
        if let sid = weakSelf?.serverId {
          weakSelf?.delegate?.dataGetError(sid, err)
        }
      } else {
        if let datas = result?.channels {
          weakSelf?.channelInfos.append(contentsOf: datas)
        }
        if let nextTimeTag = result?.nextTimetag {
          weakSelf?.nextTimetag = nextTimeTag
        }
        if let hasMore = result?.hasMore, hasMore == true {
          weakSelf?.getChannelData()
        } else {
          print("getChannelData finish : ", weakSelf?.serverId as Any)
          if let sid = weakSelf?.serverId, let channels = weakSelf?.channelInfos {
            weakSelf?.delegate?.dataGetSuccess(sid, channels)
          }
        }
      }
    }
  }
}
