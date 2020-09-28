//
//  TeamAnnouncementListCell.m
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamAnnouncementListCell.h"
#import "NIMUsrInfoData.h"
#import "NIMKitUtil.h"

@interface NIMTeamAnnouncementListCell ()
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *infoLabel;
@property (strong, nonatomic) UIView *line;
@property (strong, nonatomic) UILabel *contentLabel;

@end

@implementation NIMTeamAnnouncementListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 15, 298, 16)];
        _titleLabel.font = [UIFont systemFontOfSize:16.f];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_titleLabel];

        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 39, 298, 13)];
        _infoLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _infoLabel.font = [UIFont systemFontOfSize:13.f];
        _infoLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_infoLabel];

        _line = [[UIView alloc] initWithFrame:CGRectMake(11, 64, 298, .5)];
        _line.backgroundColor = [UIColor lightGrayColor];
        _line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_line];

        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 73, 298, 178)];
        _contentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _contentLabel.textColor = [UIColor blackColor];
        _contentLabel.font = [UIFont systemFontOfSize:14.f];
        [self.contentView addSubview:_contentLabel];

    }
    return self;
}

- (void)refreshData:(NSDictionary *)data nick:(NSString *)nick{
    NSString *title = [data objectForKey:@"title"];
    _titleLabel.text = title;
    NSString *content = [data objectForKey:@"content"];
    _contentLabel.text = content;
    NSNumber *time = [data objectForKey:@"time"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:time.integerValue];
    NSString *dataString = [dateFormatter stringFromDate:date];
    _infoLabel.text = [NSString stringWithFormat:@"%@ %@", nick ?: @"", dataString];
}

@end
