// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

// MARK: - NEAnimatedButton

/// An interactive button that plays an animation when pressed.
@objcMembers
open class NEAnimatedButton: NEAnimatedControl {
  // MARK: Lifecycle

  override public init(animation: NELottieAnimation?,
                       configuration: NELottieConfiguration = .shared) {
    super.init(animation: animation, configuration: configuration)

    #if canImport(UIKit)
      isAccessibilityElement = true
    #elseif canImport(AppKit)
      setAccessibilityElement(true)
    #endif
  }

  override public init() {
    super.init()

    #if canImport(UIKit)
      isAccessibilityElement = true
    #elseif canImport(AppKit)
      setAccessibilityElement(true)
    #endif
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    #if canImport(UIKit)
      isAccessibilityElement = true
    #elseif canImport(AppKit)
      setAccessibilityElement(true)
    #endif
  }

  // MARK: Open

  #if canImport(UIKit)
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      let _ = super.beginTracking(touch, with: event)
      let touchEvent = UIControl.Event.touchDown
      if let playRange = rangesForEvents[touchEvent.id] {
        animationView.play(fromProgress: playRange.from, toProgress: playRange.to, loopMode: .playOnce)
      }
      return true
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
      super.endTracking(touch, with: event)
      let touchEvent: UIControl.Event
      if let touch, bounds.contains(touch.location(in: self)) {
        touchEvent = UIControl.Event.touchUpInside
        performAction?()
      } else {
        touchEvent = UIControl.Event.touchUpOutside
      }

      if let playRange = rangesForEvents[touchEvent.id] {
        animationView.play(fromProgress: playRange.from, toProgress: playRange.to, loopMode: .playOnce)
      }
    }

  #elseif canImport(AppKit)
    override open func handle(_ event: NELottieNSControlEvent) {
      super.handle(event)

      if let playRange = rangesForEvents[event.id] {
        animationView.play(fromProgress: playRange.from, toProgress: playRange.to, loopMode: .playOnce)
      }

      if event == .touchUpInside {
        performAction?()
      }
    }
  #endif

  // MARK: Public

  /// A closure that is called when the button is pressed / clicked
  public var performAction: (() -> Void)?

  #if canImport(UIKit)
    override public var accessibilityTraits: UIAccessibilityTraits {
      set { super.accessibilityTraits = newValue }
      get { super.accessibilityTraits.union(.button) }
    }
  #endif

  /// Sets the play range for the given UIControlEvent.
  public func setPlayRange(fromProgress: NEAnimationProgressTime, toProgress: NEAnimationProgressTime, event: NELottieControlEvent) {
    rangesForEvents[event.id] = (from: fromProgress, to: toProgress)
  }

  /// Sets the play range for the given UIControlEvent.
  public func setPlayRange(fromMarker fromName: String, toMarker toName: String, event: NELottieControlEvent) {
    if
      let start = animationView.progressTime(forMarker: fromName),
      let end = animationView.progressTime(forMarker: toName) {
      rangesForEvents[event.id] = (from: start, to: end)
    }
  }

  // MARK: Private

  private var rangesForEvents: [AnyHashable: (from: CGFloat, to: CGFloat)] = [NELottieControlEvent.touchUpInside.id: (
    from: 0,
    to: 1
  )]
}
