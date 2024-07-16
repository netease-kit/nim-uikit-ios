//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class AIUserViewModel: NSObject {
  /// AI 列表数据源
  var datas = [NEAIUserModel]()

  /// 搜索结果
  var searchDatas = [NEAIUserModel]()

  /// 获取数字人
  public func getAIUsers(_ completion: @escaping (NSError?) -> Void) {
    AIRepo.shared.getAIUserList { [weak self] users, error in
      users?.forEach { aiUser in
        let model = NEAIUserModel()
        model.aiUser = aiUser
        self?.datas.append(model)
      }
      completion(error)
    }
  }
}
