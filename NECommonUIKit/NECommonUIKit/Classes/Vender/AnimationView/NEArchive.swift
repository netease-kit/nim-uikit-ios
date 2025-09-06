
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// The default chunk size when reading entry data from an archive.
let defaultReadChunkSize = Int(16 * 1024)
/// The default chunk size when writing entry data to an archive.
let defaultWriteChunkSize = defaultReadChunkSize
/// The default permissions for newly added entries.
let defaultFilePermissions = UInt16(0o644)
/// The default permissions for newly added directories.
let defaultDirectoryPermissions = UInt16(0o755)
let defaultPOSIXBufferSize = defaultReadChunkSize
let defaultDirectoryUnitCount = Int64(1)
let minEndOfCentralDirectoryOffset = Int64(22)
let endOfCentralDirectoryStructSignature = 0x0605_4B50
let localFileHeaderStructSignature = 0x0403_4B50
let dataDescriptorStructSignature = 0x0807_4B50
let centralDirectoryStructSignature = 0x0201_4B50
let memoryURLScheme = "memory"

// MARK: - NEArchive

/// A sequence of uncompressed or compressed ZIP entries.
///
/// You use an `NEArchive` to create, read or update ZIP files.
/// To read an existing ZIP file, you have to pass in an existing file `URL` and `NEAccessMode.read`:
///
///     var archiveURL = URL(fileURLWithPath: "/path/file.zip")
///     var archive = NEArchive(url: archiveURL, NEAccessMode: .read)
///
/// An `NEArchive` is a sequence of entries. You can
/// iterate over an archive using a `for`-`in` loop to get access to individual `NEEntry` objects:
///
///     for entry in archive {
///         print(entry.path)
///     }
///
/// Each `NEEntry` in an `NEArchive` is represented by its `path`. You can
/// use `path` to retrieve the corresponding `NEEntry` from an `NEArchive` via subscripting:
///
///     let entry = archive['/path/file.txt']
///
/// To create a new `NEArchive`, pass in a non-existing file URL and `NEAccessMode.create`. To modify an
/// existing `NEArchive` use `NEAccessMode.update`:
///
///     var archiveURL = URL(fileURLWithPath: "/path/file.zip")
///     var archive = NEArchive(url: archiveURL, NEAccessMode: .update)
///     try archive?.addEntry("test.txt", relativeTo: baseURL, compressionMethod: .deflate)
final class NEArchive: Sequence {
  // MARK: Lifecycle

  /// Initializes a new ZIP `NEArchive`.
  ///
  /// You can use this initalizer to create new archive files or to read and update existing ones.
  /// The `mode` parameter indicates the intended usage of the archive: `.read`, `.create` or `.update`.
  /// - Parameters:
  ///   - url: File URL to the receivers backing file.
  ///   - mode: Access mode of the receiver.
  ///   - preferredEncoding: Encoding for entry paths. Overrides the encoding specified in the archive.
  ///                        This encoding is only used when _decoding_ paths from the receiver.
  ///                        Paths of entries added with `addEntry` are always UTF-8 encoded.
  /// - Returns: An archive initialized with a backing file at the passed in file URL and the given access mode
  ///   or `nil` if the following criteria are not met:
  /// - Note:
  ///   - The file URL _must_ point to an existing file for `AccessMode.read`.
  ///   - The file URL _must_ point to a non-existing file for `AccessMode.create`.
  ///   - The file URL _must_ point to an existing file for `AccessMode.update`.
  init?(url: URL, accessMode mode: NEAccessMode, preferredEncoding: String.Encoding? = nil) {
    self.url = url
    accessMode = mode
    self.preferredEncoding = preferredEncoding
    guard let config = NEArchive.makeBackingConfiguration(for: url, mode: mode) else {
      return nil
    }
    archiveFile = config.file
    endOfCentralDirectoryRecord = config.endOfCentralDirectoryRecord
    zip64EndOfCentralDirectory = config.zip64EndOfCentralDirectory
    setvbuf(archiveFile, nil, _IOFBF, Int(defaultPOSIXBufferSize))
  }

  deinit {
    fclose(self.archiveFile)
  }

  // MARK: Internal

  typealias NELocalFileHeader = NEEntry.NELocalFileHeader
  typealias NEDataDescriptor = NEEntry.DefaultDataDescriptor
  typealias NEZIP64DataDescriptor = NEEntry.ZIP64DataDescriptor
  typealias NECentralDirectoryStructure = NEEntry.NECentralDirectoryStructure

