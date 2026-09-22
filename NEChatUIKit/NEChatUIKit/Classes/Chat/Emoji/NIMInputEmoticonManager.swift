
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objc
public enum NIMEmoticonType: Int {
  case file = 0
  case unicode
}

@objcMembers
open class NIMInputEmoticon: NSObject {
  public var type: NIMEmoticonType {
    if unicode?.isEmpty == false {
      return .unicode
    } else {
      return .file
    }
  }

  public var emoticonID: String?
  public var tag: String?
  public var fileName: String?
  public var unicode: String?
}

@objcMembers
open class NIMInputEmoticonLayout: NSObject {
  public var rows: NSInteger = 0 // 行数
  public var columes: NSInteger = 0 // 列数
  public var itemCountInPage: NSInteger = 0 // 每页显示几项
  public var cellWidth: CGFloat = 0 // 单个单元格宽
  public var cellHeight: CGFloat = 0 // 单个单元格高
  public var imageWidth: CGFloat = 0 // 显示图片的宽
  public var imageHeight: CGFloat = 0 // 显示图片的高
  public var emoji: Bool?

  public init(width: CGFloat) {
    rows = NIMKit_EmojRows
    columes =
      ((Int(width) - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) /
        Int(NIMKit_EmojImageWidth))
    itemCountInPage = rows * columes - 1
    cellWidth =
      CGFloat((Int(width) - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) / columes)
    cellHeight = NIMKit_EmojCellHeight
    imageWidth = NIMKit_EmojImageWidth
    imageHeight = NIMKit_EmojImageHeight
    emoji = true
  }
}

@objcMembers
open class NIMInputEmoticonCatalog: NSObject {
  public var layout: NIMInputEmoticonLayout?
  public var catalogID: String?
  public var title: String?
  public var id2Emoticons: [String: NIMInputEmoticon]?
  public var tag2Emoticons: [String: NIMInputEmoticon]?
  public var emoticons: [NIMInputEmoticon]?
  /// 图标
  public var icon: String?
  /// 小图标按下效果
  public var iconPressed: String?
  /// 分页数
  public var pagesCount: NSInteger = 0
}

@objcMembers
public final class NIMInputSticker: NSObject {
  public let stickerID: String
  public let fileURL: URL

  @objc(initWithStickerID:fileURL:)
  public init(stickerID: String, fileURL: URL) {
    self.stickerID = stickerID
    self.fileURL = fileURL
    super.init()
  }
}

@objcMembers
public final class NIMInputStickerPackage: NSObject {
  public let packageID: String
  public let title: String?
  public let normalIcon: UIImage
  public let selectedIcon: UIImage
  public let stickers: [NIMInputSticker]

  @objc(initWithPackageID:title:normalIcon:selectedIcon:stickers:)
  public init(packageID: String, title: String? = nil, normalIcon: UIImage,
              selectedIcon: UIImage, stickers: [NIMInputSticker]) {
    self.packageID = packageID
    self.title = title
    self.normalIcon = normalIcon
    self.selectedIcon = selectedIcon
    self.stickers = stickers
    super.init()
  }
}

@objcMembers
public final class NIMInputStickerNotification: NSObject {
  @objc(packagesDidChange)
  public static var packagesDidChange: NSNotification.Name {
    NSNotification.Name("NIMInputStickerPackagesDidChangeNotification")
  }
}

@objcMembers
open class NIMInputEmoticonManager: NSObject {
  public static let shared = NIMInputEmoticonManager()
  private var catalogs: [NIMInputEmoticonCatalog]?
  private var classTag = "NIMInputEmoticonManager"
  private let stickerLock = NSLock()
  private var registeredStickerPackages = [NIMInputStickerPackage]()

  /// 是否是外部资源
  private(set) var isCustomEmojResource = false

  override public init() {
    super.init()
    parsePlist()
    preloadEmoticonResource()
  }

