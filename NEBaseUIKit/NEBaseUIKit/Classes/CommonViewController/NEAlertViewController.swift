// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

/// 弹窗窗口的根控制器：只负责让窗口跟随 scene 尺寸。
///
/// 与登录窗口同因：scene 附加窗口在真机上不会被系统自动改尺寸（模拟器会强制吸附），
/// 折叠/展开期间弹出的 alert 会停在旧尺寸。这里在 trait/appear/layout 三处兜底同步。
private final class NEAlertWindowRootViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    syncWindowFrameToScene()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    syncWindowFrameToScene()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // 折叠/展开会改变 size class；即使窗口没有重新布局也能收到这个回调。
    syncWindowFrameToScene()
  }

  private func syncWindowFrameToScene() {
    guard let window = view.window, let scene = window.windowScene else { return }
    let target = scene.coordinateSpace.bounds
    guard target.width > 0.5, target.height > 0.5 else { return }
    let current = window.frame
    guard abs(current.width - target.width) > 0.5 || abs(current.height - target.height) > 0.5 else {
      return
    }
    window.frame = target
  }
}

@objcMembers
public class NEAlertViewController {
  static var alterWindow: UIWindow?
  /// 弹窗出现前的宿主窗口；收起时恢复它，而不是取应用级 keyWindow（多 scene 下可能属于其他场景）。
  private static weak var presentingWindow: UIWindow?

  public class func presentAlertViewController(_ title: String?, messageContent: String?, cancelTitle: String?, confirmTitle: String?, cancelComplete: (() -> Void)? = nil, confirmComplete: (() -> Void)? = nil) {
    let alertVC = UIAlertController(title: title, message: messageContent, preferredStyle: .alert)
    if let cancelTitle = cancelTitle {
      let cancelActon = UIAlertAction(title: cancelTitle, style: .cancel) { action in
        alterWindow?.resignKey()
        alterWindow = nil
        restoreHostWindow()
        if let cancelComplete = cancelComplete {
          cancelComplete()
        }
      }
      alertVC.addAction(cancelActon)
    }

    if let confirmTitle = confirmTitle {
      let confirmActon = UIAlertAction(title: confirmTitle, style: .default) { action in
        alterWindow?.resignKey()
        alterWindow = nil
        restoreHostWindow()
        if let confirmComplete = confirmComplete {
          confirmComplete()
        }
      }
      alertVC.addAction(confirmActon)
    }
    DispatchQueue.main.async {
      let hostWindow = UIWindow.ne_activeKeyWindow
      presentingWindow = hostWindow
      if let scene = hostWindow?.windowScene {
        alterWindow = UIWindow(windowScene: scene)
        alterWindow?.frame = scene.coordinateSpace.bounds
      } else {
        alterWindow = UIWindow(frame: UIScreen.main.bounds)
      }
      alterWindow?.rootViewController = NEAlertWindowRootViewController()
      alterWindow?.windowLevel = .normal
      alterWindow?.makeKeyAndVisible()
      alterWindow?.rootViewController?.present(alertVC, animated: true)
    }
  }

  public class func removePresentAlertViewController() {
    alterWindow?.resignKey()
    alterWindow = nil
    restoreHostWindow()
  }

  private class func restoreHostWindow() {
    if let presentingWindow = presentingWindow {
      presentingWindow.makeKeyAndVisible()
    } else {
      UIWindow.ne_activeKeyWindow?.makeKeyAndVisible()
    }
    presentingWindow = nil
  }
}
