
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
@objc open class NEBarButtonItem: UIBarButtonItem {
  private static var _classInitialize: Void = classInitialize()

  @objc override public init() {
    _ = NEBarButtonItem._classInitialize
    super.init()
  }

  @objc public required init?(coder aDecoder: NSCoder) {
    _ = NEBarButtonItem._classInitialize
    super.init(coder: aDecoder)
  }

  private class func classInitialize() {
    let appearanceProxy = appearance()

    let states: [UIControl.State]

    states = [.normal, .highlighted, .disabled, .selected, .application, .reserved]

    for state in states {
      appearanceProxy.setBackgroundImage(nil, for: state, barMetrics: .default)
      appearanceProxy.setBackgroundImage(nil, for: state, style: .done, barMetrics: .default)
      appearanceProxy.setBackgroundImage(nil, for: state, style: .plain, barMetrics: .default)
      appearanceProxy.setBackButtonBackgroundImage(nil, for: state, barMetrics: .default)
    }

    appearanceProxy.setTitlePositionAdjustment(UIOffset(), for: .default)
    appearanceProxy.setBackgroundVerticalPositionAdjustment(0, for: .default)
    appearanceProxy.setBackButtonBackgroundVerticalPositionAdjustment(0, for: .default)
  }

  @objc override open var tintColor: UIColor? {
    didSet {
      var textAttributes = [NSAttributedString.Key: Any]()
      textAttributes[.foregroundColor] = tintColor

      if let attributes = titleTextAttributes(for: .normal) {
        for (key, value) in attributes {
          textAttributes[key] = value
        }
      }

      setTitleTextAttributes(textAttributes, for: .normal)
    }
  }

  /**
   Boolean to know if it's a system item or custom item, we are having a limitation that we cannot override a designated initializer, so we are manually setting this property once in initialization
   */
  @objc var isSystemItem = false

  /**
   Additional target & action to do get callback action. Note that setting custom target & selector doesn't affect native functionality, this is just an additional target to get a callback.

   @param target Target object.
   @param action Target Selector.
   */
  @objc open func setTarget(_ target: AnyObject?, action: Selector?) {
    if let target = target, let action = action {
      invocation = NEInvocation(target, action)
    } else {
      invocation = nil
    }
  }

  /**
   Customized Invocation to be called when button is pressed. invocation is internally created using setTarget:action: method.
   */
  @objc open var invocation: NEInvocation?

  deinit {
    target = nil
    invocation = nil
  }
}
