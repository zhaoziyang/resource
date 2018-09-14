//
//  FilterPhotoController.m
//  FilterDemo
//
//  Created by zhangheng on 2017/4/24.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import "FilterPhotoController.h"
#import <Masonry/Masonry.h>
#import <GPUImage.h>
#import "TNFilterColorView.h"
#import "TNFilterSlider.h"
#import "TNFilterTextView.h"
#import "TextInputController.h"
#import "TZImagePickerController.h"
#import <Photos/Photos.h>

@interface FilterPhotoController ()<UICollectionViewDelegate, UICollectionViewDataSource, TNFilterColorViewDelegate, TNFilterTextViewDelegate>
@property (nonatomic, strong) GPUImageView *imageView;
@property (nonatomic, strong) UIImageView *containView;
@property (nonatomic, strong) UIView *editArea;
@property (nonatomic, strong) TNFilterSlider *slider;
@property (nonatomic, strong) TNFilterColorView *filterColor;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *editBtn;
@property (nonatomic, strong) UIButton *effectBtn;
@property (nonatomic, strong) UIButton *confirmBtn;

@property (nonatomic, strong) NSArray<NSString *> *dataSource;
@property (nonatomic, strong) NSArray<NSString *> *iconNames;
@property (nonatomic, strong) NSArray<NSString *> *effectNames;

@property (nonatomic, strong) NSIndexPath *selectedIndex;
@property (nonatomic, assign) NSInteger segmentIndex;
@property (nonatomic, strong) NSMutableArray<TNFilterTextView *> *textViews;
@end

@implementation FilterPhotoController {
    GPUImagePicture *sourcePicture;
    GPUImageBrightnessFilter *brightness; // 亮度
    GPUImageContrastFilter *contrast; // 对比度
    GPUImageSaturationFilter *saturation; // 饱和度
    GPUImageWhiteBalanceFilter *whiteBalance; // 色温
    GPUImageHighlightShadowFilter *hightlightShadow; // 高光
    GPUImageLevelsFilter *levels; // 色阶
    GPUImageHueFilter *hue; // HUE
    GPUImageRGBFilter *rgb; // 颜色
    GPUImageFilterPipeline *pipeline; // 组合滤镜
}

- (void)dealloc {
    [[GPUImageContext sharedImageProcessingContext].framebufferCache purgeAllUnassignedFramebuffers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"选择滤镜";
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveImage)], [[UIBarButtonItem alloc] initWithTitle:@"重置" style:UIBarButtonItemStylePlain target:self action:@selector(resetFilter)]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"选择照片" style:UIBarButtonItemStylePlain target:self action:@selector(choosePhoto)];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.photo == nil) {
        self.photo = [UIImage imageNamed:@"Model"];
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self initSubViews];
    [self layoutSubView];
    [self setupFilters];
}

- (void)initSubViews {
//    @"亮度", @"对比度", @"饱和度", @"色温", @"高光", @"阴影", @"色阶", @"HUE", @"RGB"
    self.dataSource = @[@"亮度", @"对比度", @"饱和度", @"色温", @"高光", @"阴影", @"颜色", @"文字"];
    self.iconNames = @[@"brightness", @"contrast", @"saturation", @"temp", @"hightlight", @"shadow", @"color", @"text"];
    self.effectNames = @[@"原图", @"背光", @"暗化", @"多云", @"阴影", @"日落", @"夜景", @"风景"];
    self.textViews = [NSMutableArray array];
    self.selectedIndex = 0;
    
    self.editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editBtn addTarget:self action:@selector(edit) forControlEvents:UIControlEventTouchUpInside];
    [self.editBtn setBackgroundColor:[UIColor whiteColor]];
    [self.editBtn setTitle:@"编辑" forState:UIControlStateNormal];
    [self.editBtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.editBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    self.editBtn.highlighted = YES;
    [self.view addSubview:self.editBtn];
    
    self.effectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.effectBtn addTarget:self action:@selector(effect) forControlEvents:UIControlEventTouchUpInside];
    [self.effectBtn setBackgroundColor:[UIColor whiteColor]];
    [self.effectBtn setTitle:@"特效" forState:UIControlStateNormal];
    [self.effectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.effectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:self.effectBtn];
    
    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.confirmBtn addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    [self.confirmBtn setTitle:@"完成" forState:UIControlStateNormal];
    [self.confirmBtn setBackgroundColor:self.view.backgroundColor];
    [self.confirmBtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.confirmBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:self.confirmBtn];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0.0;
    flowLayout.minimumInteritemSpacing = 10.0;
    flowLayout.itemSize = CGSizeMake(100, 100.0);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [flowLayout invalidateLayout];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.collectionView];
    
    self.slider = [[TNFilterSlider alloc] init];
    self.slider.hidden = YES;
    self.slider.value = 0;
    self.slider.minimumValue = -100.0;
    self.slider.maximumValue = 100.0;
    [self.slider addTarget:self action:@selector(updateFilter:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];
    
    self.filterColor = [[TNFilterColorView alloc] init];
    self.filterColor.hidden = YES;
    self.filterColor.delegate = self;
    self.filterColor.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.filterColor];

    self.editArea = [[UIView alloc] init];
    self.editArea.clipsToBounds = YES;
    self.editArea.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.editArea];
    
    self.containView = [[UIImageView alloc] initWithImage:self.photo];
    self.containView.contentMode = UIViewContentModeScaleAspectFit;
    self.containView.userInteractionEnabled = YES;
    [self.editArea addSubview:self.containView];
    
    self.imageView = [[GPUImageView alloc] init];
    self.imageView.userInteractionEnabled = YES;
    [self.containView addSubview:self.imageView];
    [self.imageView setBackgroundColorRed:0.0 green:0.0 blue:0.0 alpha:1.0];
}

