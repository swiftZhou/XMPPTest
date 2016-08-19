//
//  RegisteredViewController.m
//  XMPPTest
//
//  Created by 周海 on 16/8/9.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import "RegisteredViewController.h"
#import "ZHXMPPTool.h"
@interface RegisteredViewController ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTestField;
@property (weak, nonatomic) IBOutlet UITextField *userPassWordTestField;

@end

@implementation RegisteredViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
#pragma mark -注册
- (IBAction)registeredBut:(UIButton *)sender {
    
    NSString *username = _userNameTestField.text;
    NSString *password = _userPassWordTestField.text;
    
    NSString *message = nil;
    if (username.length <= 0) {
        message = @"用户名未填写";
    } else if (password.length <= 0) {
        message = @"密码未填写";
    }
    if (message.length > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil];
        [alertView show];
    } else {
        WS(weakSelf)
        XMPPJID *jid = [XMPPJID jidWithUser:username domain:bXMPP_domain resource:bXMPP_resource];
        [[ZHXMPPTool sharedInstance] registerWithJID:jid andPassword:password ResponseBlock:^(BOOL result, NSError *error) {
            if (result) {
                //注册成功
                NSLog(@"注册成功");
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"注册成功" message:message delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alertView show];
            } else{
                //注册失败
                NSLog(@"注册失败error=%@",error);
            }
            
        }];
        
    }
}
#pragma mark -取消注册
- (IBAction)cancel:(UIButton*)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex NS_DEPRECATED_IOS(2_0, 9_0){
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)hideBlackBoard
{
    [self.view endEditing:YES];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self hideBlackBoard];
    
    return YES;
}

@end
