// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/**
 Use `NEPagingKitProxy` proxy as customization point for constrained protocol extensions.
 */

public class NEPagingKitConfig {
  public static var focusColor = UIColor(
    red: 0.9137254902,
    green: 0.3490196078,
    blue: 0.3137254902,
    alpha: 1
  )

  public static var normalColor = UIColor.black

  public static var menuTitleFont = UIFont.systemFont(ofSize: 17.0)
}

public struct NEPagingKitProxy<Base: Any> {
  /// Base object to extend.
  let base: Base

  /// Creates extensions with base object.
  ///
  /// - parameter base: Base object.
  public init(_ base: Base) {
    self.base = base
  }
}

public extension NSObjectProtocol {
  /// NEPagingKitProxy extensions for class.
  static var pk: NEPagingKitProxy<Self.Type> {
    return NEPagingKitProxy(self)
  }

  /// NEPagingKitProxy extensions for instance.
  var pk: NEPagingKitProxy<Self> {
    return NEPagingKitProxy(self)
  }
}

public extension NEPagingKitProxy where Base == UIColor.Type {
  /// color theme to show focusing
  var focusRed: UIColor {
    return UIColor(
      red: 0.9137254902,
      green: 0.3490196078,
      blue: 0.3137254902,
      alpha: 1
    )
  }
}

extension NEPagingKitProxy where Base == UIView.Type {
  /// call this function to catch completion handler of layoutIfNeeded()
  ///
  /// - Parameters:
  ///   - layout: method which has layoutIfNeeded()
  ///   - completion: completion handler of layoutIfNeeded()
  func catchLayoutCompletion(layout: @escaping () -> Void, completion: @escaping (Bool) -> Void) {
    UIView.animate(withDuration: 0, animations: {
      layout()
    }) { finish in
      completion(finish)
    }
  }

  /// perform system like animation
  ///
  /// - Parameters:
  ///   - animations: animation Handler
  ///   - completion: completion Handler
  func performSystemAnimation(_ animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
    UIView.perform(
      .delete,
      on: [],
      options: UIView.AnimationOptions(rawValue: 0),
      animations: animations,
      completion: completion
    )
  }
}
