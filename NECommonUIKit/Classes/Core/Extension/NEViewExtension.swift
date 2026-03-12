
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension UIView {
  // MARK: - 常用位置属性

  var left: CGFloat {
    get {
      frame.origin.x
    }
    set(newLeft) {
      var frame = frame
      frame.origin.x = newLeft
      self.frame = frame
    }
  }

  var top: CGFloat {
    get {
      frame.origin.y
    }

    set(newTop) {
      var frame = frame
      frame.origin.y = newTop
      self.frame = frame
    }
  }

  var width: CGFloat {
    get {
      frame.size.width
    }

    set(newWidth) {
      var frame = frame
      frame.size.width = newWidth
      self.frame = frame
    }
  }

  var height: CGFloat {
    get {
      frame.size.height
    }

    set(newHeight) {
      var frame = frame
      frame.size.height = newHeight
      self.frame = frame
    }
  }

  var right: CGFloat {
    left + width
  }

  var bottom: CGFloat {
    top + height
  }

  var centerX: CGFloat {
    get {
      center.x
    }

    set(newCenterX) {
      var center = center
      center.x = newCenterX
      self.center = center
    }
  }

  var centerY: CGFloat {
    get {
      center.y
    }

    set(newCenterY) {
      var center = center
      center.y = newCenterY
      self.center = center
    }
  }

  // 圆角
  func addCorner(conrners: UIRectCorner, radius: CGFloat) {
    let maskPath = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: conrners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    let maskLayer = CAShapeLayer()
    maskLayer.fillColor = UIColor.red.cgColor
    maskLayer.frame = bounds
    maskLayer.path = maskPath.cgPath
    layer.mask = maskLayer
  }
}

public extension UIView {
  /// 查询约束
  /// - Parameters:
  ///   - firstItem: 子视图
  ///   - seconedItem: 父视图
  ///   - attribute: 约束条件
  /// - Returns: 约束对象
  func getLayoutConstraint(firstItem: UIView, seconedItem: UIView?, attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
    for cons in constraints {
      if let secItem = cons.secondItem as? UIView {
        if secItem == seconedItem,
           let firItem = cons.firstItem as? UIView,
           firItem == firstItem,
           cons.firstAttribute == attribute {
          return cons
        }
      } else {
        if let firItem = cons.firstItem as? UIView,
           firItem == firstItem,
           cons.firstAttribute == attribute {
          return cons
        }
      }
    }
    return nil
  }

  /// 更新约束
  /// - Parameters:
  ///   - firstItem: 子视图
  ///   - seconedItem: 父视图
  ///   - attribute: 约束条件
  ///   - constant: 约束值
  func updateLayoutConstraint(firstItem: UIView, secondItem: UIView?, attribute: NSLayoutConstraint.Attribute, constant: CGFloat) {
    let cons = getLayoutConstraint(firstItem: firstItem, seconedItem: secondItem, attribute: attribute)
    cons?.constant = constant
  }

  /// 移除约束
  /// - Parameters:
  ///   - firstItem: 子视图
  ///   - seconedItem: 父视图
  ///   - attribute: 约束条件
  func removeLayoutConstraint(firstItem: UIView, seconedItem: UIView?, attribute: NSLayoutConstraint.Attribute) {
    if let cons = getLayoutConstraint(firstItem: firstItem, seconedItem: seconedItem, attribute: attribute),
       constraints.contains(cons) {
      removeConstraint(cons)
    }
  }
}

public extension UIView {
  /// 根据文案查找子视图中的 UILabel
  /// - Parameter string: 文案
  /// - Returns: 该文案对应的 UILabel
  func findLabel(with string: String?) -> UILabel? {
    guard let text = string else {
      return nil
    }
    for subview in subviews {
      if let label = subview as? UILabel, label.text == text {
        return label
      } else if let foundLabel = subview.findLabel(with: text) {
        return foundLabel
      }
    }
    return nil
  }
}
