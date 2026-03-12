
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

// MARK: - NEAnimatedControl

/// Lottie comes prepacked with a two Animated Controls, `NEAnimatedSwitch` and
/// `NEAnimatedButton`. Both of these controls are built on top of `NEAnimatedControl`
///
/// `NEAnimatedControl` is a subclass of `UIControl` that provides an interactive
/// mechanism for controlling the visual state of an animation in response to
/// user actions.
///
/// The `NEAnimatedControl` will show and hide layers depending on the current
/// `UIControl.State` of the control.
///
/// Users of `AnimationControl` can set a Layer Name for each `UIControl.State`.
/// When the state is change the `AnimationControl` will change the visibility
/// of its layers.
///
/// NOTE: Do not initialize directly. This is intended to be subclassed.
@objcMembers
open class NEAnimatedControl: NELottieControlType {
  // MARK: Lifecycle

  // MARK: Initializers

  public init(animation: NELottieAnimation?,
              configuration: NELottieConfiguration = .shared) {
    animationView = NELottieAnimationView(
      animation: animation,
      configuration: configuration
    )

    super.init(frame: animation?.bounds ?? .zero)
    commonInit()
  }

  public init() {
    animationView = NELottieAnimationView()
    super.init(frame: .zero)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    animationView = NELottieAnimationView()
    super.init(coder: aDecoder)
    commonInit()
  }

  // MARK: Open

  // MARK: UIControl Overrides

  override open var isEnabled: Bool {
    didSet {
      updateForState()
    }
  }

  #if canImport(UIKit)
    override open var isSelected: Bool {
      didSet {
        updateForState()
      }
    }
  #endif

  override open var isHighlighted: Bool {
    didSet {
      updateForState()
    }
  }

  override open var intrinsicContentSize: CGSize {
    animationView.intrinsicContentSize
  }

  #if canImport(UIKit)
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      updateForState()
      return super.beginTracking(touch, with: event)
    }

    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      updateForState()
      return super.continueTracking(touch, with: event)
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
      updateForState()
      return super.endTracking(touch, with: event)
    }

    override open func cancelTracking(with event: UIEvent?) {
      updateForState()
      super.cancelTracking(with: event)
    }

  #elseif canImport(AppKit)
    override open func mouseDown(with mouseDownEvent: NSEvent) {
      guard let window else { return }

      currentState = .highlighted
      updateForState()
      handle(NELottieControlEvent(mouseDownEvent.type, inside: eventIsInside(mouseDownEvent)))

      // AppKit mouse-tracking loop from:
      // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingMouseEvents/HandlingMouseEvents.html#//apple_ref/doc/uid/10000060i-CH6-SW4
      var keepOn = true
      while
        keepOn,
        let event = window.nextEvent(
          matching: .any,
          until: .distantFuture,
          inMode: .eventTracking,
          dequeue: true
        ) {
        if event.type == .leftMouseUp {
          keepOn = false
        }

        let isInside = eventIsInside(event)
        handle(NELottieControlEvent(event.type, inside: isInside))

        let expectedState = (isInside && keepOn) ? NELottieNSControlState.highlighted : .normal
        if currentState != expectedState {
          currentState = expectedState
          updateForState()
        }
      }
    }

    func handle(_: NELottieNSControlEvent) {
      // To be overridden in subclasses
    }

    private func eventIsInside(_ event: NSEvent) -> Bool {
      let mouseLocation = convert(event.locationInWindow, from: nil)
      return isMousePoint(mouseLocation, in: bounds)
    }
  #endif

  open func animationDidSet() {}

  // MARK: Public

  /// The animation view in which the animation is rendered.
  public let animationView: NELottieAnimationView

  /// The animation backing the animated control.
  public var animation: NELottieAnimation? {
    didSet {
      animationView.animation = animation
      animationView.bounds = animation?.bounds ?? .zero
      #if canImport(UIKit)
        setNeedsLayout()
      #elseif canImport(AppKit)
        needsLayout = true
      #endif
      updateForState()
      animationDidSet()
    }
  }

  /// The speed of the animation playback. Defaults to 1
  public var animationSpeed: CGFloat {
    set { animationView.animationSpeed = newValue }
    get { animationView.animationSpeed }
  }

  /// Sets which Animation Layer should be visible for the given state.
  public func setLayer(named: String, forState: NELottieControlState) {
    stateMap[forState.rawValue] = named
    updateForState()
  }

  /// Sets a NEValueProvider for the specified keypath
  public func setValueProvider(_ valueProvider: NEAnyValueProvider, keypath: NEAnimationKeypath) {
    animationView.setValueProvider(valueProvider, keypath: keypath)
  }

  // MARK: Internal

  var stateMap: [UInt: String] = [:]

  #if canImport(UIKit)
    var currentState: NELottieControlState {
      state
    }

  #elseif canImport(AppKit)
    var currentState = NELottieControlState.normal
  #endif

  func updateForState() {
    guard let animationLayer = animationView.animationLayer else { return }
    if
      let layerName = stateMap[currentState.rawValue],
      let stateLayer = animationLayer.layer(for: NEAnimationKeypath(keypath: layerName)) {
      for layer in animationLayer._animationLayers {
        layer.isHidden = true
      }
      stateLayer.isHidden = false
    } else {
      for layer in animationLayer._animationLayers {
        layer.isHidden = false
      }
    }
  }

  // MARK: Private

  private func commonInit() {
    #if canImport(UIKit)
      animationView.clipsToBounds = false
      clipsToBounds = true
    #endif

    animationView.translatesAutoresizingMaskIntoConstraints = false
    animationView.backgroundBehavior = .forceFinish
    addSubview(animationView)
    animationView.contentMode = .scaleAspectFit

    #if canImport(UIKit)
      animationView.isUserInteractionEnabled = false
    #endif

    animationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    animationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    animationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    animationView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
}
