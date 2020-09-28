//
//  NIMKitMediaPickerController.m
//  NIMKit
//
//  Created by Genning on 2020/9/25.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMKitMediaPickerController.h"
#import "NIMKitProgressHUD.h"
#import "NIMKitDependency.h"
#import "NIMGlobalMacro.h"
#import "NIMKitFileLocationHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface NIMKitMediaPickerController ()<TZImagePickerControllerDelegate>

@end

@implementation NIMKitMediaPickerController

- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount {
    if (self = [super initWithMaxImagesCount:maxImagesCount delegate:nil]) {
        self.pickerDelegate = self;
    }
    return self;
}

- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<TZImagePickerControllerDelegate>)delegate {
    if (self = [super initWithMaxImagesCount:maxImagesCount delegate:delegate]) {
        self.navigationBar.barStyle = UIBarStyleDefault;
        self.naviBgColor = [UIColor blackColor];
        self.naviTitleColor = [UIColor whiteColor];
        self.barItemTextColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle =  UIStatusBarStyleDefault;
}

#pragma mark - <TZImagePickerControllerDelegate>
- (void)imagePickerController:(TZImagePickerController *)picker
       didFinishPickingPhotos:(NSArray<UIImage *> *)photos
                 sourceAssets:(NSArray *)assets
        isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos {
    if (isSelectOriginalPhoto)
    {
        [self requestAssets:[assets mutableCopy]];
    }
    else
    {
        if ([_nim_delegate respondsToSelector:@selector(onPickerSelectedWithType:images:path:)]) {
            [_nim_delegate onPickerSelectedWithType:PHAssetMediaTypeImage images:photos path:nil];
        }
    }
}

- (void)imagePickerController:(TZImagePickerController *)picker
        didFinishPickingVideo:(UIImage *)coverImage
                 sourceAssets:(id)asset{
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:@[asset]];
    [self requestAssets:items];
}

- (void)imagePickerController:(TZImagePickerController *)picker
     didFinishPickingGifImage:(UIImage *)animatedImage
                 sourceAssets:(PHAsset *)asset {
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:@[asset]];
    [self requestAssets:items];
}

- (void)requestAssets:(NSMutableArray *)assets
{
    if (!assets.count) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [NIMKitProgressHUD show];
    [self requestAsset:assets.firstObject handler:^(NSString *path, PHAssetMediaType type) {
        [NIMKitProgressHUD dismiss];
        if ([weakSelf.nim_delegate respondsToSelector:@selector(onPickerSelectedWithType:images:path:)]) {
            [weakSelf.nim_delegate onPickerSelectedWithType:type images:nil path:path];
        }
        NIMKit_Dispatch_Async_Main(^{
            [assets removeObjectAtIndex:0];
            [weakSelf requestAssets:assets];
        })
    }];
}

- (void)requestAsset:(PHAsset *)asset handler:(void(^)(NSString *,PHAssetMediaType)) handler
{
    __weak typeof(self) weakSelf = self;
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.version = PHVideoRequestOptionsVersionCurrent;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            
            [PHImageManager.defaultManager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable assetR, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                NSError *error = nil;
                NSString *outputPath = nil;
                if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                    outputPath = nil;
                    error = [NSError errorWithDomain:@"nimdemo.netease.fetcher" code:0x1000 userInfo:@{NSLocalizedDescriptionKey:@"图片在iCloud上"}];
                    [weakSelf showErrorMsg:@"文件在iCloud上，无法发送"];
                } else {
                    AVURLAsset *URLAsset = (AVURLAsset *)assetR;
                    NSString *outputFileName = [NIMKitFileLocationHelper genFilenameWithExt:@"mp4"];
                    outputPath = [NIMKitFileLocationHelper filepathForVideo:outputFileName];
                    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:URLAsset.URL.path];
                    if (!fileExist) {
                        error = [NSError errorWithDomain:@"nimdemo.netease.fetcher" code:0x1001 userInfo:@{NSLocalizedDescriptionKey:@"图片在本地不存在"}];
                        [weakSelf showErrorMsg:@"图片在本地不存在，无法发送"];
                    } else {
                        [NSFileManager.defaultManager copyItemAtURL:URLAsset.URL toURL:[NSURL fileURLWithPath:outputPath] error:&error];
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(!error ? outputPath : nil, PHAssetMediaTypeVideo);
                });
            }];
        });
    }
    
    if (asset.mediaType == PHAssetMediaTypeImage)
    {
        [asset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            NSString *path = contentEditingInput.fullSizeImageURL.relativePath;
            handler(path,contentEditingInput.mediaType);
        }];
    }
    
}

- (void)showErrorMsg:(NSString *)msg {
    NIMKit_Dispatch_Async_Main(^{
        [[UIApplication sharedApplication].keyWindow makeToast:msg
                                                      duration:2
                                                      position:CSToastPositionCenter];
    });
}

#pragma mark - setter
- (void)setMediaTypes:(NSArray<NSString *> *)mediaTypes {
    _mediaTypes = mediaTypes;
    self.allowPickingVideo = [mediaTypes containsObject:(NSString *)kUTTypeMovie];
    self.allowPickingImage = [mediaTypes containsObject:(NSString *)kUTTypeImage];
    self.allowPickingGif = [mediaTypes containsObject:(NSString *)kUTTypeGIF];
}

@end
