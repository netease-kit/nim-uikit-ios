// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public enum PopoverOption {
  case arrowSize(CGSize)
  case animationIn(TimeInterval)
  case animationOut(TimeInterval)
  case cornerRadius(CGFloat)
  case sideEdge(CGFloat)
  case blackOverlayColor(UIColor)
  case overlayBlur(UIBlurEffect.Style)
  case type(PopoverType)
  case color(UIColor)
  case dismissOnBlackOverlayTap(Bool)
  case showBlackOverlay(Bool)
  case springDamping(CGFloat)
  case initialSpringVelocity(CGFloat)
  case sideOffset(CGFloat)
  case borderColor(UIColor)
}

@objc public enum PopoverType: Int {
  case up
  case down
  case left
  case right
  case auto
}

@objcMembers
open class Popover: UIView {
  // custom property
  open var arrowSize: CGSize = .init(width: 16.0, height: 10.0)
  open var animationIn: TimeInterval = 0.6
  open var animationOut: TimeInterval = 0.3
  open var cornerRadius: CGFloat = 6.0
  open var sideEdge: CGFloat = 20.0
  open var popoverType: PopoverType = .down
  open var blackOverlayColor: UIColor = .init(white: 0.0, alpha: 0.2)
  open var overlayBlur: UIBlurEffect?
  open var popoverColor: UIColor = .white
  open var dismissOnBlackOverlayTap: Bool = true
  open var showBlackOverlay: Bool = true
  open var highlightFromView: Bool = false
  open var highlightCornerRadius: CGFloat = 0
  open var springDamping: CGFloat = 0.7
  open var initialSpringVelocity: CGFloat = 3
  open var sideOffset: CGFloat = 6.0
  open var borderColor: UIColor?

  // custom closure
  open var willShowHandler: (() -> Void)?
  open var willDismissHandler: (() -> Void)?
  open var didShowHandler: (() -> Void)?
  open var didDismissHandler: (() -> Void)?

  public fileprivate(set) var blackOverlay: UIControl = .init()

  fileprivate weak var containerView: UIView?
  fileprivate var contentView: UIView!
  fileprivate var contentViewFrame: CGRect!
  fileprivate var arrowShowPoint: CGPoint!

  public init() {
    super.init(frame: .zero)
    backgroundColor = .clear
    accessibilityViewIsModal = true
  }

  public init(showHandler: (() -> Void)?, dismissHandler: (() -> Void)?) {
    super.init(frame: .zero)
    backgroundColor = .clear
    didShowHandler = showHandler
    didDismissHandler = dismissHandler
    accessibilityViewIsModal = true
  }

  public init(options: [PopoverOption]?, showHandler: (() -> Void)? = nil, dismissHandler: (() -> Void)? = nil) {
    super.init(frame: .zero)
    backgroundColor = .clear
    setOptions(options)
    didShowHandler = showHandler
    didDismissHandler = dismissHandler
    accessibilityViewIsModal = true
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    contentView.frame = bounds
  }

  open func showAsDialog(_ contentView: UIView) {
    guard let rootView = UIApplication.shared.keyWindow else {
      return
    }
    showAsDialog(contentView, inView: rootView)
  }

  open func showAsDialog(_ contentView: UIView, inView: UIView) {
    arrowSize = .zero
    let point = CGPoint(x: inView.center.x,
                        y: inView.center.y - contentView.frame.height / 2)
    show(contentView, point: point, inView: inView)
  }

  open func show(_ contentView: UIView, fromView: UIView) {
    guard let rootView = UIApplication.shared.keyWindow else {
      return
    }
    show(contentView, fromView: fromView, inView: rootView)
  }

