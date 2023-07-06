
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// 距离cell边缘的距离
public let chat_cell_margin = 16.0
// 控件之间的间距
public let chat_content_margin = 8.0
// 头像宽高
public let chat_headWH = 32.0
// 时间cell的高度（固定）
public let chat_timeCellH = 21.0

// 图片最大宽高
public let chat_pic_size = CGSize(width: 150, height: 200)

// 文件宽高
public let chat_file_size = CGSize(width: 254, height: 56)

// 单行气泡高度
public let chat_min_h = 40.0

// 回复消息replyLabel高度
public let chat_reply_height = 16.0

// 气泡最大宽度
public let chat_content_maxW = (kScreenWidth - 136)

// 文本内容最大宽度
public let chat_text_maxW = chat_content_maxW - 2 * chat_content_margin

// pin消息需要增加的高度
public let chat_pin_height = 16.0

// 群聊起泡上方用户名label高度，p2p无此展示，高度为0
public let chat_full_name_height = 16.0
