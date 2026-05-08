// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 线程安全的整型原子计数器（用于并行任务计数）
final class NEAtomicInt {
  private var _value: Int
  private let lock = NSLock()

  init(_ initial: Int = 0) {
    _value = initial
  }

  var value: Int {
    lock.lock(); defer { lock.unlock() }
    return _value
  }

  /// 递减并返回递减后的值
  @discardableResult
  func decrement() -> Int {
    lock.lock(); defer { lock.unlock() }
    _value -= 1
    return _value
  }

  /// 递增并返回递增后的值
  @discardableResult
  func increment() -> Int {
    lock.lock(); defer { lock.unlock() }
    _value += 1
    return _value
  }
}

/// 线程安全的布尔原子标志（用于并行任务错误标记）
final class NEAtomicBool {
  private var _value: Bool
  private let lock = NSLock()

  init(_ initial: Bool = false) {
    _value = initial
  }

  var value: Bool {
    lock.lock(); defer { lock.unlock() }
    return _value
  }

  /// CAS 操作：仅当当前值等于 expected 时才将值置为 desired，返回是否成功
  @discardableResult
  func compareAndSet(_ expected: Bool, to desired: Bool) -> Bool {
    lock.lock(); defer { lock.unlock() }
    guard _value == expected else { return false }
    _value = desired
    return true
  }
}
