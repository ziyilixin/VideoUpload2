//
//  ViewController.m
//  Video2
//
//  Created by zzqtkj on 2021/9/11.
//

#define MAS_SHORTHAND
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UIImageView *picImageView;
// 将要模态出来的 imgPickerController, 通过设置媒体源来确定是相册还是摄像头
@property (strong, nonatomic) UIImagePickerController *imgPickerController;
//相册选取视频还是录像
@property (assign, nonatomic) BOOL isPhotoAlbum;
@property (nonatomic,strong)NSString *filePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImageView *picImageView = [[UIImageView alloc] init];
    picImageView.image = [UIImage imageNamed:@"upload_video"];
    picImageView.userInteractionEnabled = YES;
    [self.view addSubview:picImageView];
    self.picImageView = picImageView;
    [self.picImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.equalTo(self.view).offset(100);
        make.width.height.mas_equalTo(100);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uploadVideo)];
    [self.picImageView addGestureRecognizer:tap];
}

- (void)uploadVideo {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"上传视频" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册选取视频" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        // 选取视频状态
        self.isPhotoAlbum = YES;
        // 模态出 imgPicker 来干活
        [self presentViewController:self.imgPickerController animated:YES completion:nil];
    }];
    UIAlertAction *videoAction = [UIAlertAction actionWithTitle:@"录像" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        // 录像状态
        self.isPhotoAlbum = NO;
        // 模态出 imgPicker 来干活
        [self presentViewController:self.imgPickerController animated:YES completion:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil];
    
    [alertController addAction:photoAction];
    [alertController addAction:videoAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    if (self.imgPickerController.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {// 相册选取视频
        // 获取到这个视频的路径
        NSURL *videoPath = [info objectForKey:UIImagePickerControllerMediaURL];
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoPath];
        
        //进行视频导出
        [self startExportVideoWithVideoAsset:asset completion:^(NSString *outputPath) {
            [self getSomeMessageWithFilePath:self.filePath];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:outputPath]];
            NSLog(@"%@",data);
        }];
    }
    else if (self.imgPickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {// 录像
        // 录像会自动放到沙盒的某个路径, 获取到这个路径
        NSString *videoPathString = (NSString *)([info[@"UIImagePickerControllerMediaURL"] path]);
        // 获取到这个视频的路径
        NSURL *videoPath = [info objectForKey:UIImagePickerControllerMediaURL];
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoPath];
        // 是否保存录像到相册(不写的话就是不保存), 保存后有一个回调方法
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPathString)) {
            UISaveVideoAtPathToSavedPhotosAlbum(videoPathString, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
        //进行视频导出
        [self startExportVideoWithVideoAsset:asset completion:^(NSString *outputPath) {
            [self getSomeMessageWithFilePath:self.filePath];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:outputPath]];
            NSLog(@"%@",data);
        }];
    }
    
    // 模态走imgPicker
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // 模态走imgPicker
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)video:(NSString *)videoPathString didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        NSLog(@"视频的路径为: %@",videoPathString);
    }
    else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频保存错误,请稍后重试!" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *defaltAction = [UIAlertAction actionWithTitle:@"确认" style:(UIAlertActionStyleDefault) handler:nil];
        [alertController addAction:defaltAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)startExportVideoWithVideoAsset:(AVURLAsset *)videoAsset completion:(void (^)(NSString *outputPath))completion {
    
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    NSString *pre = nil;
    if ([presets containsObject:AVAssetExportPreset3840x2160]) {
        pre = AVAssetExportPreset3840x2160;
    }
    else if ([presets containsObject:AVAssetExportPreset1920x1080]) {
        pre = AVAssetExportPreset1920x1080;
    }
    else if ([presets containsObject:AVAssetExportPreset1280x720]) {
        pre = AVAssetExportPreset1280x720;
    }
    else if ([presets containsObject:AVAssetExportPreset960x540]) {
        pre = AVAssetExportPreset960x540;
    }
    else {
        pre = AVAssetExportPreset640x480;
    }
    
    if ([presets containsObject:AVAssetExportPreset640x480]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:AVAssetExportPreset640x480];
        
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        
        NSString *outputPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@",[[formater stringFromDate:[NSDate date]] stringByAppendingString:@".mov"]];
        NSLog(@"video outputPath = %@",outputPath);
        
        //删除原来的 防止重复选
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
        
        self.filePath = outputPath;
        session.outputURL = [NSURL fileURLWithPath:outputPath];
        session.shouldOptimizeForNetworkUse = YES;
        
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        }
        else if (supportedTypeArray.count == 0) {
            NSLog(@"No supported file types 视频类型暂不支持导出");
            return;
        }
        else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents"]]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents"] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        }
        
        //Begin to export video to the output path asynchronously.
        [session exportAsynchronouslyWithCompletionHandler:^(void){
            switch (session.status) {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"AVAssetExportSessionStatusUnknown"); break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"AVAssetExportSessionStatusWaiting"); break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"AVAssetExportSessionStatusExporting"); break;
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"AVAssetExportSessionStatusCompleted");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(outputPath);
                        }
                    });
                }  break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"AVAssetExportSessionStatusFailed"); break;
                default: break;
            }
        }];
        
    }
}

