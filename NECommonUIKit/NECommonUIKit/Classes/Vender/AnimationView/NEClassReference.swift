
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEClassReference

/// A `Hashable` value wrapper around an `AnyClass` value
///  - Unlike `ObjectIdentifier(class)`, `NEClassReference(class)`
///    preserves the `AnyClass` value and is more human-readable.
struct NEClassReference {
  init(_ class: AnyClass) {
    self.class = `class`
  }

  let `class`: AnyClass
}

// MARK: Equatable

extension NEClassReference: Equatable {
  static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    ObjectIdentifier(lhs.class) == ObjectIdentifier(rhs.class)
  }
}

// MARK: Hashable

extension NEClassReference: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(`class`))
  }
}

// MARK: CustomStringConvertible

extension NEClassReference: CustomStringConvertible {
  var description: String {
    String(describing: `class`)
  }
}
