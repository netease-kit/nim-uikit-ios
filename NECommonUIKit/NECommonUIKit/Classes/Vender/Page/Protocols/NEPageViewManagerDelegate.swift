// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// page view 管理类回调协议
protocol NEPageViewManagerDelegate: AnyObject {
  /// 滚动到前一个
  func scrollForward()
  /// 滚动到后一个
  func scrollReverse()
  /// page content 开始布局
  /// - Parameter viewControllers: 布局的控制器数组
  /// - Parameter keepContentOffset: 是否保持内容偏移
  func layoutViews(for viewControllers: [UIViewController], keepContentOffset: Bool)
  /// 添加控制器
  /// - Parameter viewController: 控制器
  func addViewController(_ viewController: UIViewController)
  /// 移除控制器
  /// - Parameter viewController: 控制器
  func removeViewController(_ viewController: UIViewController)
  /// 开始显示回调
  /// - Parameter isAppearing: 是否出现
  /// - Parameter viewController: 控制器
  /// - Parameter animated: 是否动画
  func beginAppearanceTransition(isAppearing: Bool,
                                 viewController: UIViewController,
                                 animated: Bool)
  /// 结束显示回调
  /// - Parameter viewController: 控制器
  func endAppearanceTransition(viewController: UIViewController)
  /// 将要滚动切换控制器回调
  /// - Parameter selectedViewController: 选中的控制器
  /// - Parameter destinationViewController: 目标控制器
  func willScroll(from selectedViewController: UIViewController,
                  to destinationViewController: UIViewController)
  /// 正在滚动切换控制器回调
  /// - Parameter selectedViewController: 选中的控制器
  /// - Parameter destinationViewController: 目标控制器
  /// - Parameter progress: 滚动进度
  func isScrolling(from selectedViewController: UIViewController,
                   to destinationViewController: UIViewController?,
                   progress: CGFloat)
  /// 滚动切换控制器结束回调
  /// - Parameter selectedViewController: 选中的控制器
  /// - Parameter destinationViewController: 目标控制器
  /// - Parameter transitionSuccessful: 是否成功
  func didFinishScrolling(from selectedViewController: UIViewController,
                          to destinationViewController: UIViewController,
                          transitionSuccessful: Bool)
}