//获取视频第一帧
- (void)getSomeMessageWithFilePath:(NSString *)filePath {
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [AVURLAsset assetWithURL:fileUrl];
    self.picImageView.image = [self getImageWithAsset:asset];
}

- (UIImage *)getImageWithAsset:(AVAsset *)asset {
    AVURLAsset *assetUrl = (AVURLAsset *)asset;
    NSParameterAssert(assetUrl);
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:assetUrl];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = 0;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage: thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

- (UIImagePickerController *)imgPickerController {
    // 调用 imgPickerController 的时候, 判断一下是否支持相册或者摄像头功能
    if ([UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeSavedPhotosAlbum)] && [UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeCamera)]) {
        
        if (!_imgPickerController) {
            
            _imgPickerController = [[UIImagePickerController alloc] init];
            _imgPickerController.delegate = self;
            // 产生的媒体文件是否可进行编辑
            _imgPickerController.allowsEditing = YES;
            // 媒体类型
            _imgPickerController.mediaTypes = @[@"public.movie"];
        }
        
        if (self.isPhotoAlbum) {
            // 媒体源, 这里设置为相册
            _imgPickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        }
        else{
            // 媒体源, 这里设置为摄像头
            _imgPickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            // 摄像头, 这里设置默认使用后置摄像头
            _imgPickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            // 摄像头模式, 这里设置为录像模式
            _imgPickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            // 录像质量
            _imgPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
            
            /**
             *  录像质量 :
             
             这三种录像质量会录出一个根据当前设备自适应分辨率的视频文件, MOV格式, 视频采用 H264 编码, 三种质量视频的清晰度还是有明显差别, 所以我一般选取高质量的录像, 然后才去中质量的视频压缩, 最终得到的视频清晰度和高质量没啥区别, 而大小又和中质量直接录的视频没啥区别
             UIImagePickerControllerQualityTypeLow
             UIImagePickerControllerQualityTypeMedium
             UIImagePickerControllerQualityTypeHigh
             
             这三种录像质量会录出一个指定分辨率的视频文件, MOV格式, 视频采用 H264 编码, 但是我们一般选取中质量
             UIImagePickerControllerQualityType640x480
             UIImagePickerControllerQualityTypeIFrame960x540
             UIImagePickerControllerQualityTypeIFrame1280x720
             */
        }
        
        return _imgPickerController;
    }
    else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"您的设备不支持此功能!" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *defaltAction = [UIAlertAction actionWithTitle:@"确认" style:(UIAlertActionStyleDefault) handler:nil];
        [alertController addAction:defaltAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return nil;
    }
}

@end
