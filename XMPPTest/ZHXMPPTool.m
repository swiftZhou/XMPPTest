//
//  ZHXMPPTool.m
//  XMPPTest
//
//  Created by 周海 on 16/8/10.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import "ZHXMPPTool.h"

@implementation ZHXMPPTool

@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;

static ZHXMPPTool *_instance;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [ZHXMPPTool new];
        
    });
    
    return _instance;
}
#pragma mark -初始化xmpp流
- (XMPPStream *)xmppStream{
    if (!_xmppStream) {
        _xmppStream = [XMPPStream new];
        [self.xmppStream setHostName:kXMPP_HOST];         //设置xmpp服务器地址
        [self.xmppStream setHostPort:kXMPP_PORT];         //设置xmpp端口，默认是5222
        /*
         //为什么是addDelegate? 因为xmppFramework 大量使用了多播代理multicast-delegate,
         代理一般是1对1的，但是这个多播代理是一对多得，而且可以在任意时候添加或者删除
         */
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.xmppStream setKeepAliveInterval:30]; //设置心跳包时间，默认值是2分中，最小时间是20秒
        
        self.xmppStream.enableBackgroundingOnSocket=YES; //允许xmpp在后台运行
        
        //添加功能模块
        //autoPing 发送的时一个stream:ping 对方如果想表示自己是活跃的，应该返回一个pong
        _xmppAutoPing = [[XMPPAutoPing alloc] init];
        //所有的Module模块，都要激活active
        [_xmppAutoPing activate:self.xmppStream];
        //autoPing由于它会定时发送ping,要求对方返回pong,因此这个时间我们需要设置
        [_xmppAutoPing setPingInterval:1000];
        //不仅仅是服务器来得响应;如果是普通的用户，一样会响应
        [_xmppAutoPing setRespondsToQueries:YES];
        //这个过程是C---->S  ;观察 S--->C(需要在服务器设置）
        
        
        /*
         接入断线重连模块
         自动重连，当我们被断开了，自动重新连接上去，并且将上一次的信息自动加上去
        */
        _xmppReconnect = [[XMPPReconnect alloc] init];
        [_xmppReconnect setAutoReconnect:YES];
        [_xmppReconnect activate:self.xmppStream];
        
        // 好友模块 支持我们管理、同步、申请、删除好友
        _xmppRosterMemoryStorage = [[XMPPRosterMemoryStorage alloc] init];
        _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterMemoryStorage];
        [_xmppRoster activate:self.xmppStream];
        
        //同时给_xmppRosterMemoryStorage 和 _xmppRoster都添加了代理
        [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        //设置好友同步策略,XMPP一旦连接成功，同步好友到本地
        [_xmppRoster setAutoFetchRoster:YES]; //自动同步，从服务器取出好友
        //关掉自动接收好友请求，默认开启自动同意
        [_xmppRoster setAutoAcceptKnownPresenceSubscriptionRequests:NO];
        
        
        
        // Setup roster
        //
        // The XMPPRoster handles the xmpp protocol stuff related to the roster.
        // The storage for the roster is abstracted.
        // So you can use any storage mechanism you want.
        // You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
        // or setup your own using raw SQLite, or create your own storage mechanism.
        // You can do it however you like! It's your application.
        // But you do need to provide the roster with some storage facility.
        
        _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
        //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
        
        _xmppCoreDataRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
        
        _xmppCoreDataRoster.autoFetchRoster = YES;
        _xmppCoreDataRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        
        
        // Setup vCard support
        //
        // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
        // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
        
        _xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
        xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
        xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
        
        [_xmppCoreDataRoster   activate:self.xmppStream];
        [xmppvCardTempModule   activate:self.xmppStream];
        [xmppvCardAvatarModule activate:self.xmppStream];

    }
    return _xmppStream;
}
#pragma mark -登录
- (void)loginWithJID:(XMPPJID *)JID andPassword:(NSString *)password ResponseBlock:(XMPPBlock)block{
    // 1.建立TCP连接
    // 2.把我自己的jid与这个TCP连接绑定起来
    // 3.认证（登录：验证jid与密码是否正确，加密方式 不可能以明文发送）--（：怎样告诉服务器我上线，以及我得上线状态
    //这句话会在xmppStream以后发送XML的时候加上 <message from="JID">
    [self.xmppStream setMyJID:JID];
    self.myPassword = password;
    self.xmppNeedRegister = NO;
    NSError *error = nil;
    if ([self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        
//        block(YES,nil);
        self.block = block;
    } else{
        NSLog(@"登录失败 error==%@",error);
        block(NO,error);
    }

}

#pragma mark -注册
- (void)registerWithJID:(XMPPJID *)JID andPassword:(NSString *)password ResponseBlock:(XMPPBlock)block
{
    [self.xmppStream setMyJID:JID];
    self.myPassword = password;
    self.xmppNeedRegister = YES;
    NSError *error = nil;
    
    if([self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]){
        self.block = block;
    } else{
        NSLog(@"注册失败 error==%@",error);
        block(NO,error);
    }
}



#pragma mark  -授权登录成功后，发送"在线" 消息
- (void)goOnline
{
    // 发送一个<presence/> 默认值avaliable 在线 是指服务器收到空的presence 会认为是这个
    // status ---自定义的内容，可以是任何的。
    // show 是固定的，有几种类型 dnd、xa、away、chat，在方法XMPPPresence 的intShow中可以看到
    XMPPPresence *presence = [XMPPPresence presence];
    [presence addChild:[DDXMLNode elementWithName:@"status" stringValue:@"在线"]];
    //    [presence addChild:[DDXMLNode elementWithName:@"show" stringValue:@"xa"]];
    
    [presence addChild:[DDXMLNode elementWithName:@"show" stringValue:@"chat"]];
    
    [self.xmppStream sendElement:presence];
}

/**
    ------------------XMPPStreamDelegate--------------------
 **/
#pragma mark -授权成功 //登录成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self goOnline];
    self.block(YES,nil);
}

