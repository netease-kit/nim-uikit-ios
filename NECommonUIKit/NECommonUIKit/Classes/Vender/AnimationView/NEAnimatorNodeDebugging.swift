
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

extension NEAnimatorNode {
  func printNodeTree() {
    parentNode?.printNodeTree()
    NELottieLogger.shared.info(String(describing: type(of: self)))

    if let group = self as? NEGroupNode {
      NELottieLogger.shared.info("* |Children")
      group.rootNode?.printNodeTree()
      NELottieLogger.shared.info("*")
    } else {
      NELottieLogger.shared.info("|")
    }
  }
}
