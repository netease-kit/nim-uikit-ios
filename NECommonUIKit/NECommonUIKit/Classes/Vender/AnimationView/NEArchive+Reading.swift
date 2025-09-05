
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension NEArchive {
  /// Read a ZIP `NEEntry` from the receiver and write it to `url`.
  ///
  /// - Parameters:
  ///   - entry: The ZIP `NEEntry` to read.
  ///   - url: The destination file URL.
  ///   - bufferSize: The maximum size of the read buffer and the decompression buffer (if needed).
  ///   - skipCRC32: Optional flag to skip calculation of the NECRC32 checksum to improve performance.
  ///   - progress: A progress object that can be used to track or cancel the extract operation.
  /// - Returns: The checksum of the processed content or 0 if the `skipCRC32` flag was set to `true`.
  /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
  func extract(_ entry: NEEntry,
               to url: URL,
               bufferSize: Int = defaultReadChunkSize,
               skipCRC32: Bool = false,
               progress: Progress? = nil)
    throws -> NECRC32 {
    guard bufferSize > 0 else {
      throw NEArchiveError.invalidBufferSize
    }
    let fileManager = FileManager()
    var checksum = NECRC32(0)
    switch entry.type {
    case .file:
      guard !fileManager.itemExists(at: url) else {
        throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
      }
      try fileManager.createParentDirectoryStructure(for: url)
      let destinationRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
      guard let destinationFile: NEFILEPointer = fopen(destinationRepresentation, "wb+") else {
        throw CocoaError(.fileNoSuchFile)
      }
      defer { fclose(destinationFile) }
      let consumer = { _ = try Data.neWrite(chunk: $0, to: destinationFile) }
      checksum = try extract(
        entry,
        bufferSize: bufferSize,
        skipCRC32: skipCRC32,
        progress: progress,
        consumer: consumer
      )
    case .directory:
      let consumer = { (_: Data) in
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      }
      checksum = try extract(
        entry,
        bufferSize: bufferSize,
        skipCRC32: skipCRC32,
        progress: progress,
        consumer: consumer
      )
    case .symlink:
      guard !fileManager.itemExists(at: url) else {
        throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
      }
      let consumer = { (data: Data) in
        guard let linkPath = String(data: data, encoding: .utf8) else { throw NEArchiveError.invalidEntryPath }
        try fileManager.createParentDirectoryStructure(for: url)
        try fileManager.createSymbolicLink(atPath: url.path, withDestinationPath: linkPath)
      }
      checksum = try extract(
        entry,
        bufferSize: bufferSize,
        skipCRC32: skipCRC32,
        progress: progress,
        consumer: consumer
      )
    }
    let attributes = FileManager.attributes(from: entry)
    try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
    return checksum
  }

  /// Read a ZIP `NEEntry` from the receiver and forward its contents to a `NEConsumer` closure.
  ///
  /// - Parameters:
  ///   - entry: The ZIP `NEEntry` to read.
  ///   - bufferSize: The maximum size of the read buffer and the decompression buffer (if needed).
  ///   - skipCRC32: Optional flag to skip calculation of the NECRC32 checksum to improve performance.
  ///   - progress: A progress object that can be used to track or cancel the extract operation.
  ///   - consumer: A closure that consumes contents of `NEEntry` as `Data` chunks.
  /// - Returns: The checksum of the processed content or 0 if the `skipCRC32` flag was set to `true`..
  /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
  func extract(_ entry: NEEntry,
               bufferSize: Int = defaultReadChunkSize,
               skipCRC32: Bool = false,
               progress: Progress? = nil,
               consumer: NEConsumer)
    throws -> NECRC32 {
    guard bufferSize > 0 else {
      throw NEArchiveError.invalidBufferSize
    }
    var checksum = NECRC32(0)
    let localFileHeader = entry.localFileHeader
    guard entry.dataOffset <= .max else { throw NEArchiveError.invalidLocalHeaderDataOffset }
    fseeko(archiveFile, off_t(entry.dataOffset), SEEK_SET)
    progress?.totalUnitCount = totalUnitCountForReading(entry)
    switch entry.type {
    case .file:
      guard let compressionMethod = NECompressionMethod(rawValue: localFileHeader.compressionMethod) else {
        throw NEArchiveError.invalidCompressionMethod
      }
      switch compressionMethod {
      case .none: checksum = try readUncompressed(
          entry: entry,
          bufferSize: bufferSize,
          skipCRC32: skipCRC32,
          progress: progress,
          with: consumer
        )
      case .deflate: checksum = try readCompressed(
          entry: entry,
          bufferSize: bufferSize,
          skipCRC32: skipCRC32,
          progress: progress,
          with: consumer
        )
      }
    case .directory:
      try consumer(Data())
      progress?.completedUnitCount = totalUnitCountForReading(entry)
    case .symlink:
      let localFileHeader = entry.localFileHeader
      let size = Int(localFileHeader.compressedSize)
      let data = try Data.neReadChunk(of: size, from: archiveFile)
      checksum = data.neCrc32(checksum: 0)
      try consumer(data)
      progress?.completedUnitCount = totalUnitCountForReading(entry)
    }
    return checksum
  }
}
