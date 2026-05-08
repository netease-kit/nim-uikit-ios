
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Photos
import UIKit

/// 聊天页面单次选择图片的最大数量
public let chatImageCountLimit: Int = 9

/// 聊天页面单次选择视频的最大数量
public let chatVideoCountLimit: Int = 1

/// 头像单次选择图片的最大数量
public let avatarImageCountLimit: Int = 1

@objc
public enum NEMediaType: Int {
  case image = 1
  case video
  // image + video
  case all
}

@objcMembers
public class NEResultModel: NSObject {
  public let asset: PHAsset

  public let image: UIImage

  /// The order in which the user selects the models in the album. This index is not necessarily equal to the order of the model's index in the array, as some PHAssets requests may fail.
  public let index: Int

  public init(asset: PHAsset, image: UIImage, index: Int) {
    self.asset = asset
    self.image = image
    self.index = index
    super.init()
  }
}

public extension NEResultModel {
  override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? NEResultModel else {
      return false
    }

    return asset == object.asset
  }
}
