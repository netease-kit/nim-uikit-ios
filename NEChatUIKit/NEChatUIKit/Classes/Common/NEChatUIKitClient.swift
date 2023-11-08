
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objc
@objcMembers
public class NEChatUIKitClient: NSObject {
  public static let instance = NEChatUIKitClient()
  private var customRegisterDic = [String: UITableViewCell.Type]()
  public var moreAction = [NEMoreItemModel]()

  override init() {
    let picture = NEMoreItemModel()
    picture.image = UIImage.ne_imageNamed(name: "chat_takePicture")
    picture.title = chatLocalizable("chat_takePicture")
    picture.type = .takePicture
    moreAction.append(picture)

    let location = NEMoreItemModel()
    location.image = UIImage.ne_imageNamed(name: "chat_location")
    location.title = chatLocalizable("chat_location")
    location.type = .location
    moreAction.append(location)

    let file = NEMoreItemModel()
    file.image = UIImage.ne_imageNamed(name: "chat_file")
    file.title = chatLocalizable("chat_file")
    file.type = .file
    moreAction.append(file)

    if XKitServiceManager.getInstance().serviceIsRegister("NERtcCallUIKit") == true {
      let rtc = NEMoreItemModel()
      rtc.image = UIImage.ne_imageNamed(name: "chat_rtc")
      rtc.title = chatLocalizable("chat_rtc")
      rtc.type = .rtc
      moreAction.append(rtc)
    }
  }

  /// 获取更多面板数据
  /// - Returns: 返回更多操作数据
  public func getMoreActionData(sessionType: NIMSessionType) -> [NEMoreItemModel] {
    var more = [NEMoreItemModel]()
    moreAction.forEach { model in
      if model.type != .rtc {
        more.append(model)
      } else if sessionType == .P2P {
        more.append(model)
      }
    }
    return more
  }

  /// 新增聊天页针对自定义消息的cell扩展，以及现有cell样式覆盖
  public func regsiterCustomCell(_ registerDic: [String: UITableViewCell.Type]) {
    registerDic.forEach { (key: String, value: UITableViewCell.Type) in
      customRegisterDic[key] = value
    }
  }

  public func getRegisterCustomCell() -> [String: UITableViewCell.Type] {
    customRegisterDic
  }
}
