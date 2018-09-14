//
//  TNFilterSlider.m
//  FilterDemo
//
//  Created by zhangheng on 2017/4/25.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import "TNFilterSlider.h"
#import <Masonry/Masonry.h>

@interface TNFilterSlider()
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIView *thumbView;
@end

@implementation TNFilterSlider
- (UIView *)thumbView {
    if (_thumbView == nil) {
        for (UIView *view in self.subviews.reverseObjectEnumerator.allObjects) {
            if (![view isEqual:self.valueLabel]) {
                _thumbView = view;
                break;
            }
        }
    }
    return _thumbView;
}

- (void)setValue:(float)value {
    [super setValue:value];
    self.valueLabel.text = [NSString stringWithFormat:@"%d", @(value).intValue];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.valueLabel.center = CGPointMake(CGRectGetMidX(self.thumbView.frame), CGRectGetMinY(self.thumbView.frame) - 15.0);
}

- (UILabel *)valueLabel {
    if (_valueLabel == nil) {
        _valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 15)];
        _valueLabel.font = [UIFont systemFontOfSize:13.0];
        _valueLabel.textColor = [UIColor grayColor];
        _valueLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_valueLabel];
    }
    return _valueLabel;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.valueLabel.center = CGPointMake(CGRectGetMidX(self.thumbView.frame), CGRectGetMinY(self.thumbView.frame) - 15.0);
    self.valueLabel.text = [NSString stringWithFormat:@"%d", @(self.value).intValue];
    return [super continueTrackingWithTouch:touch withEvent:event];
}


@end
