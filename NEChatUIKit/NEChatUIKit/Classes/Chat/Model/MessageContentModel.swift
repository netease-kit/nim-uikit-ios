
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreAudio
import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class MessageContentModel: NSObject, MessageModel {
  public var type: MessageType = .custom // 消息类型（文本、图片、自定义消息...）
  public var customType: Int = 0 // 自定义消息的子类型（合并转发、换行消息...）
  public var message: V2NIMMessage?
  public weak var cell: NEChatBaseCell? // 消息对应的cell

  public var offset: CGFloat = 0
  public var textWidth: CGFloat = 0
  public var contentSize = CGSize(width: 32.0, height: chat_min_h)
  public var height: CGFloat = 48
  open func cellHeight() -> CGFloat {
    CGFloat(height) + offset
  }

  public var selectRange: NSRange? // 划词选择的范围
  open func selectText() -> String? {
    nil
  }

  public var showSelect: Bool = false // 多选按钮是否展示
  public var isSelected: Bool = false // 多选是否选中
  public var isSelectAll: Bool = false // 是否全选
  public var unkonwMessage: Bool = false
  public var inMultiForward: Bool = false { // 是否是合并消息中的子消息
    didSet {
//      fullNameHeight = 0 // 合并消息中的子消息不显示昵称
      fullNameHeight = 20 // 合并消息中的子消息显示昵称
      if inMultiForward {
        height += fullNameHeight
      } else if oldValue {
        height -= fullNameHeight
      }
    }
  }

  public var avatar: String?
  public var shortName: String? // 昵称 > uid
  public var fullName: String? // 备注 >（群昵称）> 昵称 > uid
  public var fullNameHeight: CGFloat = 0

  public var readCount: Int = 0
  public var unreadCount: Int = 0

  public var isReply: Bool = false
  public var replyText: String?
  public var replyedModel: MessageModel? {
    didSet {
      if let reply = replyedModel as? MessageContentModel {
        if type == .tip {
          return
        }

        isReply = true
        replyText = ReplyMessageUtil.textForReplyModel(model: reply)
        // height 计算移至 getMessageModel(model:)
      }
    }
  }

  public var isReedit: Bool = false
  public var timeOut = false
  public var revokeTime: TimeInterval = 0
  public var isRevoked: Bool = false {
    didSet {
      if isRevoked {
        // A revoked message must not retain a visible Reaction area or its
        // row-height contribution after late SDK updates.
        reactionGroups.removeAll()
        reactionHeight = 0
        type = .revoke

        // 只有文本消息，才计算可编辑按钮的宽度
        if ChatMessageHelper.isSelf(message: message),
           message?.messageType == .MESSAGE_TYPE_TEXT, timeOut == false {
          contentSize = CGSize(width: 218, height: chat_min_h)
        } else {
          contentSize = CGSize(width: 130, height: chat_min_h)
        }
        // Normal/Feishu revoke rows use ordinary directional message geometry.
        // Fun/WeChat controllers override revoke rows with TIP height.
        height = contentSize.height + chat_content_margin + fullNameHeight

        // time
        if let time = timeContent, !time.isEmpty {
          height += chat_timeCellH
        }
      } else {
        type = .custom
        contentSize = CGSize(width: 32.0, height: chat_min_h)
        height = chat_min_h + chat_content_margin + fullNameHeight

        // time
        if let time = timeContent, !time.isEmpty {
          height += chat_timeCellH
        }
      }
    }
  }

  public var pinAccount: String?
  public var pinShowName: String?
  public var isPined: Bool = false

  /// Message reactions are owned by MessageReactionManager and exposed here
  /// only as presentation data for cells.
  public var reactionGroups: [NEMessageReactionGroup] = []
  public var reactionHeight: CGFloat = 0 {
    didSet {
      height += reactionHeight - oldValue
    }
  }

  public var hasReaction: Bool {
    !reactionGroups.isEmpty
  }

  // 是否显示时间
  public var timeContent: String? {
    didSet {
      if let time = timeContent, !time.isEmpty, time != oldValue {
        height += chat_timeCellH
      }
    }
  }

  public var messageTextFont: UIFont = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.selfMessageTextSize)
  public var messageTextColor = ChatUIConfig.shared.messageProperties.selfMessageTextColor
  public private(set) var viewport: NEChatViewport?
  private var intrinsicViewportWidth: CGFloat?
  private var intrinsicViewportSize: CGSize?
  private var viewportFontSize: CGFloat?
  private var viewportAudioText: String?
  public var messageMaxSize: CGSize {
    CGSize(width: viewport?.maximumTextWidth ?? chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
  }

  /// Recalculate presentation geometry only. Keeps SDK messages, selections,
  /// reply metadata, playback state and the existing row decorations intact.
  open func applyViewport(_ viewport: NEChatViewport) {
    let audioText = (self as? MessageAudioModel)?.text
    guard self.viewport?.contentWidth != viewport.contentWidth || viewportFontSize != messageTextFont.pointSize || viewportAudioText != audioText else { return }
    viewportFontSize = messageTextFont.pointSize
    viewportAudioText = audioText
    self.viewport = viewport
    // Revoke cells own their presentation geometry; resizing must not restore
    // the original media size or transcript height after a message is revoked.
    if isRevoked { return }
    let previousSize = contentSize
    (self as? MessageAIStreamModel)?.measureMarkdownForViewport()
    if let stream = self as? MessageAIStreamModel, ChatMessageHelper.isAIStreamLoading(stream.message) {
      contentSize.width = min(contentSize.width, viewport.maximumBubbleWidth)
    } else if let text = self as? MessageTextModel, !isRevoked {
      let size = text.getTextSize(text.attributeStr)
      text.textHeight = ceil(size.height)
      text.textWidth = ceil(size.width)
      var bodyWidth = ceil(size.width) + 2 * chat_content_margin
      var bodyHeight = ceil(size.height) + 2 * chat_content_margin
      if let rich = text as? MessageRichTextModel {
        let title = NSAttributedString.getRealTextViewSize(rich.titleAttributeStr, messageTextFont, messageMaxSize)
        rich.titleTextHeight = ceil(title.height)
        bodyWidth = max(bodyWidth, ceil(title.width) + 2 * chat_content_margin)
        bodyHeight += ceil(title.height) + ((rich.messageText?.isEmpty ?? true) ? 0 : chat_content_margin)
      }
      // Keep the skin's reply/minimum-height contribution rather than invoking
      // its model callback again (which would append the decoration twice).
      let oldBodyHeight = text.textHeightForViewport ?? previousSize.height - text.addedTranslationHeight
      let oldInsideTranslation = text.translationInsideBubble ? text.addedTranslationHeight : 0
      let replyDecoration = max(0, previousSize.height - oldBodyHeight - oldInsideTranslation)
      text.textHeightForViewport = bodyHeight
      text.translationBaseContentWidth = bodyWidth
      let translationHeight = text.addedTranslationHeight > 0 ? text.estimateTranslationBubbleHeight() : 0
      let translationInside = text.translationInsideBubble
      let translationDelta = translationHeight - text.addedTranslationHeight
      text.addedTranslationHeight = translationHeight
      if translationInside {
        bodyHeight += translationHeight
        bodyWidth = max(bodyWidth, text.estimateTranslationTextWidth() + 2 * chat_content_margin)
      } else {
        height += translationDelta
      }
      contentSize = CGSize(width: min(bodyWidth, viewport.maximumBubbleWidth), height: bodyHeight + replyDecoration)
    } else if let tip = self as? MessageTipsModel {
      let font = ChatMessageHelper.isAISender(message) ? messageTextFont : UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.timeTextSize)
      contentSize = String.getRealSize(tip.text, font, messageMaxSize)
      textWidth = contentSize.width
    } else if let call = self as? MessageCallRecordModel {
      let size = NSAttributedString.getRealTextViewSize(call.attributeStr, messageTextFont, messageMaxSize)
      let decoration = previousSize.height - (call.viewportTextHeight ?? size.height)
      call.viewportTextHeight = size.height
      contentSize = CGSize(width: min(viewport.maximumBubbleWidth, size.width + chat_cell_margin * 2), height: size.height + decoration)
    } else if let audio = self as? MessageAudioModel {
      audio.audioWidth = min(audio.duration > 2 ? Double(audio.duration) * 8 + 96 : 96, Double(viewport.maximumAudioWidth))
      contentSize.width = CGFloat(audio.audioWidth)
      if let text = audio.text {
        let maxWidth = audio.transcriptOutsideBubble
          ? viewport.maximumAudioWidth - audio.transcriptHorizontalInset
          : max(viewport.maximumTextWidth, CGFloat(audio.audioWidth)) - chat_cell_margin * 2
        let size = String.getRealSize(text, messageTextFont, CGSize(width: max(1, maxWidth), height: CGFloat.greatestFiniteMagnitude))
        if audio.transcriptOutsideBubble {
          height = chat_min_h + ceil(size.height) + chat_content_margin * 4 + fullNameHeight + chat_pin_height + reactionHeight
          if let timeContent, !timeContent.isEmpty { height += chat_timeCellH }
        } else {
          contentSize = CGSize(width: max(CGFloat(audio.audioWidth), ceil(size.width) + chat_cell_margin * 2), height: chat_min_h + ceil(size.height) + chat_content_margin)
          height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height + reactionHeight
          if let timeContent, !timeContent.isEmpty { height += chat_timeCellH }
        }
        // These are the same absolute row formulas used by the audio cells.
        // Do not add the generic content-size delta a second time.
        return
      }
    } else {
      if intrinsicViewportWidth == nil { intrinsicViewportWidth = contentSize.width }
      if self is MessageImageModel, !(self is MessageFileModel) {
        if intrinsicViewportSize == nil { intrinsicViewportSize = contentSize }
        let intrinsicSize = intrinsicViewportSize ?? contentSize
        if intrinsicSize.width > 0, intrinsicSize.height > 0 {
          let width = min(intrinsicSize.width, viewport.maximumBubbleWidth)
          let scale = width / intrinsicSize.width
          contentSize = CGSize(width: width, height: max(chat_min_h, intrinsicSize.height * scale))
        } else {
          contentSize = CGSize(width: viewport.maximumBubbleWidth, height: chat_min_h)
        }
      } else {
        contentSize.width = min(intrinsicViewportWidth ?? contentSize.width, viewport.maximumBubbleWidth)
      }
    }
    height += contentSize.height - previousSize.height
  }

  public required init(message: V2NIMMessage?) {
    self.message = message
    messageTextFont = UIFont.systemFont(ofSize: ChatMessageHelper.isSelf(message: message) ? ChatUIConfig.shared.messageProperties.selfMessageTextSize : ChatUIConfig.shared.messageProperties.receiveMessageTextSize)
    messageTextColor = ChatMessageHelper.isSelf(message: message) ? ChatUIConfig.shared.messageProperties.selfMessageTextColor : ChatUIConfig.shared.messageProperties.receiveMessageTextColor

    if message?.conversationType == .CONVERSATION_TYPE_TEAM,
       let senderId = ChatMessageHelper.getSenderId(message),
       !IMKitClient.instance.isMe(senderId) {
      fullNameHeight = ChatUIConfig.shared.messageProperties.showTeamMessageNick ? 20 : 0
    }

    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  open func resetMessage(_ message: V2NIMMessage?) {
    self.message = message
  }
}
