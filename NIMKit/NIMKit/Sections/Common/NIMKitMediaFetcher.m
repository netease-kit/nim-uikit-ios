//
//  NIMKitPhotoFetcher.m
//  NIMKit
//
//  Created by chris on 2016/11/12.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMKitMediaFetcher.h"
#import "CTAssetsPickerController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NIMKitFileLocationHelper.h"
#import "NIMMessageMaker.h"
#import "SVProgressHUD.h"
#import "NIMGlobalMacro.h"

@interface NIMKitMediaFetcher()<CTAssetsPickerControllerDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic,copy)   NIMKitLibraryFetchResult libraryResultHandler;

@property (nonatomic,copy)   NIMKitCameraFetchResult  cameraResultHandler;

@property (nonatomic,strong) UIImagePickerController  *imagePicker;

@property (nonatomic,strong) CTAssetsPickerController *assetsPicker;

@end

@implementation NIMKitMediaFetcher

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mediaTypes = @[(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage];
        _limit = 9;
    }
    return self;
}

- (void)fetchPhotoFromLibrary:(NIMKitLibraryFetchResult)result
{
    __weak typeof(self) weakSelf = self;
    [self setUpPhotoLibrary:^(CTAssetsPickerController * _Nullable picker) {
        if (picker && weakSelf) {
            weakSelf.assetsPicker = picker;
            weakSelf.libraryResultHandler = result;
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:picker animated:YES completion:nil];
            
        }else{
            result(nil,PHAssetMediaTypeUnknown);
        }
    }];
}

- (void)fetchMediaFromCamera:(NIMKitCameraFetchResult)result
{
    if ([self initCamera]) {
        self.cameraResultHandler = result;
#if TARGET_IPHONE_SIMULATOR
        NSAssert(0, @"not supported");
#elif TARGET_OS_IPHONE
        self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.imagePicker animated:YES completion:nil];
#endif
    }
}


- (void)setUpPhotoLibrary:(void(^)( CTAssetsPickerController * _Nullable picker)) handler
{
    __weak typeof(self) weakSelf = self;
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
                CTAssetsPickerController *assetsPicker = [[CTAssetsPickerController alloc] init];
                assetsPicker.assetCollectionSubtypes = weakSelf.assetMediaTypes;
                assetsPicker.delegate = weakSelf;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    assetsPicker.modalPresentationStyle = UIModalPresentationFormSheet;
                if(handler) handler(assetsPicker);
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
                     if (session.status == AVAssetExportSessionStatusCompleted)
                     {
                         self.cameraResultHandler(outputPath,nil);
                     }
                     else
                     {
                         self.cameraResultHandler(nil,nil);
                     }
                     self.cameraResultHandler = nil;
                 });
             }];
            
        });
        
    }else{
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        self.cameraResultHandler(nil,image);
        self.cameraResultHandler = nil;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 相册回调
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous  = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    [SVProgressHUD show];
    
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:assets];
    [self requestAssets:items];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [picker dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)requestAssets:(NSMutableArray *)assets
{
    if (!assets.count) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self requestAsset:assets.firstObject handler:^(NSString *path, PHAssetMediaType type) {
        if (weakSelf.libraryResultHandler) {
            weakSelf.libraryResultHandler(path,type);
        }
        NIMKit_Dispatch_Async_Main(^{
            [assets removeObjectAtIndex:0];
            [weakSelf requestAssets:assets];
        })
        
    }];
}

