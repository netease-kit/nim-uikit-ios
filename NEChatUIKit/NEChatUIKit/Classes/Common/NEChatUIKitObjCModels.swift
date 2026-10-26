// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

@objc(NEChatUIKitImageResource)
@objcMembers
public final class NEChatUIKitImageResourceObjC: NSObject {
  public let name: String
  public let bundle: Bundle
  private let resource: NEChatKitImageResource

  init(resource: NEChatKitImageResource) {
    self.resource = resource
    name = resource.name
    bundle = resource.bundle
    super.init()
  }

  public var image: UIImage? {
    resource.uiImage
  }
}

@objc(BotSubSessionItem)
@objcMembers
public final class BotSubSessionItemObjC: NSObject {
  public let topic: V2NIMTopic
  public var summary: String?
  public var updateTime: TimeInterval
  public var hasUnread: Bool

  public init(topic: V2NIMTopic,
              summary: String?,
              updateTime: TimeInterval,
              hasUnread: Bool) {
    self.topic = topic
    self.summary = summary
    self.updateTime = updateTime
    self.hasUnread = hasUnread
    super.init()
  }

  convenience init(_ value: BotSubSessionItem) {
    self.init(topic: value.topic,
              summary: value.summary,
              updateTime: value.updateTime,
              hasUnread: value.hasUnread)
  }

  var swiftValue: BotSubSessionItem {
    BotSubSessionItem(topic: topic,
                      summary: summary,
                      updateTime: updateTime,
                      hasUnread: hasUnread)
  }
}

@objc(LastReadPositionStateKind)
public enum LastReadPositionStateKindObjC: Int {
  case disabled
  case ready
  case visible
  case locating
  case consumed
}

@objc(LastReadPositionState)
@objcMembers
public final class LastReadPositionStateObjC: NSObject {
  public let kind: LastReadPositionStateKindObjC
  public let snapshot: NELastReadPositionSnapshot?

  public init(kind: LastReadPositionStateKindObjC,
              snapshot: NELastReadPositionSnapshot?) {
    self.kind = kind
    self.snapshot = snapshot
    super.init()
  }

  convenience init(_ state: LastReadPositionState) {
    switch state {
    case .disabled:
      self.init(kind: .disabled, snapshot: nil)
    case .ready:
      self.init(kind: .ready, snapshot: nil)
    case let .visible(snapshot):
      self.init(kind: .visible, snapshot: snapshot)
    case let .locating(snapshot):
      self.init(kind: .locating, snapshot: snapshot)
    case .consumed:
      self.init(kind: .consumed, snapshot: nil)
    }
  }
}

@objc(NEMarkdownTableAlignment)
public enum NEMarkdownTableAlignmentObjC: Int {
  case left
  case center
  case right
}

@objc(NEMarkdownTableData)
@objcMembers
public final class NEMarkdownTableDataObjC: NSObject {
  public let headers: [String]
  public let alignments: [NSNumber]
  public let rows: [[String]]

  public var columnCount: Int { headers.count }

  public init(headers: [String], alignments: [NSNumber], rows: [[String]]) {
    self.headers = headers
    self.alignments = alignments
    self.rows = rows
    super.init()
  }

  public func alignment(at column: Int) -> NEMarkdownTableAlignmentObjC {
    guard column >= 0,
          column < alignments.count,
          let alignment = NEMarkdownTableAlignmentObjC(rawValue: alignments[column].intValue) else {
      return .left
    }
    return alignment
  }

  convenience init(_ value: NEMarkdownTableData) {
    self.init(headers: value.headers,
              alignments: value.alignments.map { NSNumber(value: $0.objcValue.rawValue) },
              rows: value.rows)
  }

  var swiftValue: NEMarkdownTableData {
    NEMarkdownTableData(headers: headers,
                        alignments: alignments.map {
                          NEMarkdownTableAlignmentObjC(rawValue: $0.intValue)?.swiftValue ?? .left
                        },
                        rows: rows)
  }
}

private extension NEMarkdownTableAlignment {
  var objcValue: NEMarkdownTableAlignmentObjC {
    switch self {
    case .left: return .left
    case .center: return .center
    case .right: return .right
    }
  }
}

private extension NEMarkdownTableAlignmentObjC {
  var swiftValue: NEMarkdownTableAlignment {
    switch self {
    case .left: return .left
    case .center: return .center
    case .right: return .right
    }
  }
}

