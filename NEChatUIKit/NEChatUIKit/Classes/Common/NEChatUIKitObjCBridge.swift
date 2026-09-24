// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

/// Objective-C entry points for public module-level Swift declarations.
@objcMembers
public final class NEChatUIKitObjCBridge: NSObject {
  public static var chatBundle: Bundle {
    chatUIKitLoader.bundle
  }

  @objc(chatLocalizable:)
  public static func objcChatLocalizable(_ key: String) -> String {
    chatLocalizable(key)
  }

  public static func chatLoadImage(_ name: String) -> UIImage? {
    chatUIKitLoader.loadImage(name)
  }

  public static func chatImageResource(_ name: String) -> NEChatUIKitImageResourceObjC {
    NEChatUIKitImageResourceObjC(resource: chatUIKitLoader.loadImageResource(name))
  }

  public static func chatResourcePath(_ source: String?, type: String?) -> String? {
    chatUIKitLoader.loadString(source: source, type: type)
  }

  public static func jsonString(from dictionary: [String: Any]) -> String {
    getJSONStringFromDictionary(dictionary)
  }

  public static func dictionary(fromJSONString jsonString: String) -> NSDictionary? {
    getDictionaryFromJSONString(jsonString)
  }

  public static var screenWidth: CGFloat { kScreenWidth }
  public static var screenHeight: CGFloat { kScreenHeight }
  public static var screenWidthScale: CGFloat { kUISreenWidthScale }
  public static var screenHeightScale: CGFloat { kUISreenHeightScale }
  public static var navigationHeight: CGFloat { kNavigationHeight }
  public static var statusBarHeight: CGFloat { KStatusBarHeight }
  public static var moduleName: String { ModuleName }

  public static var supportedAudioFileExtensions: [String] { file_audio_support }
  public static var supportedVideoFileExtensions: [String] { file_video_support }
  public static var supportedImageFileExtensions: [String] { file_img_support }
  public static var supportedSpreadsheetFileExtensions: [String] { file_xls_support }
  public static var supportedDocumentFileExtensions: [String] { file_doc_support }
  public static var supportedPresentationFileExtensions: [String] { file_ppt_support }
  public static var supportedTextFileExtensions: [String] { file_txt_support }
  public static var supportedArchiveFileExtensions: [String] { file_zip_support }
  public static var supportedPDFFileExtensions: [String] { file_pdf_support }
  public static var supportedHTMLFileExtensions: [String] { file_html_support }

  public static var antispamResultCodes: [NSNumber: String] {
    Dictionary(uniqueKeysWithValues: antispamResultCodeDic.map { (NSNumber(value: $0.key), $0.value) })
  }

  public static var screenInterval: CGFloat { kScreenInterval }
  public static var moreViewSectionPadding: CGFloat { NEMoreView_Section_Padding }
  public static var moreCellReuseIdentifier: String { NEMoreCell_ReuseId }
  public static var moreCellImageSize: CGSize { NEMoreCell_Image_Size }
  public static var moreCellTitleHeight: CGFloat { NEMoreCell_Title_Height }
  public static var moreViewMargin: CGFloat { NEMoreView_Margin }
  public static var moreViewColumnCount: Int { NEMoreView_Column_Count }

  public static var chatCellMargin: CGFloat { chat_cell_margin }
  public static var chatContentMargin: CGFloat { chat_content_margin }
  public static var chatAvatarSize: CGFloat { chat_headWH }
  public static var chatTimeCellHeight: CGFloat { chat_timeCellH }
  public static var chatPictureSize: CGSize { chat_pic_size }
  public static var chatFileSize: CGSize { chat_file_size }
  public static var chatMinimumHeight: CGFloat { chat_min_h }
  public static var chatReplyHeight: CGFloat { chat_reply_height }
  public static var chatContentMaximumWidth: CGFloat { chat_content_maxW }
  public static var chatTextMaximumWidth: CGFloat { chat_text_maxW }
  public static var chatPinHeight: CGFloat { chat_pin_height }
  public static var chatFullNameHeight: CGFloat { chat_full_name_height }
  public static var audioMaximumWidth: CGFloat { audio_max_width }
  public static var aiChatViewHeight: CGFloat { ai_chat_view_height }