- (void)layoutSubView {
    [self.editBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom);
        make.left.equalTo(self.view.mas_left);
        make.width.mas_equalTo(self.view.mas_width).multipliedBy(0.5);
        make.height.mas_equalTo(40.0);
    }];
    
    [self.effectBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom);
        make.right.equalTo(self.view.mas_right);
        make.width.mas_equalTo(self.view.mas_width).multipliedBy(0.5);
        make.height.mas_equalTo(40.0);
    }];
    
    [self.confirmBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom);
        make.right.equalTo(self.view.mas_right);
        make.width.mas_equalTo(self.view.mas_width);
        make.height.mas_equalTo(40.0);
    }];
    
    [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-40.0);
        make.height.mas_equalTo(100.0);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
    }];
    
    [self.slider mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20.0);
        make.right.equalTo(self.view.mas_right).offset(-20.0);
        make.bottom.equalTo(self.view.mas_bottom).offset(-40.0);
        make.height.mas_equalTo(100.0);
    }];
    
    [self.filterColor mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20.0);
        make.right.equalTo(self.view.mas_right).offset(-20.0);
        make.bottom.equalTo(self.view.mas_bottom).offset(-40.0);
        make.height.mas_equalTo(100.0);
    }];
    
    [self.editArea mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom).offset(-140);
    }];
    
    [self.containView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.editArea.mas_centerX);
        make.top.mas_greaterThanOrEqualTo(self.editArea.mas_top);
        make.left.mas_greaterThanOrEqualTo(self.editArea.mas_left);
        make.right.mas_lessThanOrEqualTo(self.editArea.mas_right);
        make.bottom.mas_lessThanOrEqualTo(self.editArea.mas_bottom);
        make.width.mas_equalTo(self.containView.mas_height).multipliedBy(self.photo.size.width / self.photo.size.height);
    }];
    
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containView.mas_top);
        make.left.equalTo(self.containView.mas_left);
        make.right.equalTo(self.containView.mas_right);
        make.bottom.equalTo(self.containView.mas_bottom);
    }];
}

- (void)setupFilters {
    sourcePicture = [[GPUImagePicture alloc] initWithImage:self.photo smoothlyScaleOutput:YES];
    
    brightness = [[GPUImageBrightnessFilter alloc] init];
    contrast = [[GPUImageContrastFilter alloc] init];
    saturation = [[GPUImageSaturationFilter alloc] init];
    whiteBalance = [[GPUImageWhiteBalanceFilter alloc] init];
    hightlightShadow = [[GPUImageHighlightShadowFilter alloc] init];
    rgb = [[GPUImageRGBFilter alloc] init];
    
    pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:@[brightness, contrast, saturation, whiteBalance, hightlightShadow, rgb] input:sourcePicture output:self.imageView];
//    [sourcePicture addTarget:pipeline.output]; // 加上这段话 编辑的时候闪烁
    
    __weak typeof(&*sourcePicture)weakSource = sourcePicture;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSource processImage];
    });
}

- (void)resetFilter {
    brightness.brightness = 0.0;
    contrast.contrast = 1.0;
    saturation.saturation = 1.0;
    whiteBalance.temperature = 5000.0;
    hightlightShadow.highlights = 1.0;
    hightlightShadow.shadows = 0.0;
    rgb.red = 1.0;
    rgb.green = 1.0;
    rgb.blue = 1.0;
    [sourcePicture processImage];
    for (UIView *view in self.textViews) {
        [view removeFromSuperview];
    }
    [self.textViews removeAllObjects];
    [self confirm];
}

