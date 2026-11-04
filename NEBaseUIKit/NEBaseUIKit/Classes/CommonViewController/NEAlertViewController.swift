// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

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
      alterWindow?.rootViewController = UIViewController()
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
