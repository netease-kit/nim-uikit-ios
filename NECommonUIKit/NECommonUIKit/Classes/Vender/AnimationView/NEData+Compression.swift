
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

#if canImport(zlib)
  import zlib
#endif

// MARK: - NECompressionMethod

/// The compression method of an `NEEntry` in a ZIP `NEArchive`.
enum NECompressionMethod: UInt16 {
  /// Indicates that an `NEEntry` has no compression applied to its contents.
  case none = 0
  /// Indicates that contents of an `NEEntry` have been compressed with a zlib compatible Deflate algorithm.
  case deflate = 8
}

/// An unsigned 32-Bit Integer representing a checksum.
typealias NECRC32 = UInt32
/// A custom handler that consumes a `Data` object containing partial entry data.
/// - Parameters:
///   - data: A chunk of `Data` to consume.
/// - Throws: Can throw to indicate errors during data consumption.
typealias NEConsumer = (_ data: Data) throws -> Void
/// A custom handler that receives a position and a size that can be used to provide data from an arbitrary source.
/// - Parameters:
///   - position: The current read position.
///   - size: The size of the chunk to provide.
/// - Returns: A chunk of `Data`.
/// - Throws: Can throw to indicate errors in the data source.
typealias NEProvider = (_ position: Int64, _ size: Int) throws -> Data

extension Data {
  enum NECompressionError: Error {
    case invalidStream
    case corruptedData
  }

  /// Compress the output of `provider` and pass it to `consumer`.
  /// - Parameters:
  ///   - size: The uncompressed size of the data to be compressed.
  ///   - bufferSize: The maximum size of the compression buffer.
  ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
  ///   - consumer: A closure that processes the result of the compress operation.
  /// - Returns: The checksum of the processed content.
  static func neCompress(size: Int64, bufferSize: Int, provider: NEProvider, consumer: NEConsumer) throws -> NECRC32 {
    #if os(macOS) || canImport(UIKit)
      return try neProcess(
        operation: COMPRESSION_STREAM_ENCODE,
        size: size,
        bufferSize: bufferSize,
        provider: provider,
        consumer: consumer
      )
    #else
      return try encode(size: size, bufferSize: bufferSize, provider: provider, consumer: consumer)
    #endif
  }

  /// Decompress the output of `provider` and pass it to `consumer`.
  /// - Parameters:
  ///   - size: The compressed size of the data to be decompressed.
  ///   - bufferSize: The maximum size of the decompression buffer.
  ///   - skipCRC32: Optional flag to skip calculation of the NECRC32 checksum to improve performance.
  ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
  ///   - consumer: A closure that processes the result of the decompress operation.
  /// - Returns: The checksum of the processed content.
  static func neDecompress(size: Int64,
                           bufferSize: Int,
                           skipCRC32: Bool,
                           provider: NEProvider,
                           consumer: NEConsumer)
    throws -> NECRC32 {
    #if os(macOS) || canImport(UIKit)
      return try neProcess(
        operation: COMPRESSION_STREAM_DECODE,
        size: size,
        bufferSize: bufferSize,
        skipCRC32: skipCRC32,
        provider: provider,
        consumer: consumer
      )
    #else
      return try decode(bufferSize: bufferSize, skipCRC32: skipCRC32, provider: provider, consumer: consumer)
    #endif
  }

  /// Calculate the `NECRC32` checksum of the receiver.
  ///
  /// - Parameter checksum: The starting seed.
  /// - Returns: The checksum calculated from the bytes of the receiver and the starting seed.
  func neCrc32(checksum: NECRC32) -> NECRC32 {
    #if canImport(zlib)
      return withUnsafeBytes { bufferPointer in
        let length = UInt32(count)
        return NECRC32(zlib.crc32(UInt(checksum), bufferPointer.bindMemory(to: UInt8.self).baseAddress, length))
      }
    #else
      return builtInCRC32(checksum: checksum)
    #endif
  }
}

// MARK: - Apple Platforms

