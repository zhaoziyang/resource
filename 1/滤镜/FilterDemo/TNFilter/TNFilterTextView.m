//
//  TNFilterTextView.m
//  FilterDemo
//
//  Created by zhangheng on 2017/4/26.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import "TNFilterTextView.h"
#import <Masonry/Masonry.h>

#define RADIAN_TO_DEGREE(__ANGLE__) ((__ANGLE__) * 180/M_PI)
#define DEGREE_TO_RADIAN(__ANGLE__) ((__ANGLE__) * M_PI/180.0)
#define DEFAUlTSIZE CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) * 0.7, CGRectGetWidth([UIScreen mainScreen].bounds) * 0.7 * 0.25)
#define MINWIDTH 130.0
#define MAXWIDTH 1000.0

@interface TNTextLabel : UILabel
@end
@implementation TNTextLabel

- (void)drawRect:(CGRect)rect {
    [super drawTextInRect:CGRectInset(rect, 20, 20)];
}

@end

@interface TNFilterTextView() <UIGestureRecognizerDelegate>
@property (nonatomic, strong) CAShapeLayer *dashedBoarder;
@property (nonatomic, strong) UIImageView *editPressKey;
@property (nonatomic, strong) UIImageView *rotatoPressKey;
@property (nonatomic, strong) TNTextLabel *textLabel;
@end

@implementation TNFilterTextView

+ (instancetype)instance {
    return [[TNFilterTextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) * 0.7, CGRectGetWidth([UIScreen mainScreen].bounds) * 0.7 / 4)];
}

+ (instancetype)instanceWithTextView:(TNFilterTextView *)textView {
    TNFilterTextView *instance = [[TNFilterTextView alloc] initWithFrame:textView.bounds];
    instance.text = textView.text;
    instance.textColor = textView.textColor;
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initSubviews];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    if ([self.editPressKey pointInside:[self convertPoint:point toView:self.editPressKey] withEvent:event]) {
        return self.editPressKey;
    }
    if ([self.rotatoPressKey pointInside:[self convertPoint:point toView:self.rotatoPressKey] withEvent:event]) {
        return self.rotatoPressKey;
    }
    return result;
}

- (void)initSubviews {
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editText:)]];
    
    self.textLabel = [[TNTextLabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) * 2, CGRectGetWidth([UIScreen mainScreen].bounds) * 2 / 4)];
    self.textLabel.font = [UIFont systemFontOfSize:80.0];
    self.textLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.numberOfLines = 0;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.text = @"我来发就死定了快放假了圣诞节菲利克斯就发了可视对讲菲利克斯就分开老是几分考虑时间";
    self.textLabel.shadowColor = [UIColor blackColor];
    self.textLabel.shadowOffset = CGSizeMake(1, 1);
    [self addSubview:self.textLabel];
    
    self.editPressKey = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"edit"]];
    self.editPressKey.frame = CGRectMake(0, 0, 25, 25);
    self.editPressKey.contentMode = UIViewContentModeCenter;
    self.editPressKey.backgroundColor = [UIColor grayColor];
    self.editPressKey.layer.cornerRadius = CGRectGetWidth(self.editPressKey.frame) / 2.0;
    self.editPressKey.userInteractionEnabled = YES;
    [self.editPressKey addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editText:)]];
    [self addSubview:self.editPressKey];

    self.rotatoPressKey = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rotate"]];
    self.rotatoPressKey.frame = CGRectMake(0, 0, 25, 25);
    self.rotatoPressKey.contentMode = UIViewContentModeCenter;
    self.rotatoPressKey.backgroundColor = [UIColor grayColor];
    self.rotatoPressKey.layer.cornerRadius = CGRectGetWidth(self.rotatoPressKey.frame) / 2.0;
    self.rotatoPressKey.userInteractionEnabled = YES;
    [self.rotatoPressKey addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustText:)]];
    [self addSubview:self.rotatoPressKey];
    
    UIPanGestureRecognizer *moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveText:)];
    moveGesture.minimumNumberOfTouches = 1;
    moveGesture.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:moveGesture];
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateText:)];
    rotationGesture.delegate = self;
    [self addGestureRecognizer:rotationGesture];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleText:)];
    pinchGesture.delegate = self;
    [self addGestureRecognizer:pinchGesture];
}

- (void)setCanEdit:(BOOL)canEdit {
    _canEdit = canEdit;
    self.rotatoPressKey.hidden = !_canEdit;
    self.editPressKey.hidden = !_canEdit;
    self.dashedBoarder.hidden = !_canEdit;
    self.userInteractionEnabled = _canEdit;
}

- (void)editText:(UIPanGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(filterTextView:editText:textColor:)]) {
        [self.delegate filterTextView:self editText:self.textLabel.text textColor:self.textLabel.textColor];
    }
}

