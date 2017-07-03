//
//  NTESTeamMeetingCollectionViewCell.h
//  NIM
//
//  Created by chris on 2017/5/2.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESTeamMeetingCollectionViewCell : UICollectionViewCell

@property (nonatomic,strong) NIMTeam *team;

- (void)refrehWithConnecting:(NSString *)user;

- (void)refreshWithDefaultAvatar:(NSString *)user;

- (void)refreshWithTimeout:(NSString *)user;

- (void)refreshWithUserJoin:(NSString *)user;

- (void)refreshWithUserLeft:(NSString *)user;

- (void)refreshWidthYUV:(NSData *)yuvData
                  width:(NSUInteger)width
                 height:(NSUInteger)height;

- (void)refreshWidthCameraPreview:(UIView *)preview;

- (void)refreshWidthVolume:(UInt16)volume;

@end



@interface NTESTeamMeetingCollectionSeparatorView : UIView

@end