  public static var atMessageKey: String { yxAtMsg }
  public static var atRangeOffsetValue: Int { atRangeOffset }
  public static var atSegmentsKeyValue: String { atSegmentsKey }
  public static var atTextKeyValue: String { atTextKey }

  public static var emojiCatalog: String { NIMKit_EmojiCatalog }
  public static var emojiPath: String { NIMKit_EmojiPath }
  public static var chartletCatalogPath: String { NIMKit_ChartletChartletCatalogPath }
  public static var chartletCatalogContentPath: String { NIMKit_ChartletChartletCatalogContentPath }
  public static var chartletCatalogIconPath: String { NIMKit_ChartletChartletCatalogIconPath }
  public static var chartletNormalIconSuffix: String { NIMKit_ChartletChartletCatalogIconsSuffixNormal }
  public static var chartletHighlightedIconSuffix: String { NIMKit_ChartletChartletCatalogIconsSuffixHighLight }
  public static var emojiLeftMargin: Int { NIMKit_EmojiLeftMargin }
  public static var emojiRightMargin: Int { NIMKit_EmojiRightMargin }
  public static var emojiTopMargin: Int { NIMKit_EmojiTopMargin }
  public static var deleteIconWidth: CGFloat { NIMKit_DeleteIconWidth }
  public static var deleteIconHeight: CGFloat { NIMKit_DeleteIconHeight }
  public static var emojiCellHeight: CGFloat { NIMKit_EmojCellHeight }
  public static var emojiImageHeight: CGFloat { NIMKit_EmojImageHeight }
  public static var emojiImageWidth: CGFloat { NIMKit_EmojImageWidth }
  public static var emojiRows: Int { NIMKit_EmojRows }
  public static var pictureCellHeight: CGFloat { NIMKit_PicCellHeight }
  public static var pictureImageHeight: CGFloat { NIMKit_PicImageHeight }
  public static var pictureImageWidth: CGFloat { NIMKit_PicImageWidth }
  public static var pictureRows: Int { NIMKit_PicRows }

  public static var markdownImageDidLoadNotification: Notification.Name {
    NEMarkdownImageDidLoadNotification
  }

  public static func invokeSelectionHandler(
    _ handler: @escaping (Int, NETeamMemberInfoModel?) -> Void,
    index: Int,
    model: NETeamMemberInfoModel?
  ) {
    handler(index, model)
  }
}

@objc(NEChatUIKitImageResource)
@objcMembers
public final class NEChatUIKitImageResourceObjC: NSObject {
  public let name: String
  public let bundle: Bundle
  private let resource: NEChatKitImageResource