- (void)choosePhoto {
    TZImagePickerController *controller = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    controller.allowPickingVideo = NO;
    controller.allowPickingGif = NO;
    __weak typeof(&*self)weakSelf = self;
    [controller setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto){
        weakSelf.photo = photos.firstObject;
        [[GPUImageContext sharedImageProcessingContext].framebufferCache purgeAllUnassignedFramebuffers];
        weakSelf.containView.image = photos.firstObject;
        [weakSelf layoutSubView];
        [weakSelf setupFilters];
        [weakSelf resetFilter];
    }];
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)saveImage {
    UIImage *image =  [self currentImage];
    __weak typeof(&*image)weakImage = image;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        __strong typeof (&*weakImage)strongImage = weakImage;
        PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:strongImage];
        PHAssetCollection *targetCollection = [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil]lastObject];
        PHAssetCollectionChangeRequest *changeCollectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:targetCollection];
        PHObjectPlaceholder *assetPlaceholder = [changeAssetRequest placeholderForCreatedAsset];
        [changeCollectionRequest addAssets:@[assetPlaceholder]];
    } completionHandler:^(BOOL success,NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:nil message:success ? @"保存图片成功" : @"保存图片失败" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil] show];
        });
    }];
}

- (UIImage *)currentImage {
    [pipeline.filters.lastObject useNextFrameForImageCapture];
    [sourcePicture processImage];
    UIImage *image = [pipeline.filters.lastObject imageFromCurrentFramebuffer];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    for (TNFilterTextView *obj in self.textViews) {
        TNFilterTextView *textView = [TNFilterTextView instanceWithTextView:obj];
        CGSize textViewSize = obj.bounds.size;
        CGPoint textViewCenter = [obj.superview convertPoint:obj.center toView:self.imageView];
        textView.canEdit = NO;
        textView.frame = CGRectMake(0, 0, CGRectGetWidth(imageView.frame) * textViewSize.width / CGRectGetWidth(self.imageView.frame), CGRectGetHeight(imageView.frame) * textViewSize.height / CGRectGetHeight(self.imageView.frame));
        textView.center = CGPointMake(CGRectGetWidth(imageView.frame) * textViewCenter.x /  CGRectGetWidth(self.imageView.frame), CGRectGetHeight(imageView.frame) * textViewCenter.y /  CGRectGetHeight(self.imageView.frame));
        textView.transform = obj.transform;
        [imageView addSubview:textView];
    }
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.opaque, 0.0);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)updateFilter:(TNFilterSlider *)slider {
    switch (self.selectedIndex.row) {
        case 0:
            // 亮度
            brightness.brightness = self.slider.value / 100.0;
            break;
        case 1:
            // 对比度
            contrast.contrast = self.slider.value / 100.0;
            break;
        case 2:
            // 饱和度
            saturation.saturation = self.slider.value / 100.0;
            break;
        case 3:
            // 色温
            whiteBalance.temperature = self.slider.value * 100.0;
            break;
        case 4:
            // 高光
            hightlightShadow.highlights = self.slider.value / 100.0;
            break;
        case 5:
            // 阴影
            hightlightShadow.shadows = self.slider.value / 100.0;
            break;
        default:
            break;
    }
    [sourcePicture processImage];
}

- (void)confirm {
    self.navigationItem.title = @"选择滤镜";
    [self.confirmBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom).offset(0.0);
    }];
    [self.view bringSubviewToFront:self.collectionView];
    self.collectionView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
        self.collectionView.alpha = 1.0;
        self.slider.alpha =  0.0;
        self.filterColor.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.slider.hidden = YES;
        self.filterColor.hidden = YES;
    }];
}

- (void)edit {
    __weak typeof(&*self)weakSelf = self;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        weakSelf.editBtn.highlighted = YES;
        weakSelf.effectBtn.highlighted = NO;
        weakSelf.segmentIndex = 0;
        [weakSelf.collectionView reloadData];
    }];
}