  open func setCustomEmojConfig(_ array: NSArray) {
    var catalogs = [NIMInputEmoticonCatalog]()
    for dict in array {
      if let convertDict = dict as? NSDictionary {
        let info = convertDict["info"] as? [String: Any]
        let emotions = convertDict["data"] as? NSArray
        let cataLog = catalogByInfo(
          info: info as NSDictionary?,
          emoticonsArray: emotions
        )
        catalogs.append(cataLog)
      }
    }
    self.catalogs = catalogs
    isCustomEmojResource = true
  }

  func parsePlist() {
    var catalogs = [NIMInputEmoticonCatalog]()
    let filePath = Bundle.nim_EmojiPlistFile()
    if let path = filePath {
      let array = NSArray(contentsOfFile: path)
      array?.forEach { dict in
        if let convertDict = (dict as? NSDictionary) {
          let info = convertDict["info"] as? [String: Any]
          let emotions = convertDict["data"] as? NSArray
          let cataLog = catalogByInfo(
            info: info as NSDictionary?,
            emoticonsArray: emotions
          )
          catalogs.append(cataLog)
        }
      }
    }
    self.catalogs = catalogs
  }

  func catalogByInfo(info: NSDictionary?, emoticonsArray: NSArray?) -> NIMInputEmoticonCatalog {
    let cataLog = NIMInputEmoticonCatalog()

    guard let infoDict = info, let emotions = emoticonsArray else {
      NEALog.errorLog(classTag, desc: "info or emoticonsArray is nil")
      return cataLog
    }
    cataLog.catalogID = infoDict["id"] as? String
    cataLog.title = infoDict["title"] as? String
    cataLog.icon = infoDict["normal"] as? String
    cataLog.iconPressed = infoDict["pressed"] as? String
    var tag2Emoticons = [String: NIMInputEmoticon]()
    var id2Emoticons = [String: NIMInputEmoticon]()
    var resultEmotions = [NIMInputEmoticon]()

    for emoticonDict in emotions {
      if let dict = (emoticonDict as? NSDictionary) {
        let emotion = NIMInputEmoticon()
        emotion.emoticonID = dict["id"] as? String
        emotion.tag = dict["tag"] as? String
        emotion.unicode = dict["unicode"] as? String
        emotion.fileName = dict["file"] as? String

        if let id = emotion.emoticonID, !id.isEmpty {
          resultEmotions.append(emotion)
          id2Emoticons[id] = emotion
        }
        if let tag = emotion.tag, !tag.isEmpty {
          tag2Emoticons[tag] = emotion
        }
      }
    }
    cataLog.emoticons = resultEmotions
    cataLog.id2Emoticons = id2Emoticons
    cataLog.tag2Emoticons = tag2Emoticons
    return cataLog
  }

  func preloadEmoticonResource() {}

  open func emoticonCatalog(catalogID: String) -> NIMInputEmoticonCatalog? {
    guard let infos = catalogs else { return nil }

    for catalog in infos {
      if catalog.catalogID == catalogID {
        return catalog
      }
    }
    return nil
  }

  open func emoticonByTag(tag: String) -> NIMInputEmoticon? {
    var emotion: NIMInputEmoticon?

    guard let clogs = catalogs else {
      NEALog.errorLog(classTag, desc: "catalogs is nil")
      return emotion
    }

    if !tag.isEmpty {
      for catalog in clogs {
        if let tag2Emotions = catalog.tag2Emoticons {
          emotion = tag2Emotions[tag]
          if let _ = emotion {
            break
          }
        }
      }
    }
    return emotion
  }

  open func emoticonByID(emoticonID: String) -> NIMInputEmoticon? {
    var emotion: NIMInputEmoticon?
    guard let clogs = catalogs else {
      NEALog.errorLog(classTag, desc: "catalogs is nil")
      return emotion
    }

    if !emoticonID.isEmpty {
      for catalog in clogs {
        if let id2Emoticons = catalog.id2Emoticons {
          emotion = id2Emoticons[emoticonID]
          if let _ = emotion {
            break
          }
        }
      }
    }
    return emotion
  }

