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
