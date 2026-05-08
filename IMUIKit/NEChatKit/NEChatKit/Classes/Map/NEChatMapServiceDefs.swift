// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// 搜索地址回调

public typealias NESearchPositionCompletion = @convention(block) ([ChatLocaitonModel], Error?) -> Void

public typealias NEMapviewDidMoveCompletion = () -> Void

public typealias NEPositionSelectCompletion = (ChatLocaitonModel) -> Void