- (void)effect {
    __weak typeof(&*self)weakSelf = self;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        weakSelf.editBtn.highlighted = NO;
        weakSelf.effectBtn.highlighted = YES;
        weakSelf.segmentIndex = 1;
        [weakSelf.collectionView reloadData];
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.segmentIndex == 0 ? self.dataSource.count : self.effectNames.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UIImageView *image = [cell.contentView viewWithTag:1001];
    UILabel *label = [cell.contentView viewWithTag:1002];
    if (label == nil) {
        image = [[UIImageView alloc] init];
        image.contentMode = UIViewContentModeCenter;
        image.tag = 1001;
        image.layer.masksToBounds = YES;
        [cell.contentView addSubview:image];
        [image mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(cell.contentView.mas_width).offset(-40);
            make.height.equalTo(image.mas_width);
            make.centerX.equalTo(cell.contentView.mas_centerX);
            make.bottom.equalTo(cell.contentView.mas_bottom).offset(-5.0);
        }];
        
        label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = 1002;
        [cell.contentView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(image.mas_top).offset(-5.0);
            make.left.equalTo(cell.contentView.mas_left).offset(2.0);
            make.right.equalTo(cell.contentView.mas_right).offset(-2.0);
        }];
    }
    if (self.segmentIndex == 0) {
        label.text = self.dataSource[indexPath.row];
        image.contentMode = UIViewContentModeCenter;
        image.image = [UIImage imageNamed:self.iconNames[indexPath.row]];
    } else {
        image.contentMode = UIViewContentModeScaleAspectFill;
        label.text = self.effectNames[indexPath.row];
        image.image = [UIImage imageNamed:@"Model"];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath;
    if (self.segmentIndex == 0) {
        [self editAction];
    } else {
        // 特效
    }
}

- (void)editAction {
    self.navigationItem.title = self.dataSource[self.selectedIndex.row];
    switch (self.selectedIndex.row) {
        case 0:
            // 亮度
            self.slider.value = brightness.brightness * 100.0;
            self.slider.minimumValue = -100.0;
            self.slider.maximumValue = 100.0;
            break;
        case 1:
            // 对比度
            self.slider.value = contrast.contrast * 100.0;
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 400.0;
            break;
        case 2:
            // 饱和度
            self.slider.value = saturation.saturation * 100.0;
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 200.0;
            break;
        case 3:
            // 色温
            self.slider.value = whiteBalance.temperature / 100.0;
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 100.0;
            break;
        case 4:
            // 高光
            self.slider.value = hightlightShadow.highlights * 100.0;
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 100.0;
            break;
        case 5:
            // 阴影
            self.slider.value = hightlightShadow.shadows * 100.0;
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 100.0;
            break;
        default:
            break;
    }
    switch (self.selectedIndex.row) {
        case 7: {
            TextInputController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TextInputController"];
            __weak typeof(&*self)weakSelf = self;
            [controller setResult:^(NSString *text, UIColor *textColor){
                TNFilterTextView *textView = [TNFilterTextView instance];
                textView.text = text;
                textView.textColor = textColor;
                textView.delegate = weakSelf;
                CGPoint center = CGPointMake(CGRectGetWidth(weakSelf.imageView.frame) / 2, CGRectGetHeight(weakSelf.imageView.frame) / 2);
                textView.center = [weakSelf.imageView convertPoint:center toView:self.editArea];
                [weakSelf.editArea addSubview:textView];
                [weakSelf.textViews addObject:textView];
                weakSelf.navigationItem.title = @"选择滤镜";
            }];
            controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [self presentViewController:controller animated:YES completion:nil];
        }
            break;
        default:
            [self.confirmBtn mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view.mas_bottom).offset(-40.0);
            }];
            [self.view bringSubviewToFront:self.selectedIndex.row == 6 ? self.filterColor : self.slider];
            self.slider.hidden = self.selectedIndex.row == 6 ? YES : NO;
            self.filterColor.hidden = self.selectedIndex.row == 6 ? NO : YES;
            [UIView animateWithDuration:0.25 animations:^{
                [self.view layoutIfNeeded];
                self.collectionView.alpha = 0.0;
                self.slider.alpha = self.selectedIndex.row == 6 ? 0.0 : 1.0;
                self.filterColor.alpha = self.selectedIndex.row == 6  ? 1.0 : 0.0;
            } completion:^(BOOL finished) {
                self.collectionView.hidden = YES;
            }];
            break;
    }
}

- (void)filterColorView:(TNFilterColorView *)filterColorView didSelectedColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    rgb.red = components[0];
    rgb.green = components[1];
    rgb.blue = components[2];
    [sourcePicture processImage];
}

- (void)filterTextView:(TNFilterTextView *)filterTextView editText:(NSString *)text textColor:(UIColor *)textColor {
    TextInputController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TextInputController"];
    controller.text = text;
    controller.textColor = textColor;
    __weak typeof(&*filterTextView)weakObj = filterTextView;
    [controller setResult:^(NSString *text, UIColor *textColor){
        weakObj.text = text;
        weakObj.textColor = textColor;
    }];
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:controller animated:YES completion:nil];
}
@end
