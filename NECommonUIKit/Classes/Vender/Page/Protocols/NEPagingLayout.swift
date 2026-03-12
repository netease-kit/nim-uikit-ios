// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

protocol NEPagingLayout {
  init()
}

func createLayout<T>(layout: T.Type) -> T where T: NEPagingLayout {
  layout.init()
}