  open func show(_ contentView: UIView, fromView: UIView, inView: UIView) {
    let point: CGPoint

    // TODO: add left/right auto
    if popoverType == .auto {
      if let point = fromView.superview?.convert(fromView.frame.origin, to: nil),
         point.y + fromView.frame.height + self.arrowSize.height + contentView.frame.height > inView.frame.height {
        popoverType = .up
      } else {
        popoverType = .down
      }
    }

    switch popoverType {
    case .up:
      point = inView.convert(
        CGPoint(
          x: fromView.frame.origin.x + (fromView.frame.size.width / 2),
          y: fromView.frame.origin.y
        ), from: fromView.superview
      )
    case .down, .auto:
      point = inView.convert(
        CGPoint(
          x: fromView.frame.origin.x + (fromView.frame.size.width / 2),
          y: fromView.frame.origin.y + fromView.frame.size.height
        ), from: fromView.superview
      )
    case .left:
      point = inView.convert(
        CGPoint(x: fromView.frame.origin.x - sideOffset,
                y: fromView.frame.origin.y + 0.5 * fromView.frame.height), from: fromView.superview
      )
    case .right:
      point = inView.convert(
        CGPoint(x: fromView.frame.origin.x + fromView.frame.size.width + sideOffset,
                y: fromView.frame.origin.y + 0.5 * fromView.frame.height), from: fromView.superview
      )
    }

    if highlightFromView {
      createHighlightLayer(fromView: fromView, inView: inView)
    }

    show(contentView, point: point, inView: inView)
  }

  open func show(_ contentView: UIView, point: CGPoint) {
    guard let rootView = UIApplication.shared.keyWindow else {
      return
    }
    show(contentView, point: point, inView: rootView)
  }

  open func show(_ contentView: UIView, point: CGPoint, inView: UIView) {
    if dismissOnBlackOverlayTap || showBlackOverlay {
      blackOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blackOverlay.frame = inView.bounds
      inView.addSubview(blackOverlay)

      if showBlackOverlay {
        if let overlayBlur = overlayBlur {
          let effectView = UIVisualEffectView(effect: overlayBlur)
          effectView.frame = blackOverlay.bounds
          effectView.isUserInteractionEnabled = false
          blackOverlay.addSubview(effectView)
        } else {
          if !highlightFromView {
            blackOverlay.backgroundColor = blackOverlayColor
          }
          blackOverlay.alpha = 0
        }
      }

      if dismissOnBlackOverlayTap {
        blackOverlay.addTarget(self, action: #selector(Popover.dismiss), for: .touchUpInside)
      }
    }

    containerView = inView
    self.contentView = contentView
    self.contentView.backgroundColor = UIColor.clear
    self.contentView.layer.cornerRadius = cornerRadius
    self.contentView.layer.masksToBounds = true
    arrowShowPoint = point
    show()
  }

  override open func accessibilityPerformEscape() -> Bool {
    dismiss()
    return true
  }

  open func dismiss() {
    if superview != nil {
      willDismissHandler?()
      UIView.animate(withDuration: animationOut, delay: 0,
                     options: UIView.AnimationOptions(),
                     animations: {
                       self.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
                       self.blackOverlay.alpha = 0
                     }) { _ in
        self.contentView.removeFromSuperview()
        self.blackOverlay.removeFromSuperview()
        self.removeFromSuperview()
        self.transform = CGAffineTransform.identity
        self.didDismissHandler?()
      }
    }
  }

  override open func draw(_ rect: CGRect) {
    super.draw(rect)
    guard let containerView = containerView else {
      return
    }
    let arrow = UIBezierPath()
    let color = popoverColor
    let arrowPoint = containerView.convert(arrowShowPoint, to: self)
    switch popoverType {
    case .up:
      arrow.move(to: CGPoint(x: arrowPoint.x, y: bounds.height))
      arrow.addLine(
        to: CGPoint(
          x: arrowPoint.x - arrowSize.width * 0.5,
          y: isCornerLeftArrow ? arrowSize.height : bounds.height - arrowSize.height
        )
      )

      arrow.addLine(to: CGPoint(x: cornerRadius, y: bounds.height - arrowSize.height))
      arrow.addArc(
        withCenter: CGPoint(
          x: cornerRadius,
          y: bounds.height - arrowSize.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(90),
        endAngle: radians(180),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: 0, y: cornerRadius))
      arrow.addArc(
        withCenter: CGPoint(
          x: cornerRadius,
          y: cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(180),
        endAngle: radians(270),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: 0))
      arrow.addArc(
        withCenter: CGPoint(
          x: bounds.width - cornerRadius,
          y: cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(270),
        endAngle: radians(0),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: bounds.width, y: bounds.height - arrowSize.height - cornerRadius))
      arrow.addArc(
        withCenter: CGPoint(
          x: bounds.width - cornerRadius,
          y: bounds.height - arrowSize.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(0),
        endAngle: radians(90),
        clockwise: true
      )

      arrow.addLine(
        to: CGPoint(
          x: arrowPoint.x + arrowSize.width * 0.5,
          y: isCornerRightArrow ? arrowSize.height : bounds.height - arrowSize.height
        )
      )

    case .down, .auto:
      arrow.move(to: CGPoint(x: arrowPoint.x, y: 0))

      if isCloseToCornerRightArrow, !isCornerRightArrow {
        if !isBehindCornerRightArrow {
          arrow.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: arrowSize.height))
          arrow.addArc(
            withCenter: CGPoint(x: bounds.width - cornerRadius, y: arrowSize.height + cornerRadius),
            radius: cornerRadius,
            startAngle: radians(270.0),
            endAngle: radians(0),
            clockwise: true
          )
        } else {
          arrow.addLine(to: CGPoint(x: bounds.width, y: arrowSize.height + cornerRadius))
          arrow.addLine(to: CGPoint(x: bounds.width, y: arrowSize.height))
        }
      } else {
        arrow.addLine(
          to: CGPoint(
            x: isBehindCornerLeftArrow ? frame.minX - arrowSize.width * 0.5 : arrowPoint.x + arrowSize.width * 0.5,
            y: isCornerRightArrow ? arrowSize.height + bounds.height : arrowSize.height
          )
        )
        arrow.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: arrowSize.height))
        arrow.addArc(
          withCenter: CGPoint(
            x: bounds.width - cornerRadius,
            y: arrowSize.height + cornerRadius
          ),
          radius: cornerRadius,
          startAngle: radians(270.0),
          endAngle: radians(0),
          clockwise: true
        )
      }

