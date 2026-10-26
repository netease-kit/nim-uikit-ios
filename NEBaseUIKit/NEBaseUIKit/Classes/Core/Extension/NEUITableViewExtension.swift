//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import ObjectiveC
import UIKit

private var tableContentInsetsKey: UInt8 = 0
private var tableContentAdjustmentBehaviorKey: UInt8 = 0
private var tableOriginalContentInsetKey: UInt8 = 0
private var tableOriginalIndicatorInsetKey: UInt8 = 0
private var tableOriginalAutomaticIndicatorInsetKey: UInt8 = 0
private var tableOriginalLayoutMarginsKey: UInt8 = 0
private var tableOriginalReadableMarginsKey: UInt8 = 0
private var scrollManagedByContainerKey: UInt8 = 0
private var scrollOriginalIndicatorInsetKey: UInt8 = 0
private var scrollOriginalAdjustmentBehaviorKey: UInt8 = 0
private var scrollOriginalAutomaticIndicatorInsetKey: UInt8 = 0

/// The adaptive shell owns the horizontal safe-area budget. Keep the original
/// indicator geometry so leaving the shell restores the host's behaviour.
public extension UIScrollView {
  func ne_setScrollIndicatorsManagedByContainer(_ managed: Bool) {
    if managed {
      if objc_getAssociatedObject(self, &scrollManagedByContainerKey) == nil {
        objc_setAssociatedObject(self, &scrollManagedByContainerKey, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &scrollOriginalIndicatorInsetKey,
                                 NSValue(uiEdgeInsets: verticalScrollIndicatorInsets),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &scrollOriginalAdjustmentBehaviorKey,
                                 NSNumber(value: contentInsetAdjustmentBehavior.rawValue),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if #available(iOS 13.0, *) {
          objc_setAssociatedObject(self, &scrollOriginalAutomaticIndicatorInsetKey,
                                   NSNumber(value: automaticallyAdjustsScrollIndicatorInsets),
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
      }
      contentInsetAdjustmentBehavior = .never
      if #available(iOS 13.0, *) {
        // The shell already owns the horizontal safe-area budget. UIKit's
        // automatic indicator adjustment would add the host window's trailing
        // safe area back after the shell assigns the final content-column frame.
        automaticallyAdjustsScrollIndicatorInsets = false
      }
      var inset = verticalScrollIndicatorInsets
      inset.right = 0
      verticalScrollIndicatorInsets = inset
    } else if objc_getAssociatedObject(self, &scrollManagedByContainerKey) != nil {
      if let original = objc_getAssociatedObject(self, &scrollOriginalIndicatorInsetKey) as? NSValue {
        verticalScrollIndicatorInsets = original.uiEdgeInsetsValue
      }
      if let original = objc_getAssociatedObject(self, &scrollOriginalAdjustmentBehaviorKey) as? NSNumber,
         let behavior = UIScrollView.ContentInsetAdjustmentBehavior(rawValue: original.intValue) {
        contentInsetAdjustmentBehavior = behavior
      }
      if #available(iOS 13.0, *),
         let original = objc_getAssociatedObject(self, &scrollOriginalAutomaticIndicatorInsetKey) as? NSNumber {
        automaticallyAdjustsScrollIndicatorInsets = original.boolValue
      }
      objc_setAssociatedObject(self, &scrollManagedByContainerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &scrollOriginalIndicatorInsetKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &scrollOriginalAdjustmentBehaviorKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &scrollOriginalAutomaticIndicatorInsetKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

public extension UITableView {
  /// A containing shell may already own the horizontal safe-area budget.
  func ne_setContentInsetsManagedByContainer(_ managed: Bool) {
    if managed {
      if objc_getAssociatedObject(self, &tableContentInsetsKey) == nil {
        objc_setAssociatedObject(self, &tableContentInsetsKey, NSNumber(value: insetsContentViewsToSafeArea), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
      if objc_getAssociatedObject(self, &tableContentAdjustmentBehaviorKey) == nil {
        objc_setAssociatedObject(self, &tableContentAdjustmentBehaviorKey,
                                 NSNumber(value: contentInsetAdjustmentBehavior.rawValue),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &tableOriginalContentInsetKey,
                                 NSValue(uiEdgeInsets: contentInset), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &tableOriginalIndicatorInsetKey,
                                 NSValue(uiEdgeInsets: verticalScrollIndicatorInsets), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if #available(iOS 13.0, *) {
          objc_setAssociatedObject(self, &tableOriginalAutomaticIndicatorInsetKey,
                                   NSNumber(value: automaticallyAdjustsScrollIndicatorInsets),
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        objc_setAssociatedObject(self, &tableOriginalLayoutMarginsKey,
                                 NSValue(uiEdgeInsets: layoutMargins),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &tableOriginalReadableMarginsKey,
                                 NSNumber(value: cellLayoutMarginsFollowReadableWidth),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
      insetsContentViewsToSafeArea = false
      contentInsetAdjustmentBehavior = .never
      // A paired column is already bounded by the adaptive shell. Leaving
      // UIKit's readable-width margins enabled makes swipe actions stop short
      // of the column's trailing edge and exposes a blank strip behind them.
      layoutMargins = .zero
      cellLayoutMarginsFollowReadableWidth = false
      if #available(iOS 13.0, *) {
        // UITableView uses the same UIKit indicator adjustment as other scroll
        // views; disable it while the adaptive shell owns the column geometry.
        automaticallyAdjustsScrollIndicatorInsets = false
      }
      if let original = objc_getAssociatedObject(self, &tableOriginalContentInsetKey) as? NSValue {
        var inset = original.uiEdgeInsetsValue
        inset.bottom += safeAreaInsets.bottom
        contentInset = inset
      }
      if let original = objc_getAssociatedObject(self, &tableOriginalIndicatorInsetKey) as? NSValue {
        var inset = original.uiEdgeInsetsValue
        inset.bottom += safeAreaInsets.bottom
        inset.right = 0
        verticalScrollIndicatorInsets = inset
      }
    } else if let original = objc_getAssociatedObject(self, &tableContentInsetsKey) as? NSNumber {
      insetsContentViewsToSafeArea = original.boolValue
      objc_setAssociatedObject(self, &tableContentInsetsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      if let originalAdjustment = objc_getAssociatedObject(self, &tableContentAdjustmentBehaviorKey) as? NSNumber,
         let behavior = UIScrollView.ContentInsetAdjustmentBehavior(rawValue: originalAdjustment.intValue) {
        contentInsetAdjustmentBehavior = behavior
      }
      objc_setAssociatedObject(self, &tableContentAdjustmentBehaviorKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      if let original = objc_getAssociatedObject(self, &tableOriginalContentInsetKey) as? NSValue {
        contentInset = original.uiEdgeInsetsValue
      }
      if let original = objc_getAssociatedObject(self, &tableOriginalIndicatorInsetKey) as? NSValue {
        verticalScrollIndicatorInsets = original.uiEdgeInsetsValue
      }
      if let original = objc_getAssociatedObject(self, &tableOriginalLayoutMarginsKey) as? NSValue {
        layoutMargins = original.uiEdgeInsetsValue
      }
      if let original = objc_getAssociatedObject(self, &tableOriginalReadableMarginsKey) as? NSNumber {
        cellLayoutMarginsFollowReadableWidth = original.boolValue
      }
      if #available(iOS 13.0, *),
         let original = objc_getAssociatedObject(self, &tableOriginalAutomaticIndicatorInsetKey) as? NSNumber {
        automaticallyAdjustsScrollIndicatorInsets = original.boolValue
      }
      objc_setAssociatedObject(self, &tableOriginalContentInsetKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &tableOriginalIndicatorInsetKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &tableOriginalAutomaticIndicatorInsetKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &tableOriginalLayoutMarginsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &tableOriginalReadableMarginsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// 重新加载单元格
  /// - Parameters:
  ///   - indexs: 位置
  ///   - animation: 动画效果
  func reloadData(_ indexs: [IndexPath],
                  _ animation: UITableView.RowAnimation = .none,
                  _ completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates {
      self.reloadRows(at: indexs, with: animation)
    } completion: { succ in
      completion?(succ)
    }
  }

  /// 删除单元格
  /// - Parameters:
  ///   - indexs: 位置
  ///   - animation: 动画效果
  func deleteData(_ indexs: [IndexPath],
                  _ animation: UITableView.RowAnimation = .none,
                  _ completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates {
      self.deleteRows(at: indexs, with: animation)
    } completion: { succ in
      completion?(succ)
    }
  }

  /// 添加单元格
  /// - Parameters:
  ///   - indexs: 位置
  ///   - animation: 动画效果
  func insertData(_ indexs: [IndexPath],
                  _ animation: UITableView.RowAnimation = .none,
                  _ completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates {
      self.insertRows(at: indexs, with: animation)
    } completion: { succ in
      completion?(succ)
    }
  }
}

private var selectionAppearanceKey: UInt8 = 0

private final class NEListSelectionAppearance {
  let originalStyle: UITableViewCell.SelectionStyle
  let originalBackground: UIView?
  let background = UIView()
  var contentBackground: UIColor?
  init(cell: UITableViewCell) {
    originalStyle = cell.selectionStyle
    originalBackground = cell.selectedBackgroundView
    contentBackground = cell.contentView.backgroundColor
  }
}

public extension UITableViewCell {
  /// Cells still inherit the host window's trailing safe-area margin even when
  /// the table opts out of safe-area content insets. On foldables that region
  /// belongs to the side rail, and UIKit lays swipe actions out against the
  /// cell margins, so the buttons stop short of the column edge and leave a
  /// blank strip behind them. These lists position their content explicitly,
  /// so the inherited margins can be dropped.
  func ne_setLayoutMarginsManagedByContainer() {
    insetsLayoutMarginsFromSafeArea = false
    preservesSuperviewLayoutMargins = false
    layoutMargins = .zero
    contentView.insetsLayoutMarginsFromSafeArea = false
    contentView.preservesSuperviewLayoutMargins = false
    contentView.layoutMargins = .zero
  }

  /// Reapply after selection/highlight or a page updates its ordinary row background.
  func ne_refreshSelectionBackground() {
    guard let appearance = objc_getAssociatedObject(self, &selectionAppearanceKey) as? NEListSelectionAppearance else { return }
    if contentView.backgroundColor != .clear {
      appearance.contentBackground = contentView.backgroundColor
    }
    contentView.backgroundColor = isSelected || isHighlighted ? .clear : appearance.contentBackground
  }

  /// Opt-in list selection appearance; nil restores the page's original style.
  func ne_setSelectionBackgroundColor(_ color: UIColor?) {
    let previous = objc_getAssociatedObject(self, &selectionAppearanceKey) as? NEListSelectionAppearance
    guard let color else {
      if let previous {
        if selectedBackgroundView === previous.background {
          selectedBackgroundView = previous.originalBackground
          selectionStyle = previous.originalStyle
          contentView.backgroundColor = previous.contentBackground
        }
        objc_setAssociatedObject(self, &selectionAppearanceKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
      return
    }
    let appearance = previous ?? NEListSelectionAppearance(cell: self)
    appearance.background.backgroundColor = color
    selectedBackgroundView = appearance.background
    selectionStyle = .default
    objc_setAssociatedObject(self, &selectionAppearanceKey, appearance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    ne_refreshSelectionBackground()
  }
}
