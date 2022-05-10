
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation

//距离cell边缘的距离
public let qChat_cell_margin = 16.0
//控件之间的间距
public let qChat_margin = 8.0
//头像宽高
public let qChat_headWH = 32.0
//时间cell的高度（固定）
public let qChat_timeCellH = 21.0

//图片最大宽高
public let qChat_pic_size = CGSize.init(width: 150, height: 200)

//聊天小气泡角的宽度（后期扩展使用，目前默认为 0）
public let qChat_angle_w = 0.0

//单行气泡高度
public let qChat_min_h = 46.0

//内容尾部距离cell边框的间距
public let qChat_content_margin = 48.0

//内容最大宽度
public let qChat_content_maxW = (kScreenWidth - qChat_headWH - qChat_cell_margin - qChat_content_margin - qChat_margin)