  /// An error that occurs during reading, creating or updating a ZIP file.
  enum NEArchiveError: Error {
    /// Thrown when an archive file is either damaged or inaccessible.
    case unreadableArchive
    /// Thrown when an archive is either opened with NEAccessMode.read or the destination file is unwritable.
    case unwritableArchive
    /// Thrown when the path of an `NEEntry` cannot be stored in an archive.
    case invalidEntryPath
    /// Thrown when an `NEEntry` can't be stored in the archive with the proposed compression method.
    case invalidCompressionMethod
    /// Thrown when the stored checksum of an `NEEntry` doesn't match the checksum during reading.
    case invalidCRC32
    /// Thrown when an extract, add or remove operation was canceled.
    case cancelledOperation
    /// Thrown when an extract operation was called with zero or negative `bufferSize` parameter.
    case invalidBufferSize
    /// Thrown when uncompressedSize/compressedSize exceeds `Int64.max` (Imposed by file API).
    case invalidEntrySize
    /// Thrown when the offset of local header data exceeds `Int64.max` (Imposed by file API).
    case invalidLocalHeaderDataOffset
    /// Thrown when the size of local header exceeds `Int64.max` (Imposed by file API).
    case invalidLocalHeaderSize
    /// Thrown when the offset of central directory exceeds `Int64.max` (Imposed by file API).
    case invalidCentralDirectoryOffset
    /// Thrown when the size of central directory exceeds `UInt64.max` (Imposed by ZIP specification).
    case invalidCentralDirectorySize
    /// Thrown when number of entries in central directory exceeds `UInt64.max` (Imposed by ZIP specification).
    case invalidCentralDirectoryEntryCount
    /// Thrown when an archive does not contain the required End of Central Directory Record.
    case missingEndOfCentralDirectoryRecord
  }

  /// The access mode for an `NEArchive`.
  enum NEAccessMode: UInt {
    /// Indicates that a newly instantiated `NEArchive` should create its backing file.
    case create
    /// Indicates that a newly instantiated `NEArchive` should read from an existing backing file.
    case read
    /// Indicates that a newly instantiated `NEArchive` should update an existing backing file.
    case update
  }

  /// The NEVersion of an `NEArchive`
  enum NEVersion: UInt16 {
    /// The minimum NEVersion for deflate compressed archives
    case v20 = 20
    /// The minimum NEVersion for archives making use of ZIP64 extensions
    case v45 = 45
  }

  struct NEEndOfCentralDirectoryRecord: NEDataSerializable {
    let endOfCentralDirectorySignature = UInt32(endOfCentralDirectoryStructSignature)
    let numberOfDisk: UInt16
    let numberOfDiskStart: UInt16
    let totalNumberOfEntriesOnDisk: UInt16
    let totalNumberOfEntriesInCentralDirectory: UInt16
    let sizeOfCentralDirectory: UInt32
    let offsetToStartOfCentralDirectory: UInt32
    let zipFileCommentLength: UInt16
    let zipFileCommentData: Data
    static let size = 22
  }

  /// URL of an NEArchive's backing file.
  let url: URL
  /// Access mode for an archive file.
  let accessMode: NEAccessMode
  var archiveFile: NEFILEPointer
  var endOfCentralDirectoryRecord: NEEndOfCentralDirectoryRecord
  var zip64EndOfCentralDirectory: ZIP64EndOfCentralDirectory?
  var preferredEncoding: String.Encoding?

  var totalNumberOfEntriesInCentralDirectory: UInt64 {
    zip64EndOfCentralDirectory?.record.totalNumberOfEntriesInCentralDirectory
      ?? UInt64(endOfCentralDirectoryRecord.totalNumberOfEntriesInCentralDirectory)
  }

  var sizeOfCentralDirectory: UInt64 {
    zip64EndOfCentralDirectory?.record.sizeOfCentralDirectory
      ?? UInt64(endOfCentralDirectoryRecord.sizeOfCentralDirectory)
  }

  var offsetToStartOfCentralDirectory: UInt64 {
    zip64EndOfCentralDirectory?.record.offsetToStartOfCentralDirectory
      ?? UInt64(endOfCentralDirectoryRecord.offsetToStartOfCentralDirectory)
  }

  #if swift(>=5.0)
    var memoryFile: NEMemoryFile?