      arrow.addLine(to: CGPoint(x: bounds.width, y: bounds.height - cornerRadius))
      arrow.addArc(
        withCenter: CGPoint(
          x: bounds.width - cornerRadius,
          y: bounds.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(0),
        endAngle: radians(90),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: 0, y: bounds.height))
      arrow.addArc(
        withCenter: CGPoint(
          x: cornerRadius,
          y: bounds.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(90),
        endAngle: radians(180),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: 0, y: arrowSize.height + cornerRadius))

      if !isBehindCornerLeftArrow {
        arrow.addArc(
          withCenter: CGPoint(
            x: cornerRadius,
            y: arrowSize.height + cornerRadius
          ),
          radius: cornerRadius,
          startAngle: radians(180),
          endAngle: radians(270),
          clockwise: true
        )
      }

      if isBehindCornerRightArrow {
        arrow.addLine(to: CGPoint(
          x: bounds.width - arrowSize.width * 0.5,
          y: isCornerLeftArrow ? arrowSize.height + bounds.height : arrowSize.height
        ))
      } else if isCloseToCornerLeftArrow, !isCornerLeftArrow {
        () // skipping this line in that case
      } else {
        arrow.addLine(to: CGPoint(x: arrowPoint.x - arrowSize.width * 0.5,
                                  y: isCornerLeftArrow ? arrowSize.height + bounds.height : arrowSize.height))
      }

    case .left:
      arrow.move(to: CGPoint(x: bounds.width, y: bounds.height * 0.5))
      arrow.addLine(
        to: CGPoint(
          x: bounds.width - arrowSize.height,
          y: bounds.height * 0.5 + arrowSize.width * 0.5
        ))

      arrow.addLine(to: CGPoint(x: bounds.width - arrowSize.height, y: bounds.height - cornerRadius))
      arrow.addArc(
        withCenter: CGPoint(
          x: bounds.width - arrowSize.height - cornerRadius,
          y: bounds.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(0.0),
        endAngle: radians(90),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: cornerRadius, y: bounds.height))
      arrow.addArc(
        withCenter: CGPoint(
          x: cornerRadius,
          y: bounds.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(90),
        endAngle: radians(180),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: 0, y: cornerRadius))
      arrow.addArc(
        withCenter: CGPoint(
          x: cornerRadius,
          y: cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(180),
        endAngle: radians(270),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: bounds.width - arrowSize.height - cornerRadius, y: 0))
      arrow.addArc(
        withCenter: CGPoint(x: bounds.width - arrowSize.height - cornerRadius,
                            y: cornerRadius),
        radius: cornerRadius,
        startAngle: radians(270),
        endAngle: radians(0),
        clockwise: true
      )