#pragma mark -授权失败 //登录失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    NSLog(@"登录失败%s",__func__);
}

#pragma mark -socket 连接建立成功
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    NSLog(@"连接建立成功 %s",__func__);
}

#pragma mark -与主机连接成功 //这个是xml流 初始化成功
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    //连接成功后发送密码验证

    if (self.xmppNeedRegister) {
        //验证注册密码
        NSError *error;
        if([self.xmppStream registerWithPassword:self.myPassword error:&error]){
            //验证成功
            self.block(YES,nil);
        } else{
            //验证失败
            self.block(YES,error);
        }
            
        
    } else {
        //验证登录密码
        [self.xmppStream authenticateWithPassword:self.myPassword error:nil];
    }
}
#pragma mark  -与主机断开连接
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"与主机断开连接 %@",error);
}



/**
    -------------XMPPRosterDelegate--------------------
 **/
#pragma mark -开始同步服务器发送过来的自己的好友列表
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender
{
    
}

#pragma mark -同步结束,收到好友列表IQ会进入的方法，并且已经存入我的存储器
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    [self.delegate  friendsStataChange];
}

#pragma mark -收到每一个好友
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    
}

#pragma mark -如果不是初始化同步来的roster,那么会自动存入我的好友存储器
- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
    [self.delegate  friendsStataChange];
}



#pragma mark - Message
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    
    // NSLog(@"%s--%@",__FUNCTION__, message);
    //XEP--0136 已经用coreData实现了数据的接收和保存
    
    NSString *msg = [[message elementForName:@"body"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    NSRange range = [from rangeOfString:@"@"];

    NSString *str = [from substringToIndex:range.location];
    
    NSString *type = [[message attributeForName:@"type"] stringValue];

    if (!msg) return;
    
//    JSQMessage *newMessage = nil;
//    
//    newMessage = [JSQMessage messageWithSenderId:from
//                                     displayName:str
//                                            text:msg];
    
    if ([type isEqualToString:@"chat"]) {
        NSString *messstr = [NSString stringWithFormat:@"%@:%@",str,msg];
        [self.messageDelegate newMessageReceived:messstr];
    }else{
        NSString *userJID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userJID"];
        NSRange range = [from rangeOfString:@"/"];
        NSString *str = [from substringFromIndex:range.location+1];
        NSString *messstr;
        if ([userJID hasPrefix:str]) {
            messstr = [NSString stringWithFormat:@"我:%@",msg];
        } else{
            messstr = [NSString stringWithFormat:@"%@:%@",str,msg];
        }
        
        [self.messageDelegate newMessageReceived:messstr];
    }

    
    
}


#pragma mark ===== 好友模块 委托=======
/** 收到出席订阅请求（代表对方想添加自己为好友) */
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    //添加好友一定会订阅对方，但是接受订阅不一定要添加对方为好友
    self.receivePresence = presence;
    
    NSString *message = [NSString stringWithFormat:@"【%@】想加你为好友",presence.from.bare];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"同意", nil];
    [alertView show];
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    //收到对方取消定阅我得消息
    if ([presence.type isEqualToString:@"unsubscribe"]) {
        //从我的本地通讯录中将他移除
        [self.xmppRoster removeUser:presence.from];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:_receivePresence.from];
    } else {
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:_receivePresence.from andAddToRoster:YES];
    }
}

#pragma mark - 获取群聊
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    NSMutableArray *array = [NSMutableArray array];
    for (DDXMLElement *element in iq.children) {
        if ([element.name isEqualToString:@"query"]) {
            for (DDXMLElement *item in element.children) {
                if ([item.name isEqualToString:@"item"]) {
                    [array addObject:item.attributes];          //array  就是你的群列表
                
                
                }
            }
        }
    }
    [self.delegate getHomeChatList:array];
    return YES;
}
@end
