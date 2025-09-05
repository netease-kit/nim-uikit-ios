// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 带导航栏的底部弹出视图
/// 待弹出的视图需要重写preferredContentSize来设置大小
public class NEActionSheetController: UINavigationController {
  /// 点击空白区域是否收回弹出视图，默认 true
  public var dismissOnTouchOutside: Bool = true

  /// 转场动画代理实现
  private var transitioning = NEActionSheetTransitioningDelegate()

  /// 圆角处理
  private var navigationBarMask = CAShapeLayer()

  /// 根据要弹出的视图初始化
  /// - Parameter rootViewController: 待弹出视图
  override public init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
    modalPresentationStyle = .custom
    transitioningDelegate = transitioning
    navigationBar.clipsToBounds = true
    navigationBar.isTranslucent = false
    navigationBar.tintColor = .black

    if #available(iOS 13, *) {
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 16)]
      appearance.backgroundColor = .white
      navigationBar.standardAppearance = appearance
      navigationBar.scrollEdgeAppearance = appearance
    }
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // 绘制圆角
    navigationBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 48)
    navigationBarMask.frame = navigationBar.bounds
    let maskCornor = UIBezierPath(roundedRect: navigationBar.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12))
    navigationBarMask.path = maskCornor.cgPath
    navigationBar.layer.mask = navigationBarMask
  }

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override open func forwardingTarget(for aSelector: Selector!) -> Any? {
    if transitioning.responds(to: aSelector) {
      return transitioning
    }
    return super.forwardingTarget(for: aSelector)
  }
}
