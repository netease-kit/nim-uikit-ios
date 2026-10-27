// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

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
    objcDeleteMessageResultForMessage(message)
  }

  @objc(deleteMessageIndexesForMessage:)
  func objcDeleteMessageIndexesForMessage(_ message: V2NIMMessage) -> [String: [NSNumber]] {
    let result = objcDeleteMessageResultForMessage(message)
    return ["deleteIndexs": result.deletedIndexes, "reloadIndexs": result.reloadedIndexes]
  }

  @objc(deleteMessageResultForMessage:)
  func objcDeleteMessageResultForMessage(_ message: V2NIMMessage) -> NEChatMessageDeletionResult {
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
