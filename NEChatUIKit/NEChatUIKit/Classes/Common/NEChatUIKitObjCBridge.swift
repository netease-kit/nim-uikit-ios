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
