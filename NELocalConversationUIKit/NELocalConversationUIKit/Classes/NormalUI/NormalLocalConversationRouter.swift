
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension LocalConversationRouter {
  static func register() {
    registerCommon()

    Router.shared.register(SearchContactPageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let animated = param["animated"] as? Bool ?? true
      let searchCtrl = LocalConversationSearchController()
      nav?.pushViewController(searchCtrl, animated: animated)
    }

    Router.shared.register(LocalConversationPageRouter) { param in
      let nav = param["nav"] as? UINavigationController
      let conversation = LocalConversationController()
      nav?.pushViewController(conversation, animated: true)
    }
  }
}
