// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import UIKit

@objcMembers
open class NEAISearchManager: NSObject, XKitService, IMKitPluginService {
  public static let shared = NEAISearchManager()
  public var serviceName: String = NEAISearchPlugin
  public var versionName: String = "1.0.0"
  public var appKey: String = IMKitClient.instance.appKey()

  override private init() {
    super.init()
  }

  /// 插件初始化
  public func setupInit() {
    XKit.instance().register(self)
    IMKitPluginManager.shared.registerPlugin(serviceName, self)
    ChatKitClient.shared.buryDataPoints("AISearchKit")
  }

  // MARK: - IMKitPluginService

  /// 注册插件模型
  /// - Parameter text: 文本内容
  /// - Returns: 插件模型
  public func registerPlugin(_ text: String) -> OperationItem? {
    let item = OperationItem()
    item.text = localizable("operation_ai_word_search")
    item.image = UIImage.ne_imageNamed(name: "op_ai_word")
    item.type = .plugin
    item.onClick = { viewController in
      // 校验网络
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        viewController?.showToast(commonLocalizable("network_error"))
        return
      }

      // 不支持空文本
      if text.isEmpty {
        viewController?.showToast(localizable("not_supported"))
        return
      }

      let aisearchViewController = NEAIWordSearchViewController(text)
      if let viewController {
        // 展开双栏：聊天 view 本身只有右列宽度时，直接作为子视图嵌入，
        // 不经过 presentation，避免 pageSheet/空白区域与列宽不一致。
        if NEAdaptiveDeviceGate.isAdaptiveHostActive,
           let hostView = viewController.viewIfLoaded,
           let window = hostView.window,
           (hostView.bounds.width < window.bounds.width - 20
             || (hostView.bounds.width >= window.bounds.width - 1
               && window.safeAreaInsets.right > 0)) {
          self.presentInColumn(aisearchViewController, host: viewController)
        } else if NEAdaptiveDeviceGate.isAdaptiveHostActive,
                  let window = viewController.viewIfLoaded?.window,
                  window.bounds.width >= 700,
                  let navigation = viewController.navigationController {
          aisearchViewController.modalPresentationStyle = .overCurrentContext
          navigation.definesPresentationContext = true
          navigation.present(aisearchViewController, animated: true)
        } else {
          viewController.showBottomSheetInDetailColumn(aisearchViewController, animated: true)
        }
      } else if let root = UIWindow.ne_activeKeyWindow?.rootViewController {
        root.present(aisearchViewController, animated: true)
      }
    }
    return item
  }

  /// 展开双栏：把 AI 弹窗作为聊天列的子视图，遮罩与卡片都只覆盖右列。
  private func presentInColumn(_ controller: NEAIWordSearchViewController,
                               host: UIViewController) {
    let hostView = host.view!
    let windowWidth = hostView.window?.bounds.width ?? hostView.bounds.width
    let isFullWindow = hostView.bounds.width >= windowWidth - 1
    let railInset = isFullWindow ? max(0, hostView.window?.safeAreaInsets.right ?? 0) : 0
    let columnWidth = max(0, hostView.bounds.width - railInset)

    let dim = UIControl(frame: CGRect(x: 0, y: 0, width: columnWidth, height: hostView.bounds.height))
    dim.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    dim.autoresizingMask = [.flexibleHeight]
    dim.accessibilityIdentifier = "ai.word.search.column.dim"

    controller.isEmbeddedInColumn = true
    controller.columnDimView = dim
    controller.view.accessibilityIdentifier = "ai.word.search.column.v4"
    controller.view.autoresizingMask = [.flexibleTopMargin]
    // 列内嵌入时关闭入口由侧栏返回承担（`NEAdaptiveOverlayDidPresent` 注册了 dismiss），
    // 页面自己的「取消」不再展示，避免同一屏出现两个关闭入口；「补充信息 / 确认」
    // 仍保留在页面内。非折叠的原生 sheet 不经过此分支，「取消」保持不变。
    controller.cancelButton.isHidden = true

    host.addChild(controller)
    hostView.addSubview(dim)
    hostView.addSubview(controller.view)
    controller.didMove(toParent: host)

    let height = min(406, hostView.bounds.height)
    controller.view.frame = CGRect(x: 0, y: hostView.bounds.height - height,
                                   width: columnWidth, height: height)
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()

    let dismiss = { [weak controller, weak dim] in
      controller?.columnDismissHandler = nil
      controller?.willMove(toParent: nil)
      controller?.view.removeFromSuperview()
      controller?.removeFromParent()
      dim?.removeFromSuperview()
      NotificationCenter.default.post(name: Notification.Name("NEAdaptiveOverlayDidDismiss"), object: nil)
    }
    controller.columnDismissHandler = dismiss
    dim.addAction(UIAction { _ in dismiss() }, for: .touchUpInside)
    NotificationCenter.default.post(name: Notification.Name("NEAdaptiveOverlayDidPresent"),
                                    object: nil, userInfo: ["dismiss": dismiss])
  }
}
