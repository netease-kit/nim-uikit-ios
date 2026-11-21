/// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
public class CommonUIConfig: NSObject {
  public static let shared = CommonUIConfig()

  override private init() {
    super.init()
  }

  /// 导航栏返回按钮图片
  public var backArrowImage: UIImage? = coreLoader.loadImage("back_arrow")
}

/// 第三方图片选择器桥。
///
/// `NEContactUIKit`、`NETeamUIKit` 等 UI 模块不依赖消息 UI，但都需要“从相册选一张图”
/// （机器人头像、群头像等）。由宿主注入具体实现（Demo 在 `CustomConfig` 接入 ZLPhotoBrowser），
/// 页面只消费闭包；未注入时沿用系统 `UIImagePickerController` 兜底。
public enum NEPhotoPickerBridge {
  /// - Parameters:
  ///   - presenter: 发起选择的页面
  ///   - limit: 最多可选数量
  ///   - completion: 选择完成回调；取消或失败时回传 nil
  public static var pickImage: ((_ presenter: UIViewController,
                                 _ limit: Int,
                                 _ completion: @escaping (UIImage?) -> Void) -> Void)?
}
