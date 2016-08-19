//
//  TestMessagesViewController.h
//  XMPPTest
//
//  Created by 周海 on 16/8/11.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "JSQMessages.h"
//#import "BBModelData.h"
#import "ZHXMPPTool.h"
@interface TestMessagesViewController : UIViewController
@property (nonatomic, strong) XMPPJID *chatJID;
@property (nonatomic, copy) NSString *roomJID;
@property (nonatomic, copy) NSString *chatName;
@end
