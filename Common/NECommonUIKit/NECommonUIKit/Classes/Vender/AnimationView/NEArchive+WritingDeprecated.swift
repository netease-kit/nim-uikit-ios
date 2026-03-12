
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
  func addEntry(with path: String,
                relativeTo baseURL: URL,
                compressionMethod: NECompressionMethod = .none,
                bufferSize: UInt32,
                progress: Progress? = nil)
    throws {
    try addEntry(
      with: path,
      relativeTo: baseURL,
      compressionMethod: compressionMethod,
      bufferSize: Int(bufferSize),
      progress: progress
    )
  }

  @available(
    *,
    deprecated,
    message: "Please use `Int` for `bufferSize`."
  )
  func addEntry(with path: String,
                fileURL: URL,
                compressionMethod: NECompressionMethod = .none,
                bufferSize: UInt32,
                progress: Progress? = nil)
    throws {
    try addEntry(
      with: path,
      fileURL: fileURL,
      compressionMethod: compressionMethod,
      bufferSize: Int(bufferSize),
      progress: progress
    )
  }

  @available(
    *,
    deprecated,
    message: "Please use `Int64` for `uncompressedSize` and provider `position`. `Int` for `bufferSize`."
  )
  func addEntry(with path: String,
                type: NEEntry.NEEntryType,
                uncompressedSize: UInt32,
                modificationDate: Date = Date(),
                permissions: UInt16? = nil,
                compressionMethod: NECompressionMethod = .none,
                bufferSize: Int = defaultWriteChunkSize,
                progress: Progress? = nil,
                provider: (_ position: Int, _ size: Int) throws -> Data)
    throws {
    let newProvider: NEProvider = { try provider(Int($0), $1) }
    try addEntry(
      with: path,
      type: type,
      uncompressedSize: Int64(uncompressedSize),
      modificationDate: modificationDate,
      permissions: permissions,
      compressionMethod: compressionMethod,
      bufferSize: bufferSize,
      progress: progress,
      provider: newProvider
    )
  }

  @available(
    *,
    deprecated,
    message: "Please use `Int` for `bufferSize`."
  )
  func remove(_ entry: NEEntry, bufferSize: UInt32, progress: Progress? = nil) throws {
    try remove(entry, bufferSize: Int(bufferSize), progress: progress)
  }
}
