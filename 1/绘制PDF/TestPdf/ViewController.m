//
//  ViewController.m
//  TestPdf
//
//  Created by Admin on 2018/5/24.
//  Copyright © 2018年 Wellim. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
/*
 * 获取pdf绘图上下文
 * inMediaBox指定pdf页面大小
 * path指定pdf文件保存的路径
 */
CGContextRef MyPDFContextCreate (const CGRect *inMediaBox, CFStringRef path)
{
    CGContextRef myOutContext = NULL;
    CFURLRef url;
    CGDataConsumerRef dataConsumer;
    
    url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, false);
    
    if (url != NULL)
    {
        dataConsumer = CGDataConsumerCreateWithURL(url);
        if (dataConsumer != NULL)
        {
            myOutContext = CGPDFContextCreate (dataConsumer, inMediaBox, NULL);
            CGDataConsumerRelease (dataConsumer);
        }
        CFRelease(url);
    }
    return myOutContext;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1.创建media box
    CGFloat myPageWidth = self.view.bounds.size.width;
    CGFloat myPageHeight = self.view.bounds.size.height;
    CGRect mediaBox = CGRectMake (0, 0, myPageWidth, myPageHeight);
    
    
    // 2.设置pdf文档存储的路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSLog(@"%@",documentsDirectory);
    NSString *filePath = [documentsDirectory stringByAppendingString:@"/test.pdf"];
    // NSLog(@"%@", filePath);
    const char *cfilePath = [filePath UTF8String];
    CFStringRef pathRef = CFStringCreateWithCString(NULL, cfilePath, kCFStringEncodingUTF8);
    
    
    // 3.设置当前pdf页面的属性
    CFStringRef myKeys[3];
    CFTypeRef myValues[3];
    myKeys[0] = kCGPDFContextMediaBox;
    myValues[0] = (CFTypeRef) CFDataCreate(NULL,(const UInt8 *)&mediaBox, sizeof (CGRect));
    myKeys[1] = kCGPDFContextTitle;
    myValues[1] = CFSTR("我的PDF");
    myKeys[2] = kCGPDFContextCreator;
    myValues[2] = CFSTR("Jymn_Chen");
    CFDictionaryRef pageDictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,
                                                        &kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    
    
    // 4.获取pdf绘图上下文
    CGContextRef myPDFContext = MyPDFContextCreate (&mediaBox, pathRef);
    
    
    // 5.开始描绘第一页页面
    CGPDFContextBeginPage(myPDFContext, pageDictionary);
    CGContextSetRGBFillColor (myPDFContext, 1, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 200, 100 ));
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 1, .5);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 100, 200 ));
    
    // 为一个矩形设置URL链接www.baidu.com
    CFURLRef baiduURL = CFURLCreateWithString(NULL, CFSTR("http://www.baidu.com"), NULL);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (200, 200, 100, 200 ));
    CGPDFContextSetURLForRect(myPDFContext, baiduURL, CGRectMake (200, 200, 100, 200 ));
    
    // 为一个矩形设置一个跳转终点
    CGPDFContextAddDestinationAtPoint(myPDFContext, CFSTR("page"), CGPointMake(120.0, 400.0));
    CGPDFContextSetDestinationForRect(myPDFContext, CFSTR("page"), CGRectMake(50.0, 300.0, 100.0, 100.0)); // 跳转点的name为page
    //    CGPDFContextSetDestinationForRect(myPDFContext, CFSTR("page2"), CGRectMake(50.0, 300.0, 100.0, 100.0)); // 跳转点的name为page2
    CGContextSetRGBFillColor(myPDFContext, 1, 0, 1, 0.5);
    CGContextFillEllipseInRect(myPDFContext, CGRectMake(50.0, 300.0, 100.0, 100.0));
    
    CGPDFContextEndPage(myPDFContext);
    
    
    // 6.开始描绘第二页页面
    // 注意要另外创建一个page dictionary
    CFDictionaryRef page2Dictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,
                                                         &kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CGPDFContextBeginPage(myPDFContext, page2Dictionary);
    
    // 在左下角画两个矩形
    CGContextSetRGBFillColor (myPDFContext, 1, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 200, 100 ));
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 1, .5);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 100, 200 ));
    
    // 在右下角写一段文字:"Page 2"
    CGContextSelectFont(myPDFContext, "STHeitiSC-Light", 30, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode (myPDFContext, kCGTextFill);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    const char *text = [@"Page 2" UTF8String];
    CGContextShowTextAtPoint (myPDFContext, 120, 80, text, strlen(text));
    //    CGPDFContextAddDestinationAtPoint(myPDFContext, CFSTR("page2"), CGPointMake(120.0, 120.0));  // 跳转点的name为page2
    //    CGPDFContextAddDestinationAtPoint(myPDFContext, CFSTR("page"), CGPointMake(120.0, 120.0)); // 跳转点的name为page
    
    // 为右上角的矩形设置一段file URL链接，打开本地文件
    NSURL *furl = [NSURL fileURLWithPath:@"/Users/one/Library/Application Support/iPhone Simulator/7.0/Applications/3E7CB341-693A-4FE4-8FE5-A827A5210F0A/Documents/test1.pdf"];
    CFURLRef fileURL = (__bridge CFURLRef)furl;
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (200, 200, 100, 200 ));
    CGPDFContextSetURLForRect(myPDFContext, fileURL, CGRectMake (200, 200, 100, 200 ));
    
    CGPDFContextEndPage(myPDFContext);
    
    
    // 7.创建第三页内容
    CFDictionaryRef page3Dictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,
                                                         &kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CGPDFContextBeginPage(myPDFContext, page3Dictionary);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGPDFContextEndPage(myPDFContext);
    
    
    // 8.释放创建的对象
    CFRelease(page3Dictionary);
    CFRelease(page2Dictionary);
    CFRelease(pageDictionary);
    CFRelease(myValues[0]);
    CGContextRelease(myPDFContext);
}


@end
