
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/** @abstract   NEToolbar for NEKeyboardManager.    */
@available(iOSApplicationExtension, unavailable)
@objc open class NEToolbar: UIToolbar, UIInputViewAudioFeedback {
  private static var _classInitialize: Void = classInitialize()

  private class func classInitialize() {
    let appearanceProxy = appearance()

    appearanceProxy.barTintColor = nil

    let positions: [UIBarPosition] = [.any, .bottom, .top, .topAttached]

    for position in positions {
      appearanceProxy.setBackgroundImage(
        nil,
        forToolbarPosition: position,
        barMetrics: .default
      )
      appearanceProxy.setShadowImage(nil, forToolbarPosition: .any)
    }

    // Background color
    appearanceProxy.backgroundColor = nil
  }

  /**
   Previous bar button of toolbar.
   */
  private var privatePreviousBarButton: NEBarButtonItem?
  @objc open var previousBarButton: NEBarButtonItem {
    get {
      if privatePreviousBarButton == nil {
        privatePreviousBarButton = NEBarButtonItem(
          image: nil,
          style: .plain,
          target: nil,
          action: nil
        )
      }
      return privatePreviousBarButton!
    }

    set(newValue) {
      privatePreviousBarButton = newValue
    }
  }

  /**
   Next bar button of toolbar.
   */
  private var privateNextBarButton: NEBarButtonItem?
  @objc open var nextBarButton: NEBarButtonItem {
    get {
      if privateNextBarButton == nil {
        privateNextBarButton = NEBarButtonItem(
          image: nil,
          style: .plain,
          target: nil,
          action: nil
        )
      }
      return privateNextBarButton!
    }

    set(newValue) {
      privateNextBarButton = newValue
    }
  }

  /**
   Title bar button of toolbar.
   */
  private var privateTitleBarButton: NETitleBarButtonItem?
  @objc open var titleBarButton: NETitleBarButtonItem {
    get {
      if privateTitleBarButton == nil {
        privateTitleBarButton = NETitleBarButtonItem(title: nil)
        privateTitleBarButton?.accessibilityLabel = "Title"
        privateTitleBarButton?.accessibilityIdentifier = privateTitleBarButton?
          .accessibilityLabel
      }
      return privateTitleBarButton!
    }

    set(newValue) {
      privateTitleBarButton = newValue
    }
  }

  /**
   Done bar button of toolbar.
   */
  private var privateDoneBarButton: NEBarButtonItem?
  @objc open var doneBarButton: NEBarButtonItem {
    get {
      if privateDoneBarButton == nil {
        privateDoneBarButton = NEBarButtonItem(
          title: nil,
          style: .done,
          target: nil,
          action: nil
        )
      }
      return privateDoneBarButton!
    }

    set(newValue) {
      privateDoneBarButton = newValue
    }
  }

  /**
   Fixed space bar button of toolbar.
   */
  private var privateFixedSpaceBarButton: NEBarButtonItem?
  @objc open var fixedSpaceBarButton: NEBarButtonItem {
    get {
      if privateFixedSpaceBarButton == nil {
        privateFixedSpaceBarButton = NEBarButtonItem(
          barButtonSystemItem: .fixedSpace,
          target: nil,
          action: nil
        )
      }
      privateFixedSpaceBarButton!.isSystemItem = true

      if #available(iOS 10, *) {
        privateFixedSpaceBarButton!.width = 6
      } else {
        privateFixedSpaceBarButton!.width = 20
      }

      return privateFixedSpaceBarButton!
    }

    set(newValue) {
      privateFixedSpaceBarButton = newValue
    }
  }

  override init(frame: CGRect) {
    _ = NEToolbar._classInitialize
    super.init(frame: frame)

    sizeToFit()

    autoresizingMask = .flexibleWidth
    isTranslucent = true
  }

  @objc public required init?(coder aDecoder: NSCoder) {
    _ = NEToolbar._classInitialize
    super.init(coder: aDecoder)

    sizeToFit()

    autoresizingMask = .flexibleWidth
    isTranslucent = true
  }

  @objc override open func sizeThatFits(_ size: CGSize) -> CGSize {
    var sizeThatFit = super.sizeThatFits(size)
    sizeThatFit.height = 44
    return sizeThatFit
  }

  @objc override open var tintColor: UIColor! {
    didSet {
      if let unwrappedItems = items {
        for item in unwrappedItems {
          item.tintColor = tintColor
        }
      }
    }
  }

  @objc override open func layoutSubviews() {
    super.layoutSubviews()

    if #available(iOS 11, *) {
      return
    } else if let customTitleView = titleBarButton.customView {
      var leftRect = CGRect.null
      var rightRect = CGRect.null
      var isTitleBarButtonFound = false

      let sortedSubviews = subviews.sorted(by: { (view1: UIView, view2: UIView) -> Bool in
        if view1.frame.minX != view2.frame.minX {
          return view1.frame.minX < view2.frame.minX
        } else {
          return view1.frame.minY < view2.frame.minY
        }
      })

      for barButtonItemView in sortedSubviews {
        if isTitleBarButtonFound {
          rightRect = barButtonItemView.frame
          break
        } else if barButtonItemView === customTitleView {
          isTitleBarButtonFound = true
          // If it's UIToolbarButton or UIToolbarTextButton (which actually UIBarButtonItem)
        } else if barButtonItemView.isKind(of: UIControl.self) {
          leftRect = barButtonItemView.frame
        }
      }

      let titleMargin: CGFloat = 16

      let maxWidth: CGFloat = frame
        .width - titleMargin * 2 - (leftRect.isNull ? 0 : leftRect.maxX) -
        (rightRect.isNull ? 0 : frame.width - rightRect.minX)
      let maxHeight = frame.height

      let sizeThatFits = customTitleView
        .sizeThatFits(CGSize(width: maxWidth, height: maxHeight))

      var titleRect: CGRect

      if sizeThatFits.width > 0, sizeThatFits.height > 0 {
        let width = min(sizeThatFits.width, maxWidth)
        let height = min(sizeThatFits.height, maxHeight)

        var xPosition: CGFloat

        if !leftRect.isNull {
          xPosition = titleMargin + leftRect.maxX + ((maxWidth - width) / 2)
        } else {
          xPosition = titleMargin
        }

        let yPosition = (maxHeight - height) / 2

        titleRect = CGRect(x: xPosition, y: yPosition, width: width, height: height)
      } else {
        var xPosition: CGFloat

        if !leftRect.isNull {
          xPosition = titleMargin + leftRect.maxX
        } else {
          xPosition = titleMargin
        }

        let width: CGFloat = frame
          .width - titleMargin * 2 - (leftRect.isNull ? 0 : leftRect.maxX) -
          (rightRect.isNull ? 0 : frame.width - rightRect.minX)

        titleRect = CGRect(x: xPosition, y: 0, width: width, height: maxHeight)
      }

      customTitleView.frame = titleRect
    }
  }

  @objc open var enableInputClicksWhenVisible: Bool {
    true
  }

  deinit {
    items = nil
    privatePreviousBarButton = nil
    privateNextBarButton = nil
    privateTitleBarButton = nil
    privateDoneBarButton = nil
    privateFixedSpaceBarButton = nil
  }
}
