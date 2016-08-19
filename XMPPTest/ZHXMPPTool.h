//
//  ZHXMPPTool.h
//  XMPPTest
//
//  Created by 周海 on 16/8/10.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "JSQMessage.h"
@protocol ZHXMPPToolFriendsStataDelegate <NSObject>
//主要用来监测好友组变化，上线/下线
- (void)friendsStataChange;

//用来传群聊房间列表
-(void)getHomeChatList:(NSArray *)homesArray;
@end

@protocol ZHMessageDelegate <NSObject>

-(void)newMessageReceived:(id)messageContent;


@end




typedef void (^XMPPBlock)(BOOL result, NSError * error);

@interface ZHXMPPTool : NSObject<XMPPStreamDelegate,XMPPRosterDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) XMPPStream *xmppStream;

// 模块
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPAutoPing *xmppAutoPing;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRoster * xmppCoreDataRoster;
@property (nonatomic, strong) XMPPRosterMemoryStorage *xmppRosterMemoryStorage;
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;

@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;

@property (nonatomic, strong) XMPPPresence *receivePresence;

@property (nonatomic, assign) BOOL  xmppNeedRegister; //用来判断是注册/登录
@property (nonatomic, copy)   NSString *myPassword;

@property (nonatomic, copy) XMPPBlock block;


//ZHXMPPToolDelegate
@property (nonatomic, weak) id<ZHXMPPToolFriendsStataDelegate> delegate;
@property (nonatomic, weak) id<ZHMessageDelegate> messageDelegate;

+ (instancetype)sharedInstance;

//登录方法
- (void)loginWithJID:(XMPPJID *)JID andPassword:(NSString *)password ResponseBlock:(XMPPBlock)block;

//注册方法
- (void)registerWithJID:(XMPPJID *)JID andPassword:(NSString *)password ResponseBlock:(XMPPBlock)block;

@end