- (void)requestAsset:(PHAsset *)asset handler:(void(^)(NSString *,PHAssetMediaType)) handler
{
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            NSString *path = [(AVURLAsset *)asset URL].relativePath;
            handler(path, PHAssetMediaTypeVideo);
        }];
    }
    if (asset.mediaType == PHAssetMediaTypeImage) {
        [asset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            NSString *path = contentEditingInput.fullSizeImageURL.relativePath;
            handler(path,contentEditingInput.mediaType);
        }];
    }
    
    
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(PHAsset *)asset
{
    if (self.limit == 1) {
        [self assetsPickerController:picker didFinishPickingAssets:@[asset]];
        return NO;
    }
    
    for (PHAsset *item in picker.selectedAssets) {
        if (item.mediaType == PHAssetMediaTypeVideo || asset.mediaType == PHAssetMediaTypeVideo) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"视频只能单独发送,一次只能发送一个" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return NO;
        }
    }
    
    return picker.selectedAssets.count < self.limit;
}


#pragma mark - Private

- (void)setMediaTypes:(NSArray *)mediaTypes
{
    _mediaTypes = mediaTypes;
    _imagePicker.mediaTypes = mediaTypes;
    _assetsPicker.assetCollectionSubtypes = self.assetMediaTypes;
}

- (NSArray *)assetMediaTypes
{
    NSMutableArray *subTypes   = [self.assetSubtypes mutableCopy];
    
    NSArray *videoTypes = @[
                            @(PHAssetCollectionSubtypeSmartAlbumVideos),
                            @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos)];
    
    if (![_mediaTypes containsObject:(NSString *)kUTTypeImage]) {
        subTypes = [videoTypes mutableCopy];
    }
    if (![_mediaTypes containsObject:(NSString *)kUTTypeMovie]) {
        [subTypes removeObjectsInArray:videoTypes];
    }
    return subTypes;
}

- (AVMutableVideoComposition *)getVideoComposition:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    BOOL isPortrait_ = [self isVideoPortrait:asset];
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

- (BOOL) isVideoPortrait:(AVAsset *)asset
{
    BOOL isPortrait = NO;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks    count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        CGAffineTransform t = videoTrack.preferredTransform;
        // Portrait
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            isPortrait = YES;
        }
        // PortraitUpsideDown
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
            
            isPortrait = YES;
        }
        // LandscapeRight
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            isPortrait = NO;
        }
        // LandscapeLeft
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            isPortrait = NO;
        }
    }
    return isPortrait;
}

- (BOOL)initCamera{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"检测不到相机设备"
                                   delegate:nil
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil] show];
        return NO;
    }
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"相机权限受限"
                                   delegate:nil
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil] show];
        return NO;
        
    }
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.mediaTypes = self.mediaTypes;
    return YES;
}

- (NSArray *)assetSubtypes
{
    NSArray *assetCollectionSubtypes =
    @[@(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
      @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
      @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
      @(PHAssetCollectionSubtypeSmartAlbumFavorites),
      @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
      @(PHAssetCollectionSubtypeSmartAlbumVideos),
      @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
      @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
      @(PHAssetCollectionSubtypeSmartAlbumBursts),
      @(PHAssetCollectionSubtypeSmartAlbumAllHidden),
      @(PHAssetCollectionSubtypeSmartAlbumGeneric),
      @(PHAssetCollectionSubtypeAlbumRegular),
      @(PHAssetCollectionSubtypeAlbumSyncedAlbum),
      @(PHAssetCollectionSubtypeAlbumSyncedEvent),
      @(PHAssetCollectionSubtypeAlbumSyncedFaces),
      @(PHAssetCollectionSubtypeAlbumImported),
      @(PHAssetCollectionSubtypeAlbumCloudShared)];
    
    // Add iOS 9's new albums
    if ([[PHAsset new] respondsToSelector:@selector(sourceType)])
    {
        NSMutableArray *subtypes = [NSMutableArray arrayWithArray:assetCollectionSubtypes];
        [subtypes insertObject:@(PHAssetCollectionSubtypeSmartAlbumSelfPortraits) atIndex:4];
        [subtypes insertObject:@(PHAssetCollectionSubtypeSmartAlbumScreenshots) atIndex:10];
        
        assetCollectionSubtypes = [NSArray arrayWithArray:subtypes];
    }
    return assetCollectionSubtypes;
}


@end
