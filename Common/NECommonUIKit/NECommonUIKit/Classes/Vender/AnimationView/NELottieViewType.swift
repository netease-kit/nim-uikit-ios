// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit

  /// The control base type for this platform.
  ///  - `UIControl` on iOS / tvOS and `NSControl` on macOS.
  public typealias NELottieControlType = UIControl

  /// The `State` type of `NELottieControlType`
  ///  - `UIControl.State` on iOS / tvOS and `NSControl.StateValue` on macOS.
  public typealias NELottieControlState = UIControl.State

  /// The event type handled by the `NELottieControlType` component for this platform.
  ///  - `UIControl.Event` on iOS / tvOS and `NELottieNSControlEvent` on macOS.
  public typealias NELottieControlEvent = UIControl.Event

  extension NELottieControlEvent {
    var id: AnyHashable {
      rawValue
    }
  }
#else
  import AppKit

  /// The control base type for this platform.
  ///  - `UIControl` on iOS / tvOS and `NSControl` on macOS.
  public typealias NELottieControlType = NSControl

  /// The `State` type of `NELottieControlType`
  ///  - `UIControl.State` on iOS / tvOS and `NSControl.StateValue` on macOS.
  public typealias NELottieControlState = NELottieNSControlState

  /// AppKit equivalent of `UIControl.State` for `NEAnimatedControl`
  public enum NELottieNSControlState: UInt, RawRepresentable {
    /// The normal, or default, state of a control where the control is enabled but neither selected nor highlighted.
    case normal
    /// The highlighted state of a control.
    case highlighted
  }

  /// The event type handled by the `NELottieControlType` component for this platform.
  ///  - `UIControl.Event` on iOS / tvOS and `NELottieNSControlEvent` on macOS.
  public typealias NELottieControlEvent = NELottieNSControlEvent

  public struct NELottieNSControlEvent: Equatable {
    // MARK: Lifecycle

    public init(_ event: NSEvent.EventType, inside: Bool) {
      self.event = event
      self.inside = inside
    }

    // MARK: Public

    /// macOS equivalent to `UIControl.Event.touchDown`
    public static let touchDown = NELottieNSControlEvent(.leftMouseDown, inside: true)

    /// macOS equivalent to `UIControl.Event.touchUpInside`
    public static let touchUpInside = NELottieNSControlEvent(.leftMouseUp, inside: true)

    /// macOS equivalent to `UIControl.Event.touchUpInside`
    public static let touchUpOutside = NELottieNSControlEvent(.leftMouseUp, inside: false)

    /// The underlying `NSEvent.EventType` of this event, which is roughly equivalent to `UIControl.Event`
    public var event: NSEvent.EventType

    /// Whether or not the mouse must be inside the control.
    public var inside: Bool

    // MARK: Internal

    var id: AnyHashable {
      [AnyHashable(event.rawValue), AnyHashable(inside)]
    }
  }
#endif
