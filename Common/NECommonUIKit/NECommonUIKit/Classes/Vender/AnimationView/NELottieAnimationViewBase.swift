// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit

  /// The base view for `NELottieAnimationView` on iOS, tvOS, watchOS, and macCatalyst.
  ///
  /// Enables the `NELottieAnimationView` implementation to be shared across platforms.
  open class NELottieAnimationViewBase: UIView {
    // MARK: Public

    override public var contentMode: UIView.ContentMode {
      didSet {
        setNeedsLayout()
      }
    }

    override public func didMoveToWindow() {
      super.didMoveToWindow()
      animationMovedToWindow()
    }

    override public func layoutSubviews() {
      super.layoutSubviews()
      layoutAnimation()
    }

    // MARK: Internal

    var viewLayer: CALayer? {
      layer
    }

    var screenScale: CGFloat {
      #if os(iOS) || os(tvOS)
        if #available(iOS 13.0, tvOS 13.0, *) {
          return max(UITraitCollection.current.displayScale, 1)
        } else {
          return UIScreen.main.scale
        }
      #else // if os(visionOS)
        // We intentionally don't check `#if os(visionOS)`, because that emits
        // a warning when building on Xcode 14 and earlier.
        1.0
      #endif
    }

    func layoutAnimation() {
      // Implemented by subclasses.
    }

    func animationMovedToWindow() {
      // Implemented by subclasses.
    }

    func commonInit() {
      contentMode = .scaleAspectFit
      clipsToBounds = true
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(animationWillEnterForeground),
        name: UIApplication.willEnterForegroundNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(animationWillMoveToBackground),
        name: UIApplication.didEnterBackgroundNotification,
        object: nil
      )
    }

    @objc
    func animationWillMoveToBackground() {
      // Implemented by subclasses.
    }

    @objc
    func animationWillEnterForeground() {
      // Implemented by subclasses.
    }
  }
#endif
