
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEAnyEquatable

struct NEAnyEquatable {
  private let value: Any
  private let equals: (Any) -> Bool

  init<T: Equatable>(_ value: T) {
    self.value = value
    equals = { $0 as? T == value }
  }
}

// MARK: Equatable

extension NEAnyEquatable: Equatable {
  static func == (lhs: NEAnyEquatable, rhs: NEAnyEquatable) -> Bool {
    lhs.equals(rhs.value)
  }
}
