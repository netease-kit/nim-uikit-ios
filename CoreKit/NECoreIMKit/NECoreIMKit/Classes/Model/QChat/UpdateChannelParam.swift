
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct UpdateChannelParam {
  public var channelId: UInt64?
  public var name: String?
  public var topic: String?
  public var custom: String?

  public init(channelId: UInt64?) {
    self.channelId = channelId
  }

  public func toIMParam() -> NIMQChatUpdateChannelParam {
    let imParam = NIMQChatUpdateChannelParam()
    imParam.channelId = channelId ?? 0
    if let n = name {
      imParam.name = n
    }

    if let t = topic {
      imParam.topic = t
    }

    if let c = custom {
      imParam.custom = c
    }
    return imParam
  }
}

/*
 @interface NIMQChatUpdateChannelParam : NSObject

 /**
  * 频道id
  */
 @property (nonatomic, assign) unsigned long long channelId;

 /**
  * 名称
  */
 @property (nonatomic, copy)   NSString *name;

 /**
  * 主题
  */
 @property (nonatomic, copy)   NSString *topic;

 /**
  * 自定义扩展
  */
 @property (nonatomic, copy)   NSString *custom;
 */
