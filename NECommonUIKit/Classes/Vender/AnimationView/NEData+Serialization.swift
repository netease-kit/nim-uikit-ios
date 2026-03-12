
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

#if os(Android)
  typealias NEFILEPointer = OpaquePointer
#else
  typealias NEFILEPointer = UnsafeMutablePointer<FILE>
#endif

// MARK: - NEDataSerializable

protocol NEDataSerializable {
  static var size: Int { get }
  init?(data: Data, additionalDataProvider: (Int) throws -> Data)
  var data: Data { get }
}

extension Data {
  enum NEDataError: Error {
    case unreadableFile
    case unwritableFile
  }

  static func neReadStruct<T>(from file: NEFILEPointer, at offset: UInt64)
    -> T? where T: NEDataSerializable {
    guard offset <= .max else { return nil }
    fseeko(file, off_t(offset), SEEK_SET)
    guard let data = try? neReadChunk(of: T.size, from: file) else {
      return nil
    }
    let structure = T(data: data, additionalDataProvider: { additionalDataSize -> Data in
      try self.neReadChunk(of: additionalDataSize, from: file)
    })
    return structure
  }

  static func neConsumePart(of size: Int64,
                            chunkSize: Int,
                            skipCRC32: Bool = false,
                            provider: NEProvider,
                            consumer: NEConsumer)
    throws -> NECRC32 {
    var checksum = NECRC32(0)
    guard size > 0 else {
      try consumer(Data())
      return checksum
    }

    let readInOneChunk = (size < chunkSize)
    var chunkSize = readInOneChunk ? Int(size) : chunkSize
    var bytesRead: Int64 = 0
    while bytesRead < size {
      let remainingSize = size - bytesRead
      chunkSize = remainingSize < chunkSize ? Int(remainingSize) : chunkSize
      let data = try provider(bytesRead, chunkSize)
      try consumer(data)
      if !skipCRC32 {
        checksum = data.neCrc32(checksum: checksum)
      }
      bytesRead += Int64(chunkSize)
    }
    return checksum
  }

  static func neReadChunk(of size: Int, from file: NEFILEPointer) throws -> Data {
    let alignment = MemoryLayout<UInt>.alignment
    #if swift(>=4.1)
      let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
    #else
      let bytes = UnsafeMutableRawPointer.allocate(bytes: size, alignedTo: alignment)
    #endif
    let bytesRead = fread(bytes, 1, size, file)
    let error = ferror(file)
    if error > 0 {
      throw NEDataError.unreadableFile
    }
    #if swift(>=4.1)
      return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: .custom { buf, _ in buf.deallocate() })
    #else
      let deallocator = Deallocator.custom { buf, _ in buf.deallocate(bytes: size, alignedTo: 1) }
      return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: deallocator)
    #endif
  }

  static func neWrite(chunk: Data, to file: NEFILEPointer) throws -> Int {
    var sizeWritten = 0
    chunk.withUnsafeBytes { rawBufferPointer in
      if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        sizeWritten = fwrite(pointer, 1, chunk.count, file)
      }
    }
    let error = ferror(file)
    if error > 0 {
      throw NEDataError.unwritableFile
    }
    return sizeWritten
  }

  static func neWriteLargeChunk(_ chunk: Data,
                                size: UInt64,
                                bufferSize: Int,
                                to file: NEFILEPointer)
    throws -> UInt64 {
    var sizeWritten: UInt64 = 0
    chunk.withUnsafeBytes { rawBufferPointer in
      if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)

        while sizeWritten < size {
          let remainingSize = size - sizeWritten
          let chunkSize = Swift.min(Int(remainingSize), bufferSize)
          let curPointer = pointer.advanced(by: Int(sizeWritten))
          fwrite(curPointer, 1, chunkSize, file)
          sizeWritten += UInt64(chunkSize)
        }
      }
    }
    let error = ferror(file)
    if error > 0 {
      throw NEDataError.unwritableFile
    }
    return sizeWritten
  }

  func neScanValue<T>(start: Int) -> T {
    let subdata = subdata(in: start ..< start + MemoryLayout<T>.size)
    #if swift(>=5.0)
      return subdata.withUnsafeBytes { $0.load(as: T.self) }
    #else
      return subdata.withUnsafeBytes { $0.pointee }
    #endif
  }
}
