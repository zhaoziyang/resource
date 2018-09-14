//
//  TNFilterTextView.h
//  FilterDemo
//
//  Created by zhangheng on 2017/4/26.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TNFilterTextView;
@protocol TNFilterTextViewDelegate <NSObject>

- (void)filterTextView:(TNFilterTextView *)filterTextView editText:(NSString *)text textColor:(UIColor *)textColor;

@end

@interface TNFilterTextView : UIView
/**
 内容
 */
@property (nonatomic, strong) NSString *text;
/**
 文字颜色 default Black
 */
@property (nonatomic, strong) UIColor *textColor;
/**
 代理 default nil
 */
@property (nonatomic, strong) id<TNFilterTextViewDelegate> delegate;
/**
 是否可编辑 default YES
 */
@property (nonatomic, assign) BOOL canEdit;
+ (instancetype)instance;
+ (instancetype)instanceWithTextView:(TNFilterTextView *)textView;
@end
