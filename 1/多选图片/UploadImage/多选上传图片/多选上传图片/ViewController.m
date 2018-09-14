//
//  ViewController.m
//  多选上传图片
//
//  Created by holier_zyq on 16/7/15.
//  Copyright © 2016年 holier_zyq. All rights reserved.
//

#import "ViewController.h"
#import "ZYQAssetPickerController.h"
#import "CollectionViewCell.h"

#define Kwidth [UIScreen mainScreen].bounds.size.width
#define Kheight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<UIActionSheetDelegate,ZYQAssetPickerControllerDelegate,UINavigationControllerDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic ,strong) UIButton *button;
@property (nonatomic ,strong) ZYQAssetPickerController *pickerController;
@property (nonatomic ,strong) UICollectionView *collectionView;


@property (nonatomic ,strong) NSMutableArray *imageArray;
@property (nonatomic ,strong) NSMutableArray *imageDataArray;

@property (nonatomic ,assign) NSInteger i;


@end

@implementation ViewController




-(UICollectionView *)collectionView{
    if (!_collectionView) {
        
        UICollectionViewFlowLayout *flowLayOut = [[UICollectionViewFlowLayout alloc] init];
//        flowLayOut.minimumInteritemSpacing = 11;
//        flowLayOut.minimumLineSpacing = 11;
        flowLayOut.itemSize = CGSizeMake(80, 80);
        flowLayOut.sectionInset = UIEdgeInsetsMake(11, 11, 0, 11);
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, Kwidth, 300) collectionViewLayout:flowLayOut];
        
        
        _collectionView.backgroundColor = [UIColor cyanColor];
        
        
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
//        self.collectionView.scrollEnabled = NO;
    }
    return _collectionView;
}

- (NSMutableArray *)imageDataArray{
    if (!_imageDataArray) {
        self.imageDataArray = [NSMutableArray array];
    }
    return _imageDataArray;
}

- (NSMutableArray *)imageArray{
    if (!_imageArray) {
        self.imageArray = [NSMutableArray array];
       
    }
    return _imageArray;
}

- (ZYQAssetPickerController *)pickerController{
    if (!_pickerController) {
        self.pickerController = [[ZYQAssetPickerController alloc] init];
        _pickerController.maximumNumberOfSelection = 8;
        _pickerController.assetsFilter = ZYQAssetsFilterAllAssets;
        _pickerController.showEmptyGroups=NO;
        _pickerController.delegate=self;
        _pickerController.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            if ([(ZYQAsset*)evaluatedObject mediaType]==ZYQAssetMediaTypeVideo) {
                NSTimeInterval duration = [(ZYQAsset*)evaluatedObject duration];
                return duration >= 5;
            } else {
                return YES;
            }
            
            
        }];
        
    }
    return _pickerController;
}



- (UIButton *)button {
    if (!_button) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
                _button.frame = CGRectMake(0, Kheight - 49, Kwidth, 49);
        [_button setTitle:@"上传图片" forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(submitPictureToServer) forControlEvents:UIControlEventTouchUpInside];
        [_button setBackgroundColor:[UIColor redColor]];
        
    }
    return _button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.button];
    self.i = 0;
    [self.collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.collectionView registerClass:[AddCollectionViewCell class] forCellWithReuseIdentifier:@"identifier"];
    [self.view addSubview:self.collectionView];
    
    
}

-(void)submitPictureToServer{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"相机" otherButtonTitles:@"从相册获取", nil];
    [sheet showInView:self.view];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSLog(@"模拟器没有相机");
    }else if (buttonIndex == 1){
        [self presentViewController:self.pickerController animated:YES completion:nil];
    }
}


#pragma mark ---------collectionView代理方法--------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
   

    return self.imageArray.count + 1 ;
    

    
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    AddCollectionViewCell *cell1 = [collectionView dequeueReusableCellWithReuseIdentifier:@"identifier" forIndexPath:indexPath];

    if (self.imageArray.count == 0) {
        return cell1;
        
    }else{
    
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

        if (indexPath.item + 1 > self.imageArray.count ) {

            return cell1;

            
        }else{
            cell.imageV.image = self.imageArray[indexPath.item];
            [cell.imageV addSubview:cell.deleteButotn];
            cell.deleteButotn.tag = indexPath.item + 100;
            [cell.deleteButotn addTarget:self action:@selector(deleteImage:) forControlEvents:UIControlEventTouchUpInside];
        }
    
    
        return cell;
    }
    
    

    
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item + 1 > self.imageArray.count ) {
        NSLog(@"上传");
        [self submitPictureToServer];
    }else{
        ImageViewController *imageViewC =[[ImageViewController alloc] init];
        //取出存储的高清图片
        imageViewC.imageData = self.imageDataArray[indexPath.item];
        [self presentViewController:imageViewC animated:YES completion:nil];
    }
    
}

#pragma mark --------删除图片-----------

- (void)deleteImage:(UIButton *)sender{
    NSInteger index = sender.tag - 100;
//    NSLog(@"index=%ld",index);
//    NSLog(@"+++%ld",self.imageDataArray.count);
//    NSLog(@"---%ld",self.imageArray.count);
   
    //移除显示图片数组imageArray中的数据
    [self.imageArray removeObjectAtIndex:index];
    //移除沙盒数组中imageDataArray的数据
    [self.imageDataArray removeObjectAtIndex:index];
    
    NSArray *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //获取Document文件的路径
    NSString *collectPath = filePath.lastObject;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    //移除所有文件
    [fileManager removeItemAtPath:collectPath error:nil];
    //重新写入
    for (int i = 0; i < self.imageDataArray.count; i++) {
        NSData *imgData = self.imageDataArray[i];
        [self WriteToBox:imgData];
    }
    
        [self.collectionView reloadData];
    
    
}

#pragma mark ------相册回调方法----------

-(void)assetPickerController:(ZYQAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets{
   
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<assets.count; i++) {
            ZYQAsset *asset=assets[i];
            [asset setGetFullScreenImage:^(UIImage *result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //由于iphone拍照的图片太大，直接存入数组中势必会造成内存警告，严重会导致程序崩溃，所以存入沙盒中
                    //压缩图片，这个压缩的图片就是做为你传入服务器的图片
                    NSData *imageData=UIImageJPEGRepresentation(result, 0.8);
                    [self.imageDataArray addObject:imageData];
                    [self WriteToBox:imageData];
                    //添加到显示图片的数组中
                    UIImage *image = [self OriginImage:result scaleToSize:CGSizeMake(80, 80)];
                    [self.imageArray addObject:image];
                    [self.collectionView reloadData];

                });
                
            }];
        }
       

        
    });
    
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.collectionView reloadData];
    }];
}


//选择图片上限提示
-(void)assetPickerControllerDidMaximum:(ZYQAssetPickerController *)picker{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"到达9张图片上限" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
}

#pragma mark --------存入沙盒------------
- (void)WriteToBox:(NSData *)imageData{
    
    _i ++;
    NSArray *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //获取Document文件的路径
    NSString *collectPath = filePath.lastObject;
   
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:collectPath]) {
        
        [fileManager createDirectoryAtPath:collectPath withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    //    //拼接新路径
    NSString *newPath = [collectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Picture_%ld.png",_i]];
    NSLog(@"++%@",newPath);
    [imageData writeToFile:newPath atomically:YES];
}

#pragma mark -----改变显示图片的尺寸----------
-(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
