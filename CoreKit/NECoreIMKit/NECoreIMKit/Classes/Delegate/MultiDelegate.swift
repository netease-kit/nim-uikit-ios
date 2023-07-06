
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
/**
 *  `MultiDelegate` lets you easily create a "multicast delegate" for a given protocol or class.
 */
open class MultiDelegate<T> {
  /// The delegates hash table.
  private let delegates: NSHashTable<AnyObject>

  /**
   *  Use the property to check if no delegates are contained there.
   *
   *  - returns: `true` if there are no delegates at all, `false` if there is at least one.
   */
  public var isEmpty: Bool {
    delegates.allObjects.count == 0
  }

  /**
   *  Use this method to initialize a new `MultiDelegate` specifying whether delegate references should be weak or
   *  strong.
   *
   *  - parameter strongReferences: Whether delegates should be strongly referenced, false by default.
   *
   *  - returns: A new `MultiDelegate` instance
   */
  public init(strongReferences: Bool = false) {
    delegates = strongReferences ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>
      .weakObjects()
  }

  /**
   *  Use this method to initialize a new `MultiDelegate` specifying the storage options yourself.
   *
   *  - parameter options: The underlying storage options to use
   *
   *  - returns: A new `MultiDelegate` instance
   */
  public init(options: NSPointerFunctions.Options) {
    delegates = NSHashTable<AnyObject>(options: options, capacity: 0)
  }

  /**
   *  Use this method to add a delelgate.
   *
   *  Alternatively, you can use the `+=` operator to add a delegate.
   *
   *  - parameter delegate:  The delegate to be added.
   */
  public func addDelegate(_ delegate: T) {
    delegates.add(delegate as AnyObject)
  }

  /**
   *  Use this method to remove a previously-added delegate.
   *
   *  Alternatively, you can use the `-=` operator to add a delegate.
   *
   *  - parameter delegate:  The delegate to be removed.
   */
  public func removeDelegate(_ delegate: T) {
    delegates.remove(delegate as AnyObject)
  }

  /**
   *  Use this method to invoke a closure on each delegate.
   *
   *  Alternatively, you can use the `|>` operator to invoke a given closure on each delegate.
   *
   *  - parameter invocation: The closure to be invoked on each delegate.
   */
  public func invokeDelegates(_ invocation: (T) -> Void) {
    for delegate in delegates.allObjects {
      invocation(delegate as! T)
    }
  }

  /**
   *  Use this method to determine if the multicast delegate contains a given delegate.
   *
   *  - parameter delegate:   The given delegate to check if it's contained
   *
   *  - returns: `true` if the delegate is found or `false` otherwise
   */
  public func containsDelegate(_ delegate: T) -> Bool {
    delegates.contains(delegate as AnyObject)
  }
}

/**
 *  Use this operator to add a delegate.
 *
 *  This is a convenience operator for calling `addDelegate`.
 *
 *  - parameter left:   The multicast delegate
 *  - parameter right:  The delegate to be added
 */
public func += <T>(left: MultiDelegate<T>, right: T) {
  left.addDelegate(right)
}

/**
 *  Use this operator to remove a delegate.
 *
 *  This is a convenience operator for calling `removeDelegate`.
 *
 *  - parameter left:   The multicast delegate
 *  - parameter right:  The delegate to be removed
 */
public func -= <T>(left: MultiDelegate<T>, right: T) {
  left.removeDelegate(right)
}

/**
 *  Use this operator invoke a closure on each delegate.
 *
 *  This is a convenience operator for calling `invokeDelegates`.
 *
 *  - parameter left:   The multicast delegate
 *  - parameter right:  The closure to be invoked on each delegate
 *
 *  - returns: The `MultiDelegate` after all its delegates have been invoked
 */
precedencegroup MulticastPrecedence {
  associativity: left
  higherThan: TernaryPrecedence
}

infix operator |>: MulticastPrecedence
public func |> <T>(left: MultiDelegate<T>, right: (T) -> Void) {
  left.invokeDelegates(right)
}