#if os(macOS) || canImport(UIKit)
  import Compression

  extension Data {
    static func neProcess(operation: compression_stream_operation,
                          size: Int64,
                          bufferSize: Int,
                          skipCRC32: Bool = false,
                          provider: NEProvider,
                          consumer: NEConsumer)
      throws -> NECRC32 {
      var crc32 = NECRC32(0)
      let destPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
      defer { destPointer.deallocate() }
      let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
      defer { streamPointer.deallocate() }
      var stream = streamPointer.pointee
      var status = compression_stream_init(&stream, operation, COMPRESSION_ZLIB)
      guard status != COMPRESSION_STATUS_ERROR else { throw NECompressionError.invalidStream }
      defer { compression_stream_destroy(&stream) }
      stream.src_size = 0
      stream.dst_ptr = destPointer
      stream.dst_size = bufferSize
      var position: Int64 = 0
      var sourceData: Data?
      repeat {
        let isExhausted = stream.src_size == 0
        if isExhausted {
          do {
            sourceData = try provider(position, Int(Swift.min(size - position, Int64(bufferSize))))
            position += Int64(stream.prepare(for: sourceData))
          } catch { throw error }
        }
        if let sourceData {
          sourceData.withUnsafeBytes { rawBufferPointer in
            if let baseAddress = rawBufferPointer.baseAddress {
              let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
              stream.src_ptr = pointer.advanced(by: sourceData.count - stream.src_size)
              let flags = sourceData.count < bufferSize ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
              status = compression_stream_process(&stream, flags)
            }
          }
          if
            operation == COMPRESSION_STREAM_ENCODE,
            isExhausted, skipCRC32 == false { crc32 = sourceData.neCrc32(checksum: crc32) }
        }
        switch status {
        case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
          let outputData = Data(bytesNoCopy: destPointer, count: bufferSize - stream.dst_size, deallocator: .none)
          try consumer(outputData)
          if operation == COMPRESSION_STREAM_DECODE, !skipCRC32 { crc32 = outputData.neCrc32(checksum: crc32) }
          stream.dst_ptr = destPointer
          stream.dst_size = bufferSize
        default: throw NECompressionError.corruptedData
        }
      } while status == COMPRESSION_STATUS_OK
      return crc32
    }
  }

  fileprivate extension compression_stream {
    mutating func prepare(for sourceData: Data?) -> Int {
      guard let sourceData else { return 0 }

      src_size = sourceData.count
      return sourceData.count
    }
  }

  // MARK: - Linux