    /// Initializes a new in-memory ZIP `NEArchive`.
    ///
    /// You can use this initalizer to create new in-memory archive files or to read and update existing ones.
    ///
    /// - Parameters:
    ///   - data: `Data` object used as backing for in-memory archives.
    ///   - mode: Access mode of the receiver.
    ///   - preferredEncoding: Encoding for entry paths. Overrides the encoding specified in the archive.
    ///                        This encoding is only used when _decoding_ paths from the receiver.
    ///                        Paths of entries added with `addEntry` are always UTF-8 encoded.
    /// - Returns: An in-memory archive initialized with passed in backing data.
    /// - Note:
    ///   - The backing `data` _must_ contain a valid ZIP archive for `NEAccessMode.read` and `NEAccessMode.update`.
    ///   - The backing `data` _must_ be empty (or omitted) for `NEAccessMode.create`.
    init?(data: Data = Data(), accessMode mode: NEAccessMode, preferredEncoding: String.Encoding? = nil) {
      guard
        let url = URL(string: "\(memoryURLScheme)://"),
        let config = NEArchive.makeBackingConfiguration(for: data, mode: mode)
      else {
        return nil
      }

      self.url = url
      accessMode = mode
      self.preferredEncoding = preferredEncoding
      archiveFile = config.file
      memoryFile = config.memoryFile
      endOfCentralDirectoryRecord = config.endOfCentralDirectoryRecord
      zip64EndOfCentralDirectory = config.zip64EndOfCentralDirectory
    }
  #endif

  // MARK: - Helpers

  static func scanForEndOfCentralDirectoryRecord(in file: NEFILEPointer)
    -> NEEndOfCentralDirectoryStructure? {
    var eocdOffset: UInt64 = 0
    var index = minEndOfCentralDirectoryOffset
    fseeko(file, 0, SEEK_END)
    let archiveLength = Int64(ftello(file))
    while eocdOffset == 0, index <= archiveLength {
      fseeko(file, off_t(archiveLength - index), SEEK_SET)
      var potentialDirectoryEndTag = UInt32()
      fread(&potentialDirectoryEndTag, 1, MemoryLayout<UInt32>.size, file)
      if potentialDirectoryEndTag == UInt32(endOfCentralDirectoryStructSignature) {
        eocdOffset = UInt64(archiveLength - index)
        guard let eocd: NEEndOfCentralDirectoryRecord = Data.neReadStruct(from: file, at: eocdOffset) else {
          return nil
        }
        let zip64EOCD = scanForZIP64EndOfCentralDirectory(in: file, eocdOffset: eocdOffset)
        return (eocd, zip64EOCD)
      }
      index += 1
    }
    return nil
  }

  func makeIterator() -> AnyIterator<NEEntry> {
    let totalNumberOfEntriesInCD = totalNumberOfEntriesInCentralDirectory
    var directoryIndex = offsetToStartOfCentralDirectory
    var index = 0
    return AnyIterator {
      guard index < totalNumberOfEntriesInCD else { return nil }
      guard
        let centralDirStruct: NECentralDirectoryStructure = Data.neReadStruct(
          from: self.archiveFile,
          at: directoryIndex
        )
      else {
        return nil
      }
      let offset = UInt64(centralDirStruct.effectiveRelativeOffsetOfLocalHeader)
      guard
        let localFileHeader: NELocalFileHeader = Data.neReadStruct(
          from: self.archiveFile,
          at: offset
        )
      else { return nil }
      var dataDescriptor: NEDataDescriptor?
      var zip64DataDescriptor: NEZIP64DataDescriptor?
      if centralDirStruct.usesDataDescriptor {
        let additionalSize = UInt64(localFileHeader.fileNameLength) + UInt64(localFileHeader.extraFieldLength)
        let isCompressed = centralDirStruct.compressionMethod != NECompressionMethod.none.rawValue
        let dataSize = isCompressed
          ? centralDirStruct.effectiveCompressedSize
          : centralDirStruct.effectiveUncompressedSize
        let descriptorPosition = offset + UInt64(NELocalFileHeader.size) + additionalSize + dataSize
        if centralDirStruct.isZIP64 {
          zip64DataDescriptor = Data.neReadStruct(from: self.archiveFile, at: descriptorPosition)
        } else {
          dataDescriptor = Data.neReadStruct(from: self.archiveFile, at: descriptorPosition)
        }
      }
      defer {
        directoryIndex += UInt64(NECentralDirectoryStructure.size)
        directoryIndex += UInt64(centralDirStruct.fileNameLength)
        directoryIndex += UInt64(centralDirStruct.extraFieldLength)
        directoryIndex += UInt64(centralDirStruct.fileCommentLength)
        index += 1
      }
      return NEEntry(
        centralDirectoryStructure: centralDirStruct,
        localFileHeader: localFileHeader,
        dataDescriptor: dataDescriptor,
        zip64DataDescriptor: zip64DataDescriptor
      )
    }
  }

