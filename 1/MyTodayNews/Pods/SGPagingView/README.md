
# SGPagingView


## 目录
* [效果图](#效果图)

* [主要内容的介绍](#主要内容的介绍)

* [SGPagingView集成](#SGPagingView集成)

* [代码介绍](#代码介绍)

* [问题及解决方案](#问题及解决方案)

* [版本介绍](#版本介绍)

* [Concludingremarks](#Concludingremarks)

* [简书介绍](http://www.jianshu.com/p/16b0356d6ac6)


## 效果图
![](https://github.com/kingsic/SGPagingView/raw/master/Gif/sorgle.gif) 


## 主要内容的介绍
* `指示器长度自定义`<br>

* `指示器遮盖样式`<br>

* `指示器下划线样式`<br>

* `多种指示器滚动样式`<br>

* `标题按钮文字渐显效果`<br>

* `标题按钮文字缩放效果`<br>


## SGPagingView 集成
* 1、CocoaPods 导入 pod 'SGPagingView', '~> 1.3.2'
* 2、下载、拖拽 “SGPagingView” 文件夹到工程中


## 代码介绍
#### SGPagingView 的使用（详细使用, 请参考 Demo）
``` 
    /// pageTitleView 
    SGPageTitleViewConfigure *configure = [SGPageTitleViewConfigure pageTitleViewConfigure];
    
    self.pageTitleView = [SGPageTitleView pageTitleViewWithFrame:frame delegate:self titleNames:titleNames configure:configure];
    [self.view addSubview:_pageTitleView];
    
    
    /// pageContentView
    self.pageContentView = [[SGPageContentView alloc] initWithFrame:frame parentVC:self childVCs:childVCs];
    _pageContentView.delegatePageContentView = self;
    [self.view addSubview:_pageContentView];
```

* 滚动内容视图的代理方法
```
- (void)pageContentView:(SGPageContentView *)pageContentView progress:(CGFloat)progress originalIndex:(NSInteger)originalIndex targetIndex:(NSInteger)targetIndex {
    [self.pageTitleView setPageTitleViewWithProgress:progress originalIndex:originalIndex targetIndex:targetIndex];
}
```

* 滚动标题视图的代理方法
```
- (void)pageTitleView:(SGPageTitleView *)pageTitleView selectedIndex:(NSInteger)selectedIndex {
    [self.pageContentView setPageCententViewCurrentIndex:selectedIndex];
}
```


#### SGPagingView 的介绍
|主要属性、方法|描述|
|----|-----|
|**selectedIndex**|选中标题下标|
|**resetSelectedIndex**|重置标题下标|
|**titleFont**|标题文字字号大小，默认 15 号字体|
|**titleColor**|普通状态下标题按钮文字的颜色，默认为黑色|
|**titleSelectedColor**|选中状态下标题按钮文字的颜色，默认为红色|
|**indicatorColor**|指示器颜色，默认为红色|
|**indicatorStyle**|指示器样式，默认为下划线样式；下划线、遮盖样式|
|**indicatorHeight**|指示器高度；下划线样式下默认为 2.f，遮盖样式下，默认为标题文字的高度，若大于 SGPageTitleView，则高度为 SGPageTitleView 高度，下划线样式未做处理|
|**indicatorCornerRadius**|遮盖样式下圆角属性，默认为 0.f；若圆角大于 1/2 指示器高度，则圆角大小为 1/2 指示器高度|
|**indicatorAdditionalWidth**|指示器的额外宽度，默认为 0.f，介于按钮文字宽度与按钮宽度之间；若大于按钮的宽度，则为按钮的宽度|
|**spacingBetweenButtons**|按钮之间的间距，默认 20.f|
|**indicatorScrollStyle**|指示器滚动样式|
|**resetTitleWithIndex:newTitle:**|更改指定下标的标题|
|**initWithFrame:delegate:titleNames:titleFont:**|带有标题字号的初始化方法，与之对应一个类方法|


## 问题及解决方案
#### 1、CocoaPods 安装 SGPagingView 时，遇到的问题及解决方案
* 若在使用 CocoaPods 安装 SGPagingView 时，出现 [!] Unable to find a specification for SGPagingView 提示时，打开终端先输入 pod repo remove master；执行完毕后再输入 pod setup 即可 (可能会等待一段时间)
***

#### 2、关于父子控制器的说明（SGPageContentView 与 SGPageContentScrollView）
> **SGPageContentView 使用的是 UICollectionView 的重用机制管理子视图
内部是先添加子视图控制器到父视图控制器上（[self.parentViewController addChildViewController:childVC]），再添加子视图的 view 到父视图的 view 上的（[cell.contentView addSubview:childVC.view]），这时会存在一个问题：即第一次加载第一个子视图时，第一个子视图的 viewWillAppear 方法不会被调用；原因是，先调用 addChildViewController，子视图控制器与父视图控制器的事件同步，即当父视图控制器的 viewDidAppear 调用时，子视图控制器的 viewDidAppear 方法会调用一次，再调用 addSubView 也不会触发viewWillAppear 和 viewDidAppear；所以第一次加载子视图控制器时 viewWillAppear 不会被调用，再去加载其他子视图控制器不会出现这种问题了。说明：针对这种情况网络数据请求建议在 viewDidLoad 或 viewDidAppear 中作处理**

> **SGPageContentScrollView 使用的是 UIScrollView 拖拽结束后的方法加载子视图
内部是先添加子视图的 view 到父视图的 view 上的（[self.scrollView addSubview:childVC.view]），再添加子视图控制器到父视图控制器上（[self.parentViewController addChildViewController:childVC]），这时会存在一个问题：即第一次加载第一个子视图时，第一个子视图的 viewDidAppear 方法会调用二次；原因是，先调用 addSubView 时，viewWillAppear 和 viewDidAppear 会各调用一次，再 addChildViewController 时，子视图控制器与父视图控制器的事件同步，即当父视图控制器的 viewDidAppear 调用时，子视图控制器的 viewDidAppear 方法会再调用一次；所以第一次加载的子视图控制器时 viewDidAppear 方法会被调用两次，再去加载其他子视图控制器不会出现这种问题。说明：针对这种情况网络请求数据建议在 viewWillAppear 或 viewDidLoad 中作处理**
***


## 版本介绍

* 2016-10-07 ：初始版本的创建

* 2017-04-13 ：版本升级（根据标题内容自动识别 SGPageTitleView 是静止还是滚动）

* 2017-05-12 ：SGPageContentView 新增是否需要滚动属性

* 2017-06-01 ：v1.1.0 解决标题中既有中文又有英文存在的 Bug 以及性能优化

* 2017-06-15 ：v1.1.5 新增新浪微博模块以及代码的优化

* 2017-07-21 ：v1.1.7 新增 SGPageContentScrollView 类以及加入 pods 管理

* 2017-08-11 ：v1.2.0 新增指示器滚动样式

* 2017-10-17 ：v1.3.0 版本升级（新增 SGPageTitleViewConfigure 类，提供更多的属性设置以及支持指示器遮盖样式）

* 2017-10-28 ：v1.3.2 SGPageTitleViewConfigure 类新增指示器遮盖样式下的边框宽度及边框颜色属性


## Concluding remarks

* 如在使用中, 遇到什么问题或有更好建议者, 请记得 [Issues me](https://github.com/kingsic/SGPagingView/issues) 或 kingsic@126.com 邮箱联系我

