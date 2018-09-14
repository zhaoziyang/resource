//
//  TNFilterManager.m
//  FilterDemo
//
//  Created by zhangheng on 2017/4/25.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import "TNFilterManager.h"

/**
 滤镜种类

 - FilterTypeBrightness: 亮度
 - FilterTypeContrast: 对比度
 - FilterTypeSharpen: 锐化
 - FilterTypeSaturation: 饱和度
 - FilterTypeColorTemp: 色温
 - FilterTypeHightLight: 高光调节
 - FilterTypeShadow: 阴影
 - FilterTypeFade: 褪色
 */
typedef NS_ENUM(int, FilterType) {
    FilterTypeBrightness,
    FilterTypeContrast,
    FilterTypeSharpen,
    FilterTypeSaturation,
    FilterTypeColorTemp,
    FilterTypeHightLight,
    FilterTypeShadow,
    FilterTypeFade,
};

typedef NS_ENUM(int, SourceType) {
    SourceTypePicture,
    SourceTypeCamera
};

@implementation TNFilterManager

//- (void)initWith

@end