@objc(NEMarkdownEnabledElements)
@objcMembers
public final class NEMarkdownEnabledElementsObjC: NSObject {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue = rawValue
    super.init()
  }

  public static var automaticLink: NEMarkdownEnabledElementsObjC { .init(.automaticLink) }
  public static var header: NEMarkdownEnabledElementsObjC { .init(.header) }
  public static var list: NEMarkdownEnabledElementsObjC { .init(.list) }
  public static var quote: NEMarkdownEnabledElementsObjC { .init(.quote) }
  public static var link: NEMarkdownEnabledElementsObjC { .init(.link) }
  public static var bold: NEMarkdownEnabledElementsObjC { .init(.bold) }
  public static var italic: NEMarkdownEnabledElementsObjC { .init(.italic) }
  public static var code: NEMarkdownEnabledElementsObjC { .init(.code) }
  public static var strikethrough: NEMarkdownEnabledElementsObjC { .init(.strikethrough) }
  public static var table: NEMarkdownEnabledElementsObjC { .init(.table) }
  public static var orderedList: NEMarkdownEnabledElementsObjC { .init(.orderedList) }
  public static var horizontalRule: NEMarkdownEnabledElementsObjC { .init(.horizontalRule) }
  public static var image: NEMarkdownEnabledElementsObjC { .init(.image) }
  public static var disabledAutomaticLink: NEMarkdownEnabledElementsObjC { .init(.disabledAutomaticLink) }
  public static var all: NEMarkdownEnabledElementsObjC { .init(.all) }

  public func contains(_ other: NEMarkdownEnabledElementsObjC) -> Bool {
    (rawValue & other.rawValue) == other.rawValue
  }

  public func adding(_ other: NEMarkdownEnabledElementsObjC) -> NEMarkdownEnabledElementsObjC {
    NEMarkdownEnabledElementsObjC(rawValue: rawValue | other.rawValue)
  }

  public func removing(_ other: NEMarkdownEnabledElementsObjC) -> NEMarkdownEnabledElementsObjC {
    NEMarkdownEnabledElementsObjC(rawValue: rawValue & ~other.rawValue)
  }

  convenience init(_ value: NEMarkdownParser.NEEnabledElements) {
    self.init(rawValue: UInt(value.rawValue))
  }

  var swiftValue: NEMarkdownParser.NEEnabledElements {
    .init(rawValue: Int(rawValue))
  }
}

@objc(NEMarkdownElement)
public protocol NEMarkdownElementObjC: NSObjectProtocol {
  var regex: String { get }
  func regularExpression() throws -> NSRegularExpression
  func parse(_ attributedString: NSMutableAttributedString)
  func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString)
}

@objc(NEMarkdownStyle)
public protocol NEMarkdownStyleObjC: NSObjectProtocol {
  var font: UIFont? { get }
  var color: UIColor? { get }
  @objc(attributes) var objcAttributes: NSDictionary { get }
}

@objc(NEMarkdownCommonElement)
public protocol NEMarkdownCommonElementObjC: NEMarkdownElementObjC, NEMarkdownStyleObjC {
  func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange)
}

@objc(NEMarkdownLevelElement)
public protocol NEMarkdownLevelElementObjC: NEMarkdownElementObjC, NEMarkdownStyleObjC {
  var maxLevel: Int { get }
  func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int)
  func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int)
  @objc(attributesForLevel:) func objcAttributes(forLevel level: Int) -> NSDictionary
}

@objc(NEMarkdownLinkElement)
public protocol NEMarkdownLinkElementObjC: NEMarkdownElementObjC, NEMarkdownStyleObjC {
  func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, link: String)
  func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange, link: String)
}

final class NEMarkdownObjCElementAdapter: NEMarkdownElement {
  let source: NEMarkdownElementObjC

  init(_ source: NEMarkdownElementObjC) {
    self.source = source
  }

  var regex: String { source.regex }

  func regularExpression() throws -> NSRegularExpression {
    try source.regularExpression()
  }

  func parse(_ attributedString: NSMutableAttributedString) {
    source.parse(attributedString)
  }

  func match(_ match: NSTextCheckingResult,
             attributedString: NSMutableAttributedString) {
    source.match(match, attributedString: attributedString)
  }
}

final class NEMarkdownSwiftElementAdapter: NSObject, NEMarkdownElementObjC {
  let source: NEMarkdownElement

  init(_ source: NEMarkdownElement) {
    self.source = source
  }

  var regex: String { source.regex }

  func regularExpression() throws -> NSRegularExpression {
    try source.regularExpression()
  }

  func parse(_ attributedString: NSMutableAttributedString) {
    source.parse(attributedString)
  }

  func match(_ match: NSTextCheckingResult,
             attributedString: NSMutableAttributedString) {
    source.match(match, attributedString: attributedString)
  }
}

@objc(NEChatMessageDeletionResult)
@objcMembers
public final class NEChatMessageDeletionResult: NSObject {
  public let deletedIndexes: [NSNumber]
  public let reloadedIndexes: [NSNumber]

  init(deleteIndexes: [Int], reloadIndexes: [Int]) {
    deletedIndexes = deleteIndexes.map(NSNumber.init(value:))
    reloadedIndexes = reloadIndexes.map(NSNumber.init(value:))
    super.init()
  }
}

@objc(NEChatTextMentionSplitResult)
@objcMembers
public final class NEChatTextMentionSplitResult: NSObject {
  public let parts: [String]
  public let atFlags: [NSNumber]

  init(parts: [String], atFlags: [Bool]) {
    self.parts = parts
    self.atFlags = atFlags.map(NSNumber.init(value:))
    super.init()
  }
}

@objc(NENotificationTeamStateResult)
@objcMembers
public final class NENotificationTeamStateResult: NSObject {
  public let isLeave: Bool
  public let isDismiss: Bool

  init(isLeave: Bool, isDismiss: Bool) {
    self.isLeave = isLeave
    self.isDismiss = isDismiss
    super.init()
  }
}
