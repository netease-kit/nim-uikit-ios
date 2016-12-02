//
//  NTESSearchCellLayoutConstant.h
//  NIM
//
//  Created by chris on 15/7/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#ifndef NIM_NTESSearchCellLayoutConstant_h
#define NIM_NTESSearchCellLayoutConstant_h

//font
extern CGFloat SearchCellTitleFontSize;
extern CGFloat SearchCellContentFontSize;
extern CGFloat SearchCellTimeFontSize;

//layout
extern CGFloat SearchCellAvatarLeft;
extern CGFloat SearchCellAvatarAndTitleSpacing;
extern CGFloat SearchCellTitleTop;
extern CGFloat SearchCellContentTop;
extern CGFloat SearchCellContentBottom;
extern CGFloat SearchCellContentMaxWidth;
extern CGFloat SearchCellContentMinHeight; //cell的高度是由文本高度决定的。防止没有文本的情况，导致cell的高度过小。
extern CGFloat SearchCellTimeRight;
extern CGFloat SearchCellTimeTop;

#endif
