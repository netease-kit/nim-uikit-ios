// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 页面自绘标题栏的统一返回按钮。
///
/// 与 `NENavigationView` 的返回按钮共用同一张皮肤返回图和 32pt 命中高度。
/// 自绘标题栏中的「取消」文本返回入口统一替换为该按钮，原文案只保留为
/// 无障碍标签，避免同一产品里出现两套返回样式。
@objcMembers
public final class NEUnifiedBackButton: UIButton {
  /// 与导航栏返回按钮一致的默认尺寸（宽 × 高）。
  private static let width: CGFloat = 34
  private static let height: CGFloat = 32

  public init(accessibilityLabel: String?) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    setTitle(nil, for: .normal)
    setImage(CommonUIConfig.shared.backArrowImage, for: .normal)
    contentHorizontalAlignment = .left
    self.accessibilityLabel = accessibilityLabel
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: Self.width),
      heightAnchor.constraint(equalToConstant: Self.height),
    ])
  }

  @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
}
