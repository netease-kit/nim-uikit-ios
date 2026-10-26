// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

public extension BotSubSessionListViewModel {
  @objc(itemAtIndex:)
  func objcItem(at index: Int) -> BotSubSessionItemObjC? {
    item(at: index).map(BotSubSessionItemObjC.init)
  }
}

public extension BotSubSessionListCell {
  @objc(configureWithItem:sessionName:keyword:highlightColor:)
  func objcConfigure(item: BotSubSessionItemObjC,
                     sessionName: String,
                     keyword: String,
                     highlightColor: UIColor) {
    configure(item: item.swiftValue,
              sessionName: sessionName,
              keyword: keyword,
              highlightColor: highlightColor)
  }
}

public extension ChatUIConfig {
  @objc(chatInputBar)
  var objcChatInputBar: ((ChatViewController?, [UIButton]) -> [UIButton])? {
    get {
      guard let callback = chatInputBar else { return nil }
      return { controller, buttons in
        var result = buttons
        callback(controller, &result)
        return result
      }
    }
    set {
      guard let callback = newValue else {
        chatInputBar = nil
        return
      }
      chatInputBar = { controller, buttons in
        buttons = callback(controller, buttons)
      }
    }
  }

  @objc(chatInputMenu)
  var objcChatInputMenu: ((ChatViewController, [NEMoreItemModel]) -> [NEMoreItemModel])? {
    get {
      guard let callback = chatInputMenu else { return nil }
      return { controller, items in
        var result = items
        callback(controller, &result)
        return result
      }
    }
    set {
      guard let callback = newValue else {
        chatInputMenu = nil
        return
      }
      chatInputMenu = { controller, items in
        items = callback(controller, items)
      }
    }
  }

  @objc(chatPopMenu)
  var objcChatPopMenu: ((ChatViewController, [OperationItem], MessageContentModel?) -> [OperationItem])? {
    get {
      guard let callback = chatPopMenu else { return nil }
      return { controller, items, model in
        var result = items
        callback(controller, &result, model)
        return result
      }
    }
    set {
      guard let callback = newValue else {
        chatPopMenu = nil
        return
      }
      chatPopMenu = { controller, items, model in
        items = callback(controller, items, model)
      }
    }
  }
}

public extension MessageProperties {
  @objc(backgroundImageCapInsets)
  var objcBackgroundImageCapInsets: NSValue? {
    get { backgroundImageCapInsets.map(NSValue.init(uiEdgeInsets:)) }
    set { backgroundImageCapInsets = newValue?.uiEdgeInsetsValue }
  }
}

public extension MessageContentModel {
  @objc(selectRange)
  var objcSelectRange: NSValue? {
    get { selectRange.map(NSValue.init(range:)) }
    set { selectRange = newValue?.rangeValue }
  }
}

public extension MessageFileModel {
  @objc(fileLength)
  var objcFileLength: NSNumber? {
    get { fileLength.map(NSNumber.init(value:)) }
    set { fileLength = newValue?.int64Value }
  }
}

public extension MessageLocationModel {
  @objc(lat)
  var objcLatitude: NSNumber? {
    get { lat.map(NSNumber.init(value:)) }
    set { lat = newValue?.doubleValue }
  }

  @objc(lng)
  var objcLongitude: NSNumber? {
    get { lng.map(NSNumber.init(value:)) }
    set { lng = newValue?.doubleValue }
  }
}

public extension NEMoreItemModel {
  @objc(type)
  var objcType: NSNumber? {
    get { type.map { NSNumber(value: $0.rawValue) } }
    set { type = newValue.flatMap { NEMoreActionType(rawValue: $0.intValue) } }
  }
}

public extension NIMInputEmoticonLayout {
  @objc(emoji)
  var objcEmoji: NSNumber? {
    get { emoji.map(NSNumber.init(value:)) }
    set { emoji = newValue?.boolValue }
  }
}

public extension UserSettingCellModel {
  @objc(cornerType)
  var objcCornerType: Int {
    get { cornerType.rawValue }
    set { cornerType = CornerType(rawValue: newValue) }
  }
}

public extension NEBaseUserSettingCell {
  @objc(subCornerType)
  var objcSubCornerType: Int {
    get { subCornerType.rawValue }
    set { subCornerType = CornerType(rawValue: newValue) }
  }
}
