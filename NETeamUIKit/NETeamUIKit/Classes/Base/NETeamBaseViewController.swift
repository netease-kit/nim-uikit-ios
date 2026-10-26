
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

/// UI 模块 ViewController 基类
@objcMembers
open class NETeamBaseViewController: NEBaseViewController {
  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: "",
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view
  }()

}