      arrow.addLine(to: CGPoint(x: bounds.width - arrowSize.height,
                                y: bounds.height * 0.5 - arrowSize.width * 0.5))

    case .right:
      arrow.move(to: CGPoint(x: arrowPoint.x, y: bounds.height * 0.5))
      arrow.addLine(
        to: CGPoint(
          x: arrowPoint.x + arrowSize.height,
          y: bounds.height * 0.5 + 0.5 * arrowSize.width
        ))

      arrow.addLine(
        to: CGPoint(
          x: arrowPoint.x + arrowSize.height,
          y: bounds.height - cornerRadius
        ))
      arrow.addArc(
        withCenter: CGPoint(
          x: arrowPoint.x + arrowSize.height + cornerRadius,
          y: bounds.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(180.0),
        endAngle: radians(90),
        clockwise: false
      )

      arrow.addLine(to: CGPoint(x: bounds.width + arrowPoint.x - cornerRadius, y: bounds.height))
      arrow.addArc(
        withCenter: CGPoint(
          x: bounds.width + arrowPoint.x - cornerRadius,
          y: bounds.height - cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(90),
        endAngle: radians(0),
        clockwise: false
      )

      arrow.addLine(to: CGPoint(x: bounds.width + arrowPoint.x, y: cornerRadius))
      arrow.addArc(
        withCenter: CGPoint(
          x: bounds.width + arrowPoint.x - cornerRadius,
          y: cornerRadius
        ),
        radius: cornerRadius,
        startAngle: radians(0),
        endAngle: radians(-90),
        clockwise: false
      )

      arrow.addLine(to: CGPoint(x: arrowPoint.x + arrowSize.height - cornerRadius, y: 0))
      arrow.addArc(
        withCenter: CGPoint(x: arrowPoint.x + arrowSize.height + cornerRadius,
                            y: cornerRadius),
        radius: cornerRadius,
        startAngle: radians(-90),
        endAngle: radians(-180),
        clockwise: false
      )

      arrow.addLine(to: CGPoint(x: arrowPoint.x + arrowSize.height,
                                y: bounds.height * 0.5 - arrowSize.width * 0.5))
    }

    color.setFill()
    arrow.fill()
    if let borderColor = borderColor {
      borderColor.setStroke()
      arrow.stroke()
    }
  }
}

private extension Popover {
  func setOptions(_ options: [PopoverOption]?) {
    if let options = options {
      for option in options {
        switch option {
        case let .arrowSize(value):
          arrowSize = value
        case let .animationIn(value):
          animationIn = value
        case let .animationOut(value):
          animationOut = value
        case let .cornerRadius(value):
          cornerRadius = value
        case let .sideEdge(value):
          sideEdge = value
        case let .blackOverlayColor(value):
          blackOverlayColor = value
        case let .overlayBlur(style):
          overlayBlur = UIBlurEffect(style: style)
        case let .type(value):
          popoverType = value
        case let .color(value):
          popoverColor = value
        case let .dismissOnBlackOverlayTap(value):
          dismissOnBlackOverlayTap = value
        case let .showBlackOverlay(value):
          showBlackOverlay = value
        case let .springDamping(value):
          springDamping = value
        case let .initialSpringVelocity(value):
          initialSpringVelocity = value
        case let .sideOffset(value):
          sideOffset = value
        case let .borderColor(value):
          borderColor = value
        }
      }
    }
  }