- (void)adjustText:(UIPanGestureRecognizer *)sender {
    static CGPoint startTouchPoint; // 开始触碰的点
    static CGPoint startMovePoint; // 开始移动的点
    if (sender.state == UIGestureRecognizerStateBegan) {
        startTouchPoint = [sender locationInView:self.superview];
        startMovePoint = [self convertPoint:CGPointMake(sender.view.center.x, sender.view.center.y) toView:self.superview];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        // 基础数据
        CGPoint originPoint = self.center; // 中心点
        CGPoint currentTouchPoint = [sender locationInView:self.superview]; // 当前触碰的点
        CGPoint changVector = CGPointMake(currentTouchPoint.x - startTouchPoint.x, currentTouchPoint.y - startTouchPoint.y); // 改变的向量
        CGPoint currentMovePoint = CGPointMake(startMovePoint.x + changVector.x, startMovePoint.y + changVector.y); // 当前移动到的位置
        CGFloat cosValue = cos(atanf(CGRectGetHeight(self.bounds) / CGRectGetWidth(self.bounds))); // 边与边的余弦值
        
        // 旋转后的size
        CGFloat width = sqrtf(powf(currentMovePoint.x - originPoint.x, 2) + powf(currentMovePoint.y - originPoint.y, 2)) * 2 * cosValue;
        CGFloat height = width * 0.25;
        
        // 旋转后的rdaian
        CGFloat tanValue = (currentMovePoint.y - originPoint.y) / (currentMovePoint.x - originPoint.x);
        CGFloat degree = RADIAN_TO_DEGREE(atanf(tanValue));
        if (currentMovePoint.x - originPoint.x < 0) {
            degree = 180.0 + degree;
        }
        CGFloat radian = DEGREE_TO_RADIAN(degree) - acosf(cosValue);
        
        // 重绘视图
        [self setSize:CGSizeMake(width, height)];
        [self setRotation:radian reset:YES];
        [self setNeedsDisplay];
    }
}

- (void)moveText:(UIPanGestureRecognizer *)sender {
    // 重置偏移量
    CGAffineTransform oldTransForm = self.transform;
    self.transform = CGAffineTransformMakeRotation(0.0);
    CGPoint originCenter = self.center;
    self.center = CGPointMake(originCenter.x + [sender translationInView:sender.view].x, originCenter.y + [sender translationInView:sender.view].y);
    self.transform = oldTransForm;
    [sender setTranslation:CGPointMake(0, 0) inView:sender.view];
}

- (void)rotateText:(UIRotationGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
        [self setRotation:sender.rotation reset:NO];
        [sender setRotation:0];
    }
}

- (void)scaleText:(UIPinchGestureRecognizer *)sender {
    CGFloat width = CGRectGetWidth(self.bounds) * sender.scale;
    CGFloat height = width * 0.25;
    [self setSize:CGSizeMake(width, height)];
    [sender setScale:1.0];
    [self setNeedsDisplay];
}

- (void)setSize:(CGSize)size {
    if (size.width < MINWIDTH || size.width > MAXWIDTH) {
        return;
    }
    self.bounds = CGRectMake(0, 0, size.width, size.height);
}

- (void)setRotation:(CGFloat)rotaition reset:(BOOL)reset {
    if (reset) {
        self.transform = CGAffineTransformMakeRotation(rotaition);
    } else {
        self.transform = CGAffineTransformRotate(self.transform, rotaition);
    }
}

- (CAShapeLayer *)dashedBoarder {
    if (_dashedBoarder == nil) {
        _dashedBoarder = [CAShapeLayer layer];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.fromValue = @1.0;
        animation.toValue = @0.3;
        animation.autoreverses = YES;
        animation.duration = 0.5;
        animation.removedOnCompletion = NO;
        animation.repeatCount = MAXFLOAT;
        animation.fillMode = @"forwards";
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [_dashedBoarder addAnimation:animation forKey:@"opacity"];
    }
    return _dashedBoarder;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    self.dashedBoarder.bounds = self.bounds;
    self.dashedBoarder.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.dashedBoarder.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
    self.dashedBoarder.lineWidth = 2.0;
    self.dashedBoarder.lineCap = @"round";
    self.dashedBoarder.lineDashPattern = @[@3, @3];
    self.dashedBoarder.fillColor = [UIColor clearColor].CGColor;
    self.dashedBoarder.strokeColor = [UIColor whiteColor].CGColor;
    [self.layer insertSublayer:self.dashedBoarder atIndex:0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat ratio = CGRectGetWidth(self.bounds) / CGRectGetWidth(self.textLabel.frame);
    self.textLabel.transform = CGAffineTransformScale(self.textLabel.transform, ratio, ratio);
    self.textLabel.center = CGPointMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2 - 2.0);
    self.editPressKey.center = CGPointMake(CGRectGetWidth(self.bounds), 0);
    self.rotatoPressKey.center = CGPointMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}

- (void)setText:(NSString *)text {
    self.textLabel.text = text;
}

- (NSString *)text {
    return self.textLabel.text;
}

- (void)setTextColor:(UIColor *)textColor {
    self.textLabel.textColor = textColor;
}

- (UIColor *)textColor {
    return self.textLabel.textColor;
}

- (UIImage *)imageWithContrastImage:(UIImage *)image {
    CGRect newRect = [self.superview convertRect:[self convertRect:self.textLabel.frame toView:self.superview] toView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)]];

    
    UIGraphicsBeginImageContext(newRect.size);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
//    CGContextTranslateCTM (c, ty/2, tx/2);
    CGContextRotateCTM(c, M_PI/2);
//    CGContextTranslateCTM (c, -tx/2, -ty/2);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *textImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    return textImage;
}

#pragma mark 手势代理
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) {
        return YES;
    }
    if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

@end
