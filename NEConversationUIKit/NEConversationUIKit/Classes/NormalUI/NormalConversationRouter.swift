
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension ConversationRouter {
  static func register() {
    registerCommon()

    Router.shared.register(SearchContactPageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let searchCtrl = ConversationSearchController()
      nav?.pushViewController(searchCtrl, animated: true)
    }

    Router.shared.register(ConversationPageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let conversation = ConversationController()
      nav?.pushViewController(conversation, animated: true)
    }
  }
}
