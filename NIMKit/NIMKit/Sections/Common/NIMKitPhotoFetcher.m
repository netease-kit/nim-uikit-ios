//
//  NIMKitPhotoFetcher.m
//  NIMKit
//
//  Created by chris on 2016/11/12.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMKitPhotoFetcher.h"
#import "CTAssetsPickerController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NIMKitFileLocationHelper.h"

typedef enum : NSUInteger {
    NIMKitImagePickerModeImage,
    NIMKitImagePickerModeSnapChat,
} NIMKitImagePickerMode;

@interface NIMKitPhotoFetcher()<CTAssetsPickerControllerDelegate>

@property (nonatomic,assign) NIMKitImagePickerMode  mode;

@end

@implementation NIMKitPhotoFetcher

- (void)fetchImageFromPhotoLibrary:(NIMKitPhotoFetchResult)result
{
    self.mode = NIMKitImagePickerModeImage;
    [self setUpPhotoLibrary:^(CTAssetsPickerController * _Nullable picker) {
        if (picker) {
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:picker animated:YES completion:nil];
        }
    }];
}

- (void)fetchImageFromCamera:(NIMKitPhotoFetchResult)result
{
    
}


- (void)setUpPhotoLibrary:(void(^)( CTAssetsPickerController * _Nullable picker)) handler
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                [[[UIAlertView alloc] initWithTitle:nil
                                            message:@"相册权限受限"
                                           delegate:nil
                                  cancelButtonTitle:@"确定"
                                  otherButtonTitles:nil] show];
                if(handler) handler(nil);
            }
            if (status == PHAuthorizationStatusAuthorized) {
                CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
                
                // set delegate
                picker.delegate = self;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    picker.modalPresentationStyle = UIModalPresentationFormSheet;
                
                if(handler) handler(picker);
            }
        });
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *inputURL  = [info objectForKey:UIImagePickerControllerMediaURL];
            NSString *outputFileName = [NIMKitFileLocationHelper genFilenameWithExt:@"mp4"];
            NSString *outputPath = [NIMKitFileLocationHelper filepathForVideo:outputFileName];
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
            AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                             presetName:AVAssetExportPresetMediumQuality];
            session.outputURL = [NSURL fileURLWithPath:outputPath];
            session.outputFileType = AVFileTypeMPEG4;   // 支持安卓某些机器的视频播放
            session.shouldOptimizeForNetworkUse = YES;
            session.videoComposition = [self getVideoComposition:asset];  //修正某些播放器不识别视频Rotation的问题
            [session exportAsynchronouslyWithCompletionHandler:^(void)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (session.status == AVAssetExportSessionStatusCompleted) {
                         [self sendMessage:[NTESSessionMsgConverter msgWithVideo:outputPath]];
                     }
                     else {
                         [self.view makeToast:@"发送失败"
                                     duration:2
                                     position:CSToastPositionCenter];
                     }
                 });
             }];
            
        });
        
    }else{
        UIImage *orgImage = info[UIImagePickerControllerOriginalImage];
        [self sendImageMessage:orgImage];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 相册回调
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    __weak typeof(self) weakSelf = self;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous  = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    [SVProgressHUD show];
    for (PHAsset *asset in assets) {
        [asset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            NSString *path = contentEditingInput.fullSizeImageURL.relativePath;
            dispatch_async_main_safe(^{
                [weakSelf sendImageMessagePath:path];
                if (asset == assets.lastObject) {
                    [SVProgressHUD dismiss];
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                }
            });
        }];
    }
}


#pragma mark - Private
- (AVMutableVideoComposition *)getVideoComposition:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    BOOL isPortrait_ = [NTESSessionUtil isVideoPortrait:asset];
    if(isPortrait_) {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    composition.naturalSize     = videoSize;
    videoComposition.renderSize = videoSize;
    
    videoComposition.frameDuration = CMTimeMakeWithSeconds( 1 / videoTrack.nominalFrameRate, 600);
    AVMutableCompositionTrack *compositionVideoTrack;
    compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}


@end