  open func emoticonByCatalogID(catalogID: String, emoticonID: String) -> NIMInputEmoticon? {
    var emotion: NIMInputEmoticon?
    guard let clogs = catalogs else {
      NEALog.errorLog(classTag, desc: "catalogs is nil")
      return emotion
    }

    if !catalogID.isEmpty, !emoticonID.isEmpty {
      for catalog in clogs {
        if catalog.catalogID == catalogID {
          if let id2Emoticons = catalog.id2Emoticons {
            emotion = id2Emoticons[emoticonID]
            break
          }
        }
      }
    }
    return emotion
  }

  @discardableResult
  @objc(registerStickerPackage:)
  open func registerStickerPackage(_ package: NIMInputStickerPackage) -> Bool {
    guard let snapshot = validatedStickerPackage(package) else {
      return false
    }

    stickerLock.lock()
    if let index = registeredStickerPackages.firstIndex(where: { $0.packageID == snapshot.packageID }) {
      registeredStickerPackages[index] = snapshot
    } else {
      registeredStickerPackages.append(snapshot)
    }
    stickerLock.unlock()

    postStickerPackagesDidChange()
    return true
  }

  @discardableResult
  @objc(unregisterStickerPackageWithID:)
  open func unregisterStickerPackage(withID packageID: String) -> Bool {
    let normalizedID = packageID.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedID.isEmpty, normalizedID != NIMKit_EmojiCatalog else {
      return false
    }

    stickerLock.lock()
    guard let index = registeredStickerPackages.firstIndex(where: { $0.packageID == normalizedID }) else {
      stickerLock.unlock()
      return false
    }
    registeredStickerPackages.remove(at: index)
    stickerLock.unlock()

    postStickerPackagesDidChange()
    return true
  }

  @objc(stickerPackages)
  open func stickerPackages() -> [NIMInputStickerPackage] {
    stickerLock.lock()
    let snapshot = registeredStickerPackages
    stickerLock.unlock()
    return snapshot
  }

  private func validatedStickerPackage(_ package: NIMInputStickerPackage) -> NIMInputStickerPackage? {
    let packageID = package.packageID.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !packageID.isEmpty,
          packageID != NIMKit_EmojiCatalog,
          package.normalIcon.size.width > 0,
          package.normalIcon.size.height > 0,
          package.selectedIcon.size.width > 0,
          package.selectedIcon.size.height > 0 else {
      return nil
    }

    var stickerIDs = Set<String>()
    var validStickers = [NIMInputSticker]()
    for sticker in package.stickers {
      let stickerID = sticker.stickerID.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !stickerID.isEmpty,
            !stickerIDs.contains(stickerID),
            sticker.fileURL.isFileURL,
            FileManager.default.isReadableFile(atPath: sticker.fileURL.path),
            let image = UIImage(contentsOfFile: sticker.fileURL.path),
            image.size.width > 0,
            image.size.height > 0 else {
        continue
      }
      stickerIDs.insert(stickerID)
      validStickers.append(NIMInputSticker(stickerID: stickerID, fileURL: sticker.fileURL))
    }

    guard !validStickers.isEmpty else {
      return nil
    }
    return NIMInputStickerPackage(
      packageID: packageID,
      title: package.title,
      normalIcon: package.normalIcon,
      selectedIcon: package.selectedIcon,
      stickers: validStickers
    )
  }

  private func postStickerPackagesDidChange() {
    let postNotification = { [self] in
      NotificationCenter.default.post(
        name: NIMInputStickerNotification.packagesDidChange,
        object: self
      )
    }
    if Thread.isMainThread {
      postNotification()
    } else {
      DispatchQueue.main.async(execute: postNotification)
    }
  }
}
