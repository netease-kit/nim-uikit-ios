
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
enum MessageType: Int {
  case Text = 0, Image, Audio, Video, Location, Notification, File, Tip, Robot, RtcCallRecord,
       Custom
}

enum MessageDeliveryState: Int {
  case Failed = 0, Delivering, Deliveried
}

enum MessageAttachmentDownloadState: Int {
  case NeedDownload = 0, Failed, Downloading, Downloaded
}

enum MessageState: Int {
  case Init = 0, Revoked, Deleted, Custom
}

class QMessage {
  var messageType: MessageType?
  var session: AnyObject?
  var messageId: String?
  var serverID: String?
  var text: String?
//    消息附件内容
//    let messageObject: NIMMessageObject?
//    消息设置
//    let setting: NIMMessageSetting?

//    消息推送文案,长度限制500字,撤回消息时该字段无效
  var apnsContent: String?
//    消息推送Payload
  var apnsPayload: [String: Any]?
//    客户端可以设置这个字段,这个字段将在本地存储且发送至对端,上层需要保证 NSDictionary 可以转换为 JSON，长度限制 1K
  var remoteExt: [String: Any]?
//    客户端可以设置这个字段，这个字段只在本地存储,不会发送至对端,上层需要保证 NSDictionary 可以转换为 JSON
  var localExt: [String: Any]?
//    消息发送时间 发送成功后将被服务器自动修正
  var timestamp: TimeInterval?
//    消息投递状态 仅针对发送的消息
  var deliveryState: MessageDeliveryState?
//    消息附件下载状态 仅针对收到的消息
  var attachmentDownloadState: MessageAttachmentDownloadState?
//    是否是收到的消息
  var isReceivedMsg: Bool?
//    是否是往外发的消息
  var isOutgoingMsg: Bool?
//    消息是否标记为已删除
  var isDeleted: Bool?
  var isRevoked: Bool?

  var status: MessageState?

  var from: String?
  var senderName: String?
  var qchatChannelId: UInt64?
  var qchatServerId: UInt64?
  var mentionedAll: Bool?
  var mentionedAccids: [String]?
  var updateTimestamp: TimeInterval?
}
