//
//  CollectionViewCell.m
//  多选上传图片
//
//  Created by holier_zyq on 16/7/19.
//  Copyright © 2016年 holier_zyq. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.imageV];
        
        
    }
    return self;
}

- (UIImageView *)imageV{
    if (!_imageV) {
        self.imageV = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageV.userInteractionEnabled = YES;
    }
    return _imageV;
}

- (UIButton *)deleteButotn{
    if (!_deleteButotn) {
        self.deleteButotn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButotn.frame = CGRectMake(60, -6, 25, 25);
        [_deleteButotn setBackgroundImage:[UIImage imageNamed:@"common_del_circle@3x"] forState:UIControlStateNormal];
    }
    return _deleteButotn;
}




@end
