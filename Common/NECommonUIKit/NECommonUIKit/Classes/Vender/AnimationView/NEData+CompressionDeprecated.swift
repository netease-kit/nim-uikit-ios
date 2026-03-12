
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension Data {
  @available(*, deprecated, message: "Please use `Int64` for `size` and provider `position`.")
  static func neCompress(size: Int,
                         bufferSize: Int,
                         provider: (_ position: Int, _ size: Int) throws -> Data,
                         consumer: NEConsumer)
    throws -> NECRC32 {
    let newProvider: NEProvider = { try provider(Int($0), $1) }
    return try neCompress(size: Int64(size), bufferSize: bufferSize, provider: newProvider, consumer: consumer)
  }

  @available(*, deprecated, message: "Please use `Int64` for `size` and provider `position`.")
  static func neDecompress(size: Int,
                           bufferSize: Int,
                           skipCRC32: Bool,
                           provider: (_ position: Int, _ size: Int) throws -> Data,
                           consumer: NEConsumer)
    throws -> NECRC32 {
    let newProvider: NEProvider = { try provider(Int($0), $1) }
    return try neDecompress(
      size: Int64(size),
      bufferSize: bufferSize,
      skipCRC32: skipCRC32,
      provider: newProvider,
      consumer: consumer
    )
  }
}
