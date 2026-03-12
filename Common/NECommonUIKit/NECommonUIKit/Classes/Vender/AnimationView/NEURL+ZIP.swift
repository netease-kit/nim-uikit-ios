// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension URL {
  static func neTemporaryReplacementDirectoryURL(for archive: NEArchive) -> URL {
    #if swift(>=5.0) || os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      if
        archive.url.isFileURL,
        let tempDir = try? FileManager().url(
          for: .itemReplacementDirectory,
          in: .userDomainMask,
          appropriateFor: archive.url,
          create: true
        ) {
        return tempDir
      }
    #endif

    return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      ProcessInfo.processInfo.globallyUniqueString)
  }
}