  fileprivate init(resource: NEChatKitImageResource) {
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

  fileprivate convenience init(_ value: BotSubSessionItem) {
    self.init(topic: value.topic,
              summary: value.summary,
              updateTime: value.updateTime,
              hasUnread: value.hasUnread)
  }

  fileprivate var swiftValue: BotSubSessionItem {
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

  fileprivate convenience init(_ state: LastReadPositionState) {
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

  fileprivate convenience init(_ value: NEMarkdownTableData) {
    self.init(headers: value.headers,
              alignments: value.alignments.map { NSNumber(value: $0.objcValue.rawValue) },
              rows: value.rows)
  }

  fileprivate var swiftValue: NEMarkdownTableData {
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

  fileprivate convenience init(_ value: NEMarkdownParser.NEEnabledElements) {
    self.init(rawValue: UInt(value.rawValue))
  }

  fileprivate var swiftValue: NEMarkdownParser.NEEnabledElements {
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

private final class NEMarkdownObjCElementAdapter: NEMarkdownElement {
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

private final class NEMarkdownSwiftElementAdapter: NSObject, NEMarkdownElementObjC {
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

  fileprivate init(deleteIndexes: [Int], reloadIndexes: [Int]) {
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

  fileprivate init(parts: [String], atFlags: [Bool]) {
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

  fileprivate init(isLeave: Bool, isDismiss: Bool) {
    self.isLeave = isLeave
    self.isDismiss = isDismiss
    super.init()
  }
}

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

public extension ChatViewModel {
  @objc(lastReadPositionState)
  var objcLastReadPositionState: LastReadPositionStateObjC {
    LastReadPositionStateObjC(lastReadPositionState)
  }

  @objc(isLastReadPositionSuppressed)
  var objcIsLastReadPositionSuppressed: Bool {
    isLastReadPositionSuppressed
  }

  @objc(updateLastReadPositionVisibilityWithVisibleMessageIndexes:)
  func objcUpdateLastReadPositionVisibility(_ visibleMessageIndexes: IndexSet) {
    updateLastReadPositionVisibility(visibleMessageIndices: Set(visibleMessageIndexes))
  }

  @objc(locateLastReadPosition:)
  func objcLocateLastReadPosition(_ completion: @escaping (String?, Bool) -> Void) {
    locateLastReadPosition(completion)
  }

  @objc(completeLastReadPositionLocationWithSuccess:)
  func objcCompleteLastReadPositionLocation(success: Bool) {
    completeLastReadPositionLocation(success: success)
  }

  @objc(indexOfMessageWithStableId:)
  func objcIndexOfMessage(withStableId stableId: String) -> NSNumber? {
    indexOfMessage(withStableId: stableId).map(NSNumber.init(value:))
  }

  @objc(deleteMessageModel:)
  func objcDeleteMessageModel(_ message: V2NIMMessage) -> NEChatMessageDeletionResult {
    let result = deleteMessageModel(message)
    return NEChatMessageDeletionResult(deleteIndexes: result.deleteIndexs,
                                       reloadIndexes: result.reloadIndexs)
  }

  @objc(insertTipMessage:createTime:conversationId:senderId:)
  func objcInsertTipMessage(_ text: String,
                            createTime: NSNumber?,
                            conversationId: String?,
                            senderId: String?) {
    insertTipMessage(text,
                     createTime?.doubleValue,
                     conversationId,
                     senderId)
  }
}

public extension ChatViewController {
  @objc(operationCellFilter)
  var objcOperationCellFilter: [NSNumber]? {
    get { operationCellFilter?.map { NSNumber(value: $0.rawValue) } }
    set {
      operationCellFilter = newValue?.compactMap { OperationType(rawValue: $0.intValue) }
    }
  }

  @objc(setOperationItems:model:)
  func objcSetOperationItems(_ items: [OperationItem], model: MessageContentModel?) -> [OperationItem] {
    var result = items
    setOperationItems(items: &result, model: model)
    return result
  }

  @objc(didTapMessage:model:replyIndex:)
  func objcDidTapMessage(_ cell: UITableViewCell?,
                         model: MessageContentModel?,
                         replyIndex: NSNumber?) {
    didTapMessage(cell, model, replyIndex?.intValue)
  }

  @objc(didTapImageMessage:replyIndex:)
  func objcDidTapImageMessage(_ model: MessageContentModel?, replyIndex: NSNumber?) {
    didTapImageMessage(model, replyIndex?.intValue)
  }

  @objc(didTapVideoMessage:model:replyIndex:)
  func objcDidTapVideoMessage(_ cell: UITableViewCell?,
                              model: MessageContentModel?,
                              replyIndex: NSNumber?) {
    didTapVideoMessage(cell, model, replyIndex?.intValue)
  }

  @objc(didTapFileMessage:model:replyIndex:)
  func objcDidTapFileMessage(_ cell: UITableViewCell?,
                             model: MessageContentModel?,
                             replyIndex: NSNumber?) {
    didTapFileMessage(cell, model, replyIndex?.intValue)
  }

  @objc(didTapCustomMessage:replyIndex:)
  func objcDidTapCustomMessage(_ model: MessageContentModel?, replyIndex: NSNumber?) {
    didTapCustomMessage(model, replyIndex?.intValue)
  }
}

public extension MultiForwardViewController {
  @objc(didTapMessage:model:replyIndex:)
  func objcDidTapMessage(_ cell: UITableViewCell?,
                         model: MessageContentModel?,
                         replyIndex: NSNumber?) {
    didTapMessage(cell, model, replyIndex?.intValue)
  }
}

public extension ChatActivityIndicatorView {
  @objc(messageStatus)
  var objcMessageStatus: NSNumber? {
    get { messageStatus.map { NSNumber(value: $0.rawValue) } }
    set { messageStatus = newValue.flatMap { ChatSendMessageStatus(rawValue: $0.intValue) } }
  }
}

private final class NEChatUIKitReactionProviderAdapter: MessageReactionEmojiProvider {
  private let source: NEMessageReactionEmojiProvider

  init(_ source: NEMessageReactionEmojiProvider) {
    self.source = source
  }

  func emoji(for index: Int) -> MessageReactionEmoji? {
    source.emoji(forIndex: index).map(Self.swiftEmoji)
  }

  func allEmojis() -> [MessageReactionEmoji] {
    source.allEmojis().map(Self.swiftEmoji)
  }

  private static func swiftEmoji(_ value: NEMessageReactionEmoji) -> MessageReactionEmoji {
    MessageReactionEmoji(id: value.index,
                         index: value.index,
                         resourceName: value.resourceName,
                         accessibilityDescription: value.accessibilityDescription)
  }
}

public extension MessageOperationView {
  @objc(visibleFrame)
  var objcVisibleFrame: NSValue? {
    get { visibleFrame.map(NSValue.init(cgRect:)) }
    set { visibleFrame = newValue?.cgRectValue }
  }

  @objc(onSelectReaction)
  var objcOnSelectReaction: ((Int) -> Void)? {
    get { onSelectReaction }
    set { onSelectReaction = newValue }
  }

  @objc(configureReactionsWithProvider:quickIndexes:showEmoji:showMoreButton:)
  func objcConfigureReactions(provider: NEMessageReactionEmojiProvider?,
                              quickIndexes: [NSNumber],
                              showEmoji: Bool,
                              showMoreButton: Bool) {
    configureReactions(provider: provider.map(NEChatUIKitReactionProviderAdapter.init),
                       quickIndexes: quickIndexes.map(\.intValue),
                       showEmoji: showEmoji,
                       showMoreButton: showMoreButton)
  }
}

public extension NotificationMessageUtils {
  @objc(teamLeaveOrDismissResult:)
  static func objcTeamLeaveOrDismissResult(_ message: V2NIMMessage) -> NENotificationTeamStateResult {
    let result = isTeamLeaveOrDismiss(message: message)
    return NENotificationTeamStateResult(isLeave: result.isLeave,
                                         isDismiss: result.isDismiss)
  }
}

public extension NETeamUserManager {
  @objc(getAllTeamMemberWithMaxLimit:nextToken:memberList:queryType:completion:)
  func objcGetAllTeamMemberWithMaxLimit(
    _ teamId: String,
    nextToken: String?,
    memberList: [V2NIMTeamMember],
    queryType: V2NIMTeamMemberRoleQueryType,
    completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void
  ) {
    var accumulatedMembers = memberList
    getAllTeamMemberWithMaxLimit(teamId,
                                 nextToken,
                                 &accumulatedMembers,
                                 queryType,
                                 completion)
  }
}

public extension NEMarkdownParser {
  @objc(customElements)
  var objcCustomElements: [NEMarkdownElementObjC] {
    get {
      customElements.map { element in
        if let adapter = element as? NEMarkdownObjCElementAdapter {
          return adapter.source
        }
        if let objcElement = element as? NEMarkdownElementObjC {
          return objcElement
        }
        return NEMarkdownSwiftElementAdapter(element)
      }
    }
    set {
      customElements = newValue.map { element in
        (element as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter(element)
      }
    }
  }

  @objc(enabledElements)
  var objcEnabledElements: NEMarkdownEnabledElementsObjC {
    get { NEMarkdownEnabledElementsObjC(enabledElements) }
    set { enabledElements = newValue.swiftValue }
  }

  @objc(initWithFont:color:enabledElements:customElements:)
  convenience init(objcFont font: UIFont,
                   color: UIColor,
                   enabledElements: NEMarkdownEnabledElementsObjC,
                   customElements: [NEMarkdownElementObjC]) {
    self.init(font: font,
              color: color,
              enabledElements: enabledElements.swiftValue,
              customElements: customElements.map {
                ($0 as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter($0)
              })
  }

  @objc(initWithAutomaticLinkDetectionEnabled:font:customElements:)
  convenience init(objcAutomaticLinkDetectionEnabled enabled: Bool,
                   font: UIFont,
                   customElements: [NEMarkdownElementObjC]) {
    self.init(automaticLinkDetectionEnabled: enabled,
              font: font,
              customElements: customElements.map {
                ($0 as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter($0)
              })
  }

  @objc(addCustomElement:)
  func objcAddCustomElement(_ element: NEMarkdownElementObjC) {
    addCustomElement((element as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter(element))
  }

  @objc(removeCustomElement:)
  func objcRemoveCustomElement(_ element: NEMarkdownElementObjC) {
    if let swiftElement = element as? NEMarkdownElement {
      removeCustomElement(swiftElement)
      return
    }
    guard let adapter = customElements.first(where: {
      ($0 as? NEMarkdownObjCElementAdapter)?.source === element
    }) else {
      return
    }
    removeCustomElement(adapter)
  }
}

public extension NEMarkdownTableView {
  @objc(initWithData:maxWidth:)
  convenience init(objcData data: NEMarkdownTableDataObjC, maxWidth: CGFloat) {
    self.init(data: data.swiftValue, maxWidth: maxWidth)
  }

  @objc(calculateHeightWithData:maxWidth:headerFont:cellFont:cellPadding:borderWidth:)
  static func objcCalculateHeight(data: NEMarkdownTableDataObjC,
                                  maxWidth: CGFloat,
                                  headerFont: UIFont,
                                  cellFont: UIFont,
                                  cellPadding: CGFloat,
                                  borderWidth: CGFloat) -> CGFloat {
    calculateHeight(data: data.swiftValue,
                    maxWidth: maxWidth,
                    headerFont: headerFont,
                    cellFont: cellFont,
                    cellPadding: cellPadding,
                    borderWidth: borderWidth)
  }
}

public extension NEBaseChatInputView {
  @objc(checkRemoveAtMessageWithRange:attribute:)
  func objcCheckRemoveAtMessage(range: NSRange,
                                attribute: NSAttributedString) -> NSValue? {
    checkRemoveAtMessage(range: range, attribute: attribute).map(NSValue.init(range:))
  }

  @objc(findShowPositionWithRange:attribute:)
  func objcFindShowPosition(range: NSRange,
                            attribute: NSAttributedString) -> NSValue? {
    findShowPosition(range: range, attribute: attribute).map(NSValue.init(range:))
  }

  @objc(convertRangeToNSRangeWithRange:)
  func objcConvertRangeToNSRange(range: UITextRange?) -> NSValue? {
    convertRangeToNSRange(range: range).map(NSValue.init(range:))
  }
}

public extension ChatMessageHelper {
  @objc(isAIStreamLoading:)
  static func objcIsAIStreamLoading(_ message: V2NIMMessage?) -> Bool {
    isAIStreamLoading(message)
  }

  @objc(splitTextByAtMentions:message:)
  static func objcSplitTextByAtMentions(_ text: String,
                                        message: V2NIMMessage) -> NEChatTextMentionSplitResult {
    let result = splitTextByAtMentions(text: text, message: message)
    return NEChatTextMentionSplitResult(parts: result.parts, atFlags: result.isAtFlags)
  }
}
