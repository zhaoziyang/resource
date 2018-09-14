//
//  TextInputController.h
//  FilterDemo
//
//  Created by zhangheng on 2017/4/27.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextInputController : UIViewController
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) void(^result)(NSString *text, UIColor *textColor);
@end