#else
  import CZlib

  extension Data {
    static func encode(size: Int64, bufferSize: Int, provider: NEProvider, consumer: NEConsumer) throws -> NECRC32 {
      var stream = z_stream()
      let streamSize = Int32(MemoryLayout<z_stream>.size)
      var result = deflateInit2_(
        &stream,
        Z_DEFAULT_COMPRESSION,
        Z_DEFLATED,
        -MAX_WBITS,
        9,
        Z_DEFAULT_STRATEGY,
        ZLIB_NEVersion,
        streamSize
      )
      defer { deflateEnd(&stream) }
      guard result == Z_OK else { throw CompressionError.invalidStream }
      var flush = Z_NO_FLUSH
      var position: Int64 = 0
      var zipCRC32 = NECRC32(0)
      repeat {
        let readSize = Int(Swift.min(size - position, Int64(bufferSize)))
        var inputChunk = try provider(position, readSize)
        zipCRC32 = inputChunk.crc32(checksum: zipCRC32)
        stream.avail_in = UInt32(inputChunk.count)
        try inputChunk.withUnsafeMutableBytes { rawBufferPointer in
          if let baseAddress = rawBufferPointer.baseAddress {
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            stream.next_in = pointer
            flush = position + Int64(bufferSize) >= size ? Z_FINISH : Z_NO_FLUSH
          } else if rawBufferPointer.count > 0 {
            throw CompressionError.corruptedData
          } else {
            stream.next_in = nil
            flush = Z_FINISH
          }
          var outputChunk = Data(count: bufferSize)
          repeat {
            stream.avail_out = UInt32(bufferSize)
            try outputChunk.withUnsafeMutableBytes { rawBufferPointer in
              guard let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 else {
                throw CompressionError.corruptedData
              }
              let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
              stream.next_out = pointer
              result = deflate(&stream, flush)
            }
            guard result >= Z_OK else { throw CompressionError.corruptedData }

            outputChunk.count = bufferSize - Int(stream.avail_out)
            try consumer(outputChunk)
          } while stream.avail_out == 0
        }
        position += Int64(readSize)
      } while flush != Z_FINISH
      return zipCRC32
    }

    static func decode(bufferSize: Int, skipCRC32: Bool, provider: NEProvider, consumer: NEConsumer) throws -> NECRC32 {
      var stream = z_stream()
      let streamSize = Int32(MemoryLayout<z_stream>.size)
      var result = inflateInit2_(&stream, -MAX_WBITS, ZLIB_NEVersion, streamSize)
      defer { inflateEnd(&stream) }
      guard result == Z_OK else { throw CompressionError.invalidStream }
      var unzipCRC32 = NECRC32(0)
      var position: Int64 = 0
      repeat {
        stream.avail_in = UInt32(bufferSize)
        var chunk = try provider(position, bufferSize)
        position += Int64(chunk.count)
        try chunk.withUnsafeMutableBytes { rawBufferPointer in
          if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            stream.next_in = pointer
            repeat {
              var outputData = Data(count: bufferSize)
              stream.avail_out = UInt32(bufferSize)
              try outputData.withUnsafeMutableBytes { rawBufferPointer in
                if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
                  let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                  stream.next_out = pointer
                } else {
                  throw CompressionError.corruptedData
                }
                result = inflate(&stream, Z_NO_FLUSH)
                guard
                  result != Z_NEED_DICT,
                  result != Z_DATA_ERROR,
                  result != Z_MEM_ERROR
                else {
                  throw CompressionError.corruptedData
                }
              }
              let remainingLength = UInt32(bufferSize) - stream.avail_out
              outputData.count = Int(remainingLength)
              try consumer(outputData)
              if !skipCRC32 { unzipCRC32 = outputData.crc32(checksum: unzipCRC32) }
            } while stream.avail_out == 0
          }
        }
      } while result != Z_STREAM_END
      return unzipCRC32
    }
  }

#endif

