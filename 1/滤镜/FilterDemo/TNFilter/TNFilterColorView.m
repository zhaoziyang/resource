//
//  TNFilterColorView.m
//  FilterDemo
//
//  Created by zhangheng on 2017/4/25.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import "TNFilterColorView.h"
#import <Masonry/Masonry.h>

@interface TNFilterColorView()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray<UIColor *> *dataSource;
@property (nonatomic, strong) NSIndexPath *selectedIndex;

@end

@implementation TNFilterColorView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.flowLayout.itemSize = CGSizeMake(CGRectGetWidth(self.frame) / 9, CGRectGetHeight(self.frame));
    self.flowLayout.minimumLineSpacing = 0.0;
    self.flowLayout.minimumInteritemSpacing = 0.0;
    [self.collectionView reloadData];
    self.collectionView.frame = self.bounds;
}

- (UICollectionViewFlowLayout *)flowLayout {
    if (_flowLayout == nil) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        [self addSubview:_collectionView];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    _collectionView.backgroundColor = self.backgroundColor;
    return _collectionView;
}

- (NSArray<UIColor *> *)dataSource {
    if (_dataSource == nil) {
        _dataSource = @[[UIColor blackColor],
                        [UIColor colorWithRed:199.0/255.0 green:192.0/255.0 blue:62.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:197.0/255.0 green:138.0/255.0 blue:56.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:197.0/255.0 green:48.0/255.0 blue:51.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:194.0/255.0 green:68.0/255.0 blue:126.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:132.0/255.0 green:55.0/255.0 blue:196.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:48.0/255.0 green:66.0/255.0 blue:196.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:55.0/255.0 green:171.0/255.0 blue:197.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:56.0/255.0 green:197.0/255.0 blue:69.0/255.0 alpha:1.0]];
    }
    return _dataSource;
}

- (NSIndexPath *)selectedIndex {
    if (_selectedIndex == nil) {
        _selectedIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return _selectedIndex;
}

- (void)setDefaultColor:(UIColor *)defaultColor {
    if (defaultColor != nil) {
        for (UIColor *color in self.dataSource) {
            if (CGColorEqualToColor(defaultColor.CGColor, color.CGColor)) {
                self.selectedIndex = [NSIndexPath indexPathForRow:[self.dataSource indexOfObject:color] inSection:0];
                break;
            }
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UILabel *selectedLabel = [cell.contentView viewWithTag:1001];
    UILabel *colorLabel = [cell.contentView viewWithTag:1002];
    if (selectedLabel == nil || colorLabel == nil) {
        selectedLabel = [[UILabel alloc] init];
        selectedLabel.layer.cornerRadius = 24.0 / 2.0;
        selectedLabel.layer.borderWidth = 2.5;
        selectedLabel.layer.masksToBounds = YES;
        selectedLabel.tag = 1001;
        [cell.contentView addSubview:selectedLabel];
        [selectedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell.contentView.mas_centerY);
            make.centerX.equalTo(cell.contentView.mas_centerX);
            make.width.mas_equalTo(24.0);
            make.height.mas_equalTo(24.0);
        }];
        
        colorLabel = [[UILabel alloc] init];
        colorLabel.layer.masksToBounds = YES;
        colorLabel.tag = 1002;
        [cell.contentView addSubview:colorLabel];
        [colorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell.contentView.mas_centerY);
            make.centerX.equalTo(cell.contentView.mas_centerX);
        }];
    }
    selectedLabel.backgroundColor = self.backgroundColor;
    selectedLabel.layer.borderColor = self.dataSource[indexPath.row].CGColor;
    colorLabel.backgroundColor = self.dataSource[indexPath.row];
    
    for (UIView *view in colorLabel.subviews) {
        [view removeFromSuperview];
    }
    
    if (self.selectedIndex.row == indexPath.row) {
        selectedLabel.hidden = NO;
        colorLabel.layer.cornerRadius = 10.0 / 2.0;
        [colorLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(10.0);
            make.height.mas_equalTo(10.0);
        }];
    } else {
        selectedLabel.hidden = YES;
        colorLabel.layer.cornerRadius = 15.0 / 2.0;
        [colorLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(15.0);
            make.height.mas_equalTo(15.0);
        }];
        if (indexPath.row == 0) {
            UIView *none = [[UIView alloc] init];
            none.backgroundColor = [UIColor whiteColor];
            [colorLabel addSubview:none];
            [none mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(colorLabel.mas_top).offset(2.0);
                make.bottom.equalTo(colorLabel.mas_bottom).offset(-2.0);
                make.width.mas_equalTo(0.5);
                make.centerX.mas_equalTo(colorLabel.mas_centerX);
            }];
            none.transform = CGAffineTransformMakeRotation (M_PI_4);
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectedIndex compare:indexPath] != NSOrderedSame) {
        self.selectedIndex = indexPath;
        [self.collectionView reloadData];
        if ([self.delegate respondsToSelector:@selector(filterColorView:didSelectedColor:)]) {
            [self.delegate filterColorView:self didSelectedColor:self.selectedIndex.row == 0 ? [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] : self.dataSource[self.selectedIndex.row]];
        }
    }
}

@end
