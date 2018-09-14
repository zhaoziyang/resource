//
//  TNFilterColorView.h
//  FilterDemo
//
//  Created by zhangheng on 2017/4/25.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TNFilterColorView;
@protocol TNFilterColorViewDelegate <NSObject>

- (void)filterColorView:(TNFilterColorView *)filterColorView didSelectedColor:(UIColor *)color;

@end

@interface TNFilterColorView : UIView

@property (nonatomic, strong) UIColor *defaultColor;
@property (nonatomic, weak) id<TNFilterColorViewDelegate> delegate;

@end
