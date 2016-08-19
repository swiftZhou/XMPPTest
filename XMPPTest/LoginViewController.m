//
//  LoginViewController.m
//  XMPPTest
//
//  Created by 周海 on 16/8/9.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import "LoginViewController.h"
#import "FriendsViewController.h"
#import "ZHXMPPTool.h"
@interface LoginViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTestField;
@property (weak, nonatomic) IBOutlet UITextField *passWordTestField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
#pragma makr -点击登录
- (IBAction)loginBut:(UIButton *)sender {
    NSString *username = _userNameTestField.text;
    NSString *password = _passWordTestField.text;
    
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
        [[ZHXMPPTool sharedInstance] loginWithJID:jid andPassword:password ResponseBlock:^(BOOL result, NSError *error) {
            if (result) {
                //登录成功
                NSLog(@"登录成功");
                FriendsViewController *friendsVC = [[FriendsViewController alloc] init];
                [weakSelf.navigationController pushViewController:friendsVC animated:YES];
                
                NSString *jid = [NSString stringWithFormat:@"%@@%@",username,bXMPP_domain];
                [[NSUserDefaults standardUserDefaults] setValue:jid forKey:@"userJID"];
                
            } else{
                //登录失败
                NSLog(@"登录失败error=%@",error);
            }
            
        }];
        
    }
}
#pragma makr -注册
- (IBAction)registeredBut:(UIButton *)sender{
    [self performSegueWithIdentifier:@"registerd" sender:self];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
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
