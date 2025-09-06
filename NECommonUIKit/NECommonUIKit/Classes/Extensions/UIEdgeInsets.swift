// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

extension UIEdgeInsets {
  var horizontal: CGFloat {
    left + right
  }

  var vertical: CGFloat {
    top + bottom
  }
}
