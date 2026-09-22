// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import UIKit

enum DemoStickerConfig {
  private struct PackageDefinition {
    let id: String
    let title: String
  }

  private static let classTag = "DemoStickerConfig"
  private static let packages = [
    PackageDefinition(id: "ajmd", title: "鸡"),
    PackageDefinition(id: "xxy", title: "熊"),
    PackageDefinition(id: "lt", title: "兔"),
  ]

  static func registerPackages() {
    guard let bundleURL = Bundle.main.url(forResource: "NIMDemoChartlet", withExtension: "bundle") else {
      NEALog.errorLog(classTag, desc: "NIMDemoChartlet.bundle is missing")
      return
    }

    for definition in packages {
      guard let package = makePackage(definition, bundleURL: bundleURL) else {
        NEALog.errorLog(classTag, desc: "skip invalid sticker package: \(definition.id)")
        continue
      }
      if !NIMInputEmoticonManager.shared.registerStickerPackage(package) {
        NEALog.errorLog(classTag, desc: "failed to register sticker package: \(definition.id)")
      }
    }
  }

  private static func makePackage(_ definition: PackageDefinition,
                                  bundleURL: URL) -> NIMInputStickerPackage? {
    let packageURL = bundleURL.appendingPathComponent(definition.id, isDirectory: true)
    let contentURL = packageURL.appendingPathComponent("content", isDirectory: true)
    let iconURL = packageURL.appendingPathComponent("icon", isDirectory: true)

    guard let normalIcon = loadIcon(
      named: "\(definition.id)_s_normal",
      from: iconURL
    ), let selectedIcon = loadIcon(
      named: "\(definition.id)_s_highlighted",
      from: iconURL
    ) else {
      return nil
    }

    let stickers = imageURLs(in: contentURL).compactMap { fileURL -> NIMInputSticker? in
      guard UIImage(contentsOfFile: fileURL.path) != nil else {
        return nil
      }
      return NIMInputSticker(stickerID: normalizedStem(for: fileURL), fileURL: fileURL)
    }
    guard !stickers.isEmpty else {
      return nil
    }

    return NIMInputStickerPackage(
      packageID: definition.id,
      title: definition.title,
      normalIcon: normalIcon,
      selectedIcon: selectedIcon,
      stickers: stickers
    )
  }

  private static func loadIcon(named name: String, from directoryURL: URL) -> UIImage? {
    guard let fileURL = imageURLs(in: directoryURL).first(where: {
      normalizedStem(for: $0) == name
    }) else {
      return nil
    }
    return UIImage(contentsOfFile: fileURL.path)
  }

  private static func imageURLs(in directoryURL: URL) -> [URL] {
    guard let urls = try? FileManager.default.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }
    return urls.filter { url in
      (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }.sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  private static func normalizedStem(for fileURL: URL) -> String {
    fileURL.deletingPathExtension().lastPathComponent.replacingOccurrences(
      of: "@[23]x$",
      with: "",
      options: .regularExpression
    )
  }
}