/// The lookup table used to calculate `NECRC32` checksums when using the built-in
/// NECRC32 implementation.
private let crcTable: [NECRC32] = [
  0x0000_0000, 0x7707_3096, 0xEE0E_612C, 0x9909_51BA, 0x076D_C419, 0x706A_F48F, 0xE963_A535, 0x9E64_95A3, 0x0EDB_8832,
  0x79DC_B8A4, 0xE0D5_E91E, 0x97D2_D988, 0x09B6_4C2B, 0x7EB1_7CBD, 0xE7B8_2D07, 0x90BF_1D91, 0x1DB7_1064, 0x6AB0_20F2,
  0xF3B9_7148, 0x84BE_41DE, 0x1ADA_D47D, 0x6DDD_E4EB, 0xF4D4_B551, 0x83D3_85C7, 0x136C_9856, 0x646B_A8C0, 0xFD62_F97A,
  0x8A65_C9EC, 0x1401_5C4F, 0x6306_6CD9, 0xFA0F_3D63, 0x8D08_0DF5, 0x3B6E_20C8, 0x4C69_105E, 0xD560_41E4, 0xA267_7172,
  0x3C03_E4D1, 0x4B04_D447, 0xD20D_85FD, 0xA50A_B56B, 0x35B5_A8FA, 0x42B2_986C, 0xDBBB_C9D6, 0xACBC_F940, 0x32D8_6CE3,
  0x45DF_5C75, 0xDCD6_0DCF, 0xABD1_3D59, 0x26D9_30AC, 0x51DE_003A, 0xC8D7_5180, 0xBFD0_6116, 0x21B4_F4B5, 0x56B3_C423,
  0xCFBA_9599, 0xB8BD_A50F, 0x2802_B89E, 0x5F05_8808, 0xC60C_D9B2, 0xB10B_E924, 0x2F6F_7C87, 0x5868_4C11, 0xC161_1DAB,
  0xB666_2D3D, 0x76DC_4190, 0x01DB_7106, 0x98D2_20BC, 0xEFD5_102A, 0x71B1_8589, 0x06B6_B51F, 0x9FBF_E4A5, 0xE8B8_D433,
  0x7807_C9A2, 0x0F00_F934, 0x9609_A88E, 0xE10E_9818, 0x7F6A_0DBB, 0x086D_3D2D, 0x9164_6C97, 0xE663_5C01, 0x6B6B_51F4,
  0x1C6C_6162, 0x8565_30D8, 0xF262_004E, 0x6C06_95ED, 0x1B01_A57B, 0x8208_F4C1, 0xF50F_C457, 0x65B0_D9C6, 0x12B7_E950,
  0x8BBE_B8EA, 0xFCB9_887C, 0x62DD_1DDF, 0x15DA_2D49, 0x8CD3_7CF3, 0xFBD4_4C65, 0x4DB2_6158, 0x3AB5_51CE, 0xA3BC_0074,
  0xD4BB_30E2, 0x4ADF_A541, 0x3DD8_95D7, 0xA4D1_C46D, 0xD3D6_F4FB, 0x4369_E96A, 0x346E_D9FC, 0xAD67_8846, 0xDA60_B8D0,
  0x4404_2D73, 0x3303_1DE5, 0xAA0A_4C5F, 0xDD0D_7CC9, 0x5005_713C, 0x2702_41AA, 0xBE0B_1010, 0xC90C_2086, 0x5768_B525,
  0x206F_85B3, 0xB966_D409, 0xCE61_E49F, 0x5EDE_F90E, 0x29D9_C998, 0xB0D0_9822, 0xC7D7_A8B4, 0x59B3_3D17, 0x2EB4_0D81,
  0xB7BD_5C3B, 0xC0BA_6CAD, 0xEDB8_8320, 0x9ABF_B3B6, 0x03B6_E20C, 0x74B1_D29A, 0xEAD5_4739, 0x9DD2_77AF, 0x04DB_2615,
  0x73DC_1683, 0xE363_0B12, 0x9464_3B84, 0x0D6D_6A3E, 0x7A6A_5AA8, 0xE40E_CF0B, 0x9309_FF9D, 0x0A00_AE27, 0x7D07_9EB1,
  0xF00F_9344, 0x8708_A3D2, 0x1E01_F268, 0x6906_C2FE, 0xF762_575D, 0x8065_67CB, 0x196C_3671, 0x6E6B_06E7, 0xFED4_1B76,
  0x89D3_2BE0, 0x10DA_7A5A, 0x67DD_4ACC, 0xF9B9_DF6F, 0x8EBE_EFF9, 0x17B7_BE43, 0x60B0_8ED5, 0xD6D6_A3E8, 0xA1D1_937E,
  0x38D8_C2C4, 0x4FDF_F252, 0xD1BB_67F1, 0xA6BC_5767, 0x3FB5_06DD, 0x48B2_364B, 0xD80D_2BDA, 0xAF0A_1B4C, 0x3603_4AF6,
  0x4104_7A60, 0xDF60_EFC3, 0xA867_DF55, 0x316E_8EEF, 0x4669_BE79, 0xCB61_B38C, 0xBC66_831A, 0x256F_D2A0, 0x5268_E236,
  0xCC0C_7795, 0xBB0B_4703, 0x2202_16B9, 0x5505_262F, 0xC5BA_3BBE, 0xB2BD_0B28, 0x2BB4_5A92, 0x5CB3_6A04, 0xC2D7_FFA7,
  0xB5D0_CF31, 0x2CD9_9E8B, 0x5BDE_AE1D, 0x9B64_C2B0, 0xEC63_F226, 0x756A_A39C, 0x026D_930A, 0x9C09_06A9, 0xEB0E_363F,
  0x7207_6785, 0x0500_5713, 0x95BF_4A82, 0xE2B8_7A14, 0x7BB1_2BAE, 0x0CB6_1B38, 0x92D2_8E9B, 0xE5D5_BE0D, 0x7CDC_EFB7,
  0x0BDB_DF21, 0x86D3_D2D4, 0xF1D4_E242, 0x68DD_B3F8, 0x1FDA_836E, 0x81BE_16CD, 0xF6B9_265B, 0x6FB0_77E1, 0x18B7_4777,
  0x8808_5AE6, 0xFF0F_6A70, 0x6606_3BCA, 0x1101_0B5C, 0x8F65_9EFF, 0xF862_AE69, 0x616B_FFD3, 0x166C_CF45, 0xA00A_E278,
  0xD70D_D2EE, 0x4E04_8354, 0x3903_B3C2, 0xA767_2661, 0xD060_16F7, 0x4969_474D, 0x3E6E_77DB, 0xAED1_6A4A, 0xD9D6_5ADC,
  0x40DF_0B66, 0x37D8_3BF0, 0xA9BC_AE53, 0xDEBB_9EC5, 0x47B2_CF7F, 0x30B5_FFE9, 0xBDBD_F21C, 0xCABA_C28A, 0x53B3_9330,
  0x24B4_A3A6, 0xBAD0_3605, 0xCDD7_0693, 0x54DE_5729, 0x23D9_67BF, 0xB366_7A2E, 0xC461_4AB8, 0x5D68_1B02, 0x2A6F_2B94,
  0xB40B_BE37, 0xC30C_8EA1, 0x5A05_DF1B, 0x2D02_EF8D,
]

