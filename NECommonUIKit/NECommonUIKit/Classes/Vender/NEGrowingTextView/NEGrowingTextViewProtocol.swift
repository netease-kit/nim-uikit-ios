// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc public protocol NEGrowingTextViewDelegate: NSObjectProtocol {
  /// 变高输入框是否开始编辑回调
  /// - Parameter growingTextView: 输入框
  /// - Returns: 是否开始编辑
  @objc optional func growingTextViewShouldBeginEditing(_ growingTextView: NEGrowingTextView) -> Bool
  /// 变高输入框是否结束编辑回调
  /// - Parameter growingTextView: 输入框
  /// - Returns: 是否结束编辑
  @objc optional func growingTextViewShouldEndEditing(_ growingTextView: NEGrowingTextView) -> Bool
  /// 变高输入框开始编辑回调
  /// - Parameter growingTextView: 输入框
  @objc optional func growingTextViewDidBeginEditing(_ growingTextView: NEGrowingTextView)
  /// 变高输入框结束编辑回调
  /// - Parameter growingTextView: 输入框
  @objc optional func growingTextViewDidEndEditing(_ growingTextView: NEGrowingTextView)
  /// 变高输入框文字变化回调
  /// - Parameter growingTextView: 输入框
  /// - Parameter range: 范围
  /// - Parameter text: 文字
  /// - Returns: 是否变化
  @objc optional func growingTextView(_ growingTextView: NEGrowingTextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
  /// 变高输入框文字变化回调
  /// - Parameter growingTextView: 输入框
  @objc optional func growingTextViewDidChange(_ growingTextView: NEGrowingTextView)
  /// 变高输入框文字变化回调
  /// - Parameter growingTextView: 输入框
  @objc optional func growingTextViewDidChangeSelection(_ growingTextView: NEGrowingTextView)
  /// 变高输入框高度将要变化回调
  /// - Parameter growingTextView: 输入框
  /// - Parameter height: 高度
  /// - Parameter difference: 变化值
  @objc optional func growingTextView(_ growingTextView: NEGrowingTextView, willChangeHeight height: CGFloat, difference: CGFloat)
  /// 变高输入框高度变化回调
  /// - Parameter growingTextView: 输入框
  /// - Parameter height: 高度
  /// - Parameter difference: 变化值
  @objc optional func growingTextView(_ growingTextView: NEGrowingTextView, didChangeHeight height: CGFloat, difference: CGFloat)

  /// 变高输入框点击return回调
  /// - Parameter growingTextView: 输入框
  /// - Returns: 是否执行return
  @objc optional func growingTextViewShouldReturn(_ growingTextView: NEGrowingTextView) -> Bool
}

enum DelegateSelectors {
  static let shouldBeginEditing = #selector(NEGrowingTextViewDelegate.growingTextViewShouldBeginEditing(_:))
  static let shouldEndEditing = #selector(NEGrowingTextViewDelegate.growingTextViewShouldEndEditing(_:))
  static let didBeginEditing = #selector(NEGrowingTextViewDelegate.growingTextViewDidBeginEditing(_:))
  static let didEndEditing = #selector(NEGrowingTextViewDelegate.growingTextViewDidEndEditing(_:))
  static let shouldChangeText = #selector(NEGrowingTextViewDelegate.growingTextView(_:shouldChangeTextInRange:replacementText:))
  static let didChange = #selector(NEGrowingTextViewDelegate.growingTextViewDidChange(_:))
  static let didChangeSelection = #selector(NEGrowingTextViewDelegate.growingTextViewDidChangeSelection(_:))
  static let willChangeHeight = #selector(NEGrowingTextViewDelegate.growingTextView(_:willChangeHeight:difference:))
  static let didChangeHeight = #selector(NEGrowingTextViewDelegate.growingTextView(_:didChangeHeight:difference:))
  static let shouldReturn = #selector(NEGrowingTextViewDelegate.growingTextViewShouldReturn(_:))
}
