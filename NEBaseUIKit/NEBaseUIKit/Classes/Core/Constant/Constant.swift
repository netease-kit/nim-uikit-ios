
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Darwin
import Foundation
import NEChatKit

public let coreLoader = CommonLoader<TabNavigationView>()
public func commonLocalizable(_ key: String) -> String {
  coreLoader.localizable(key)
}
// let CommonScreenWidth: CGFloat = UIScreen.main.bounds.size.width
// let CommonScreenHeight: CGFloat = UIScreen.main.bounds.size.height

public let useSystemNav = "useSystemNav"

public enum NEAdaptiveDeviceGate {
  /// 机型判定：只作为几何无法确认时的补充信号（Duo 的机型标识符）。
  /// Simulator 名称可被修改，因此只接受机型标识符这一个模拟器信号。
  public static func isFoldable(identifier: String, simulatorModelIdentifier: String?, isSimulator: Bool) -> Bool {
    if isSimulator { return simulatorModelIdentifier == "iPhone19,4" }
    return identifier == "iPhone19,4"
  }

  /// 单个遮挡区是否代表 Duo 的「侧边控件区」。
  ///
  /// Duo 右侧状态区是贴着尾部边缘的竖向窄条（实测 84x124）；
  /// 普通 iPhone 的刘海、灵动岛、状态栏都是横向遮挡条，不能作为折叠屏证据，
  /// 否则非折叠屏会被误判并套用双栏/侧栏布局。
  public static func isSideControlArea(frame: CGRect, windowSize: CGSize, isActive: Bool) -> Bool {
    guard isActive, windowSize.width > 1, windowSize.height > 1 else { return false }
    guard frame.width > 0, frame.height > frame.width else { return false }
    // 侧边状态区是窄条；接近窗口宽度一半的遮挡区一定不是侧边控件。
    guard frame.width <= windowSize.width * 0.3 else { return false }
    return frame.minX <= 1 || frame.maxX >= windowSize.width - 1
  }

  /// 只按窗口几何判断是否存在折叠屏侧边控件区（不依赖机型，便于单测）。
  ///
  /// 两个条件同时成立才算：
  /// 1. 横向安全区只在单侧存在（Duo 右侧 84pt）；
  /// 2. 存在贴边竖向遮挡区。
  /// 普通 iPhone 竖屏两侧安全区均为 0；横屏两侧对称（刘海机型 44/44），都不会命中。
  public static func isFoldableGeometry(safeAreaInsets: UIEdgeInsets,
                                        windowSize: CGSize,
                                        activeOcclusions: [CGRect]) -> Bool {
    let hasSingleSidedInset = (safeAreaInsets.left > 0) != (safeAreaInsets.right > 0)
    guard hasSingleSidedInset else { return false }
    return activeOcclusions.contains {
      isSideControlArea(frame: $0, windowSize: windowSize, isActive: true)
    }
  }

  /// 官方「针对 iPhone Duo 设计」要求：不要依赖具体机型，而应先按场景几何适配。
  ///
  /// 判定顺序固定为「场景几何优先、机型兜底」：
  /// 1. 场景几何能确认「侧边控件区」时直接采用；
  /// 2. 几何无法确认时才退回机型（Duo 折叠为单屏时没有侧边状态区，
  ///    不能因此把已适配的 Duo 降级回普通 tab 布局）。
  /// 任何一步都不会在只有刘海/灵动岛的普通 iPhone 上返回 true。
  public static var isFoldableDevice: Bool {
    if foldableBySceneGeometry { return true }
    return foldableByModel
  }

  /// 场景几何判定（官方推荐路径）：侧边安全区 + 系统占位区。
  public static var foldableBySceneGeometry: Bool {
    guard #available(iOS 27.1, *), let window = activeWindow else { return false }
    let activeOcclusions = window.reservedRegions(kind: .occlusion)
      .filter(\.isActive)
      .map(\.frame)
    return isFoldableGeometry(safeAreaInsets: window.safeAreaInsets,
                              windowSize: window.bounds.size,
                              activeOcclusions: activeOcclusions)
  }

  private static var activeWindow: UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.flatMap(\.windows).first(where: { $0.isKeyWindow }) ?? scenes.flatMap(\.windows).first
  }

  /// 机型不会变化，只解析一次；避免每次布局都执行 `uname`。
  private static let foldableByModel: Bool = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let identifier = withUnsafeBytes(of: &systemInfo.machine) { bytes in
      String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
    #if targetEnvironment(simulator)
      let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
      return isFoldable(identifier: identifier,
                        simulatorModelIdentifier: simulatorModelIdentifier,
                        isSimulator: true)
    #else
      return isFoldable(identifier: identifier, simulatorModelIdentifier: nil, isSimulator: false)
    #endif
  }()
}

/// 自适应分栏的列几何判定：只依赖窗口坐标与安全区，不依赖机型或具体容器。
enum NEAdaptiveColumnGeometry {
  /// 内容视图是否位于双栏展开态的右侧详情栏。
  /// 单栏内容（含折叠外屏）与窗口左侧安全区对齐，不会被误判为右列。
  static func isDetailColumn(frameInWindow: CGRect,
                             windowWidth: CGFloat,
                             safeAreaInsets: UIEdgeInsets) -> Bool {
    guard windowWidth > 1, frameInWindow.width > 0, frameInWindow.height > 0 else { return false }
    return frameInWindow.minX > safeAreaInsets.left + 1
  }
}