  func create() {
    guard let containerView = containerView else {
      return
    }

    var frame = contentView.frame

    switch popoverType {
    case .up, .down, .auto:
      frame.origin.x = arrowShowPoint.x - frame.size.width * 0.5
    case .left, .right:
      frame.origin.y = arrowShowPoint.y - frame.size.height * 0.5
    }

    var sideEdge: CGFloat = 0.0
    if frame.size.width < containerView.frame.size.width {
      sideEdge = self.sideEdge
    }

    let outerSideEdge = frame.maxX - containerView.bounds.size.width
    if outerSideEdge > 0 {
      frame.origin.x -= (outerSideEdge + sideEdge)
    } else {
      if frame.minX < 0 {
        frame.origin.x += abs(frame.minX) + sideEdge
      }
    }
    self.frame = frame

    let arrowPoint = containerView.convert(arrowShowPoint, to: self)
    var anchorPoint: CGPoint
    switch popoverType {
    case .up:
      frame.origin.y = arrowShowPoint.y - frame.height - arrowSize.height
      anchorPoint = CGPoint(x: arrowPoint.x / frame.size.width, y: 1)
    case .down, .auto:
      frame.origin.y = arrowShowPoint.y
      anchorPoint = CGPoint(x: arrowPoint.x / frame.size.width, y: 0)
    case .left:
      frame.origin.x = arrowShowPoint.x - frame.size.width - arrowSize.height
      anchorPoint = CGPoint(x: 1, y: 0.5)
    case .right:
      frame.origin.x = arrowShowPoint.x
      anchorPoint = CGPoint(x: 0, y: 0.5)
    }

    if arrowSize == .zero {
      anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    let lastAnchor = layer.anchorPoint
    layer.anchorPoint = anchorPoint
    let x = layer.position.x + (anchorPoint.x - lastAnchor.x) * layer.bounds.size.width
    let y = layer.position.y + (anchorPoint.y - lastAnchor.y) * layer.bounds.size.height
    layer.position = CGPoint(x: x, y: y)

    switch popoverType {
    case .up, .down, .auto:
      frame.size.height += arrowSize.height
    case .left, .right:
      frame.size.width += arrowSize.height
    }

    self.frame = frame
  }

  func createHighlightLayer(fromView: UIView, inView: UIView) {
    let path = UIBezierPath(rect: inView.bounds)
    let highlightRect = inView.convert(fromView.frame, from: fromView.superview)
    let highlightPath = UIBezierPath(roundedRect: highlightRect, cornerRadius: highlightCornerRadius)
    path.append(highlightPath)
    path.usesEvenOddFillRule = true

    let fillLayer = CAShapeLayer()
    fillLayer.path = path.cgPath
    fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
    fillLayer.fillColor = blackOverlayColor.cgColor
    blackOverlay.layer.addSublayer(fillLayer)
  }

  func show() {
    guard let containerView = containerView else {
      return
    }
    setNeedsDisplay()
    switch popoverType {
    case .up:
      contentView.frame.origin.y = 0.0
    case .down, .auto:
      contentView.frame.origin.y = arrowSize.height
    case .left, .right:
      contentView.frame.origin.x = 0
    }
    addSubview(contentView)
    containerView.addSubview(self)

    create()
    transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    willShowHandler?()
    UIView.animate(
      withDuration: animationIn,
      delay: 0,
      usingSpringWithDamping: springDamping,
      initialSpringVelocity: initialSpringVelocity,
      options: UIView.AnimationOptions(),
      animations: {
        self.transform = CGAffineTransform.identity
      }
    ) { _ in
      self.didShowHandler?()
    }
    UIView.animate(
      withDuration: animationIn / 3,
      delay: 0,
      options: .curveLinear,
      animations: {
        self.blackOverlay.alpha = 1
      }, completion: nil
    )
  }

  var isCloseToCornerLeftArrow: Bool {
    arrowShowPoint.x < frame.origin.x + arrowSize.width / 2 + cornerRadius
  }

  var isCloseToCornerRightArrow: Bool {
    arrowShowPoint.x > (frame.origin.x + bounds.width) - arrowSize.width / 2 - cornerRadius
  }

  var isCornerLeftArrow: Bool {
    arrowShowPoint.x == frame.origin.x
  }

  var isCornerRightArrow: Bool {
    arrowShowPoint.x == frame.origin.x + bounds.width
  }

  var isBehindCornerLeftArrow: Bool {
    arrowShowPoint.x < frame.origin.x
  }

  var isBehindCornerRightArrow: Bool {
    arrowShowPoint.x > frame.origin.x + bounds.width
  }

  func radians(_ degrees: CGFloat) -> CGFloat {
    CGFloat.pi * degrees / 180
  }
}
