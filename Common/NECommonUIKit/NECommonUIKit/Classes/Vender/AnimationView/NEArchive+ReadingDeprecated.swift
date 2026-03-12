
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension NEArchive {
  @available(
    *,
    deprecated,
    message: "Please use `Int` for `bufferSize`."
  )
  func extract(_ entry: NEEntry,
               to url: URL,
               bufferSize: UInt32,
               skipCRC32: Bool = false,
               progress: Progress? = nil)
    throws -> NECRC32 {
    try extract(entry, to: url, bufferSize: Int(bufferSize), skipCRC32: skipCRC32, progress: progress)
  }

  @available(
    *,
    deprecated,
    message: "Please use `Int` for `bufferSize`."
  )
  func extract(_ entry: NEEntry,
               bufferSize: UInt32,
               skipCRC32: Bool = false,
               progress: Progress? = nil,
               consumer: NEConsumer)
    throws -> NECRC32 {
    try extract(
      entry,
      bufferSize: Int(bufferSize),
      skipCRC32: skipCRC32,
      progress: progress,
      consumer: consumer
    )
  }
}
