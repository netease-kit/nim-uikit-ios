
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEInitializableError

enum NEInitializableError: Error {
  case invalidInput(file: StaticString = #file, line: UInt = #line)
}

// MARK: - NEDictionaryInitializable

protocol NEDictionaryInitializable {
  init(dictionary: [String: Any]) throws
}

// MARK: - NEAnyInitializable

protocol NEAnyInitializable {
  init(value: Any) throws
}

extension Dictionary {
  @_disfavoredOverload
  func value<T, KeyType: RawRepresentable>(for key: KeyType,
                                           file: StaticString = #file,
                                           line: UInt = #line)
    throws -> T where KeyType.RawValue == Key {
    guard let value = self[key.rawValue] as? T else {
      throw NEInitializableError.invalidInput(file: file, line: line)
    }
    return value
  }

  func value<T: NEAnyInitializable, KeyType: RawRepresentable>(for key: KeyType,
                                                               file: StaticString = #file,
                                                               line: UInt = #line)
    throws -> T where KeyType.RawValue == Key {
    if let value = self[key.rawValue] as? T {
      return value
    }

    if let value = self[key.rawValue] {
      return try T(value: value)
    }

    throw NEInitializableError.invalidInput(file: file, line: line)
  }
}

// MARK: - NEAnyInitializable + NEAnyInitializable

extension [Double]: NEAnyInitializable {
  init(value: Any) throws {
    guard let array = value as? [Double] else {
      throw NEInitializableError.invalidInput()
    }
    self = array
  }
}