extension Data {
  /// Lookup table-based NECRC32 implenetation that is used
  /// if `zlib` isn't available.
  /// - Parameter checksum: Running checksum or `0` for the initial run.
  /// - Returns: The calculated checksum of the receiver.
  func builtInCRC32(checksum: NECRC32) -> NECRC32 {
    // The typecast is necessary on 32-bit platforms because of
    // https://bugs.swift.org/browse/SR-1774
    let mask = 0xFFFF_FFFF as NECRC32
    var result = checksum ^ mask
    #if swift(>=5.0)
      crcTable.withUnsafeBufferPointer { crcTablePointer in
        self.withUnsafeBytes { bufferPointer in
          var bufferIndex = 0
          while bufferIndex < self.count {
            let byte = bufferPointer[bufferIndex]
            let index = Int((result ^ NECRC32(byte)) & 0xFF)
            result = (result >> 8) ^ crcTablePointer[index]
            bufferIndex += 1
          }
        }
      }
    #else
      withUnsafeBytes { bytes in
        let bins = stride(from: 0, to: self.count, by: 256)
        for bin in bins {
          for binIndex in 0 ..< 256 {
            let byteIndex = bin + binIndex
            guard byteIndex < self.count else { break }

            let byte = bytes[byteIndex]
            let index = Int((result ^ NECRC32(byte)) & 0xFF)
            result = (result >> 8) ^ crcTable[index]
          }
        }
      }
    #endif
    return result ^ mask
  }
}

#if !swift(>=5.0)

  // Since Swift 5.0, `Data.withUnsafeBytes()` passes an `UnsafeRawBufferPointer` instead of an `UnsafePointer<UInt8>`
  // into `body`.
  // We provide a compatible method for targets that use Swift 4.x so that we can use the new Version
  // across all language NEVersions.

  extension Data {
    func withUnsafeBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
      let count = count
      return try withUnsafeBytes { (pointer: UnsafePointer<UInt8>) throws -> T in
        try body(UnsafeRawBufferPointer(start: pointer, count: count))
      }
    }

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    #else
      mutating func withUnsafeMutableBytes<T>(_ body: (UnsafeMutableRawBufferPointer) throws -> T) rethrows -> T {
        let count = count
        guard count > 0 else {
          return try body(UnsafeMutableRawBufferPointer(start: nil, count: count))
        }
        return try withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) throws -> T in
          try body(UnsafeMutableRawBufferPointer(start: pointer, count: count))
        }
      }
    #endif
  }
#endif