  /// Retrieve the ZIP `NEEntry` with the given `path` from the receiver.
  ///
  /// - Note: The ZIP file format specification does not enforce unique paths for entries.
  ///   Therefore an archive can contain multiple entries with the same path. This method
  ///   always returns the first `NEEntry` with the given `path`.
  ///
  /// - Parameter path: A relative file path identifying the corresponding `NEEntry`.
  /// - Returns: An `NEEntry` with the given `path`. Otherwise, `nil`.
  subscript(path: String) -> NEEntry? {
    if let encoding = preferredEncoding {
      return first { $0.path(using: encoding) == path }
    }
    return first { $0.path == path }
  }

  // MARK: Private

  private static func scanForZIP64EndOfCentralDirectory(in file: NEFILEPointer, eocdOffset: UInt64)
    -> ZIP64EndOfCentralDirectory? {
    guard UInt64(ZIP64EndOfCentralDirectoryLocator.size) < eocdOffset else {
      return nil
    }
    let locatorOffset = eocdOffset - UInt64(ZIP64EndOfCentralDirectoryLocator.size)

    guard UInt64(ZIP64EndOfCentralDirectoryRecord.size) < locatorOffset else {
      return nil
    }
    let recordOffset = locatorOffset - UInt64(ZIP64EndOfCentralDirectoryRecord.size)
    guard
      let locator: ZIP64EndOfCentralDirectoryLocator = Data.neReadStruct(from: file, at: locatorOffset),
      let record: ZIP64EndOfCentralDirectoryRecord = Data.neReadStruct(from: file, at: recordOffset)
    else {
      return nil
    }
    return ZIP64EndOfCentralDirectory(record: record, locator: locator)
  }
}

extension NEArchive.NEEndOfCentralDirectoryRecord {
  // MARK: Lifecycle

  init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
    guard data.count == NEArchive.NEEndOfCentralDirectoryRecord.size else { return nil }
    guard data.neScanValue(start: 0) == endOfCentralDirectorySignature else { return nil }
    numberOfDisk = data.neScanValue(start: 4)
    numberOfDiskStart = data.neScanValue(start: 6)
    totalNumberOfEntriesOnDisk = data.neScanValue(start: 8)
    totalNumberOfEntriesInCentralDirectory = data.neScanValue(start: 10)
    sizeOfCentralDirectory = data.neScanValue(start: 12)
    offsetToStartOfCentralDirectory = data.neScanValue(start: 16)
    zipFileCommentLength = data.neScanValue(start: 20)
    guard let commentData = try? provider(Int(zipFileCommentLength)) else { return nil }
    guard commentData.count == Int(zipFileCommentLength) else { return nil }
    zipFileCommentData = commentData
  }

  init(record: NEArchive.NEEndOfCentralDirectoryRecord,
       numberOfEntriesOnDisk: UInt16,
       numberOfEntriesInCentralDirectory: UInt16,
       updatedSizeOfCentralDirectory: UInt32,
       startOfCentralDirectory: UInt32) {
    numberOfDisk = record.numberOfDisk
    numberOfDiskStart = record.numberOfDiskStart
    totalNumberOfEntriesOnDisk = numberOfEntriesOnDisk
    totalNumberOfEntriesInCentralDirectory = numberOfEntriesInCentralDirectory
    sizeOfCentralDirectory = updatedSizeOfCentralDirectory
    offsetToStartOfCentralDirectory = startOfCentralDirectory
    zipFileCommentLength = record.zipFileCommentLength
    zipFileCommentData = record.zipFileCommentData
  }

  // MARK: Internal

  var data: Data {
    var endOfCDSignature = endOfCentralDirectorySignature
    var numberOfDisk = numberOfDisk
    var numberOfDiskStart = numberOfDiskStart
    var totalNumberOfEntriesOnDisk = totalNumberOfEntriesOnDisk
    var totalNumberOfEntriesInCD = totalNumberOfEntriesInCentralDirectory
    var sizeOfCentralDirectory = sizeOfCentralDirectory
    var offsetToStartOfCD = offsetToStartOfCentralDirectory
    var zipFileCommentLength = zipFileCommentLength
    var data = Data()
    withUnsafePointer(to: &endOfCDSignature) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &numberOfDisk) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &numberOfDiskStart) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &totalNumberOfEntriesOnDisk) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &totalNumberOfEntriesInCD) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &sizeOfCentralDirectory) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &offsetToStartOfCD) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    withUnsafePointer(to: &zipFileCommentLength) { data.append(UnsafeBufferPointer(start: $0, count: 1)) }
    data.append(zipFileCommentData)
    return data
  }
}
