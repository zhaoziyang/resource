//
//  AddCollectionViewCell.m
//  多选上传图片
//
//  Created by holier_zyq on 16/7/20.
//  Copyright © 2016年 holier_zyq. All rights reserved.
//

#import "AddCollectionViewCell.h"

@implementation AddCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.addImageV];
        
        
    }
    return self;
}

- (UIImageView *)addImageV{
    if (!_addImageV) {
        self.addImageV = [[UIImageView alloc] initWithFrame:self.bounds];
        _addImageV.image = [UIImage imageNamed:@"addImage@2x.jpg"];
        
    }
    return _addImageV;
}
@end
