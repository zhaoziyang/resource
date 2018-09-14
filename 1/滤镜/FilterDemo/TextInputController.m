//
//  TextInputController.m
//  FilterDemo
//
//  Created by zhangheng on 2017/4/27.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

#import "TextInputController.h"
#import "TNFilterColorView.h"

@interface TextInputController ()<TNFilterColorViewDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet TNFilterColorView *filterColor;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorSelectBottom;
@end

@implementation TextInputController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.filterColor.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillHideNotification object:nil];
    [self.textView becomeFirstResponder];
    self.textView.delegate = self;
    self.textView.text = self.text;
    self.textView.textColor = self.textColor == nil ? [UIColor whiteColor] : self.textColor;
    self.filterColor.defaultColor = self.textColor;
}

- (void)keyboardShow:(NSNotification *)notification {
    self.colorSelectBottom.constant = CGRectGetHeight([[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]);
    [UIView animateWithDuration:[[notification.userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue] animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardHide:(NSNotification *)notification {
    self.colorSelectBottom.constant = 0.0;
    [UIView animateWithDuration:[[notification.userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue] animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)dismiss:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)confirm:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.result) {
        self.result(self.textView.text, self.textView.textColor);
    }
}

- (void)filterColorView:(TNFilterColorView *)filterColorView didSelectedColor:(UIColor *)color {
    self.textView.textColor = color;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        [self confirm:nil];
        return NO;
    }
    return YES;
}

@end
