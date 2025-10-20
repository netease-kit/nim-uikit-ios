
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension ConversationRouter {
  static func registerFun() {
    registerCommon()

    Router.shared.register(SearchContactPageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let searchCtrl = FunConversationSearchController()
      nav?.pushViewController(searchCtrl, animated: animated)
    }

    Router.shared.register(ConversationPageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let conversation = FunConversationController()
      nav?.pushViewController(conversation, animated: animated)
    }
  }
}
