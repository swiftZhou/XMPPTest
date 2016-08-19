//
//  TestMessagesViewController.m
//  XMPPTest
//
//  Created by 周海 on 16/8/11.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import "TestMessagesViewController.h"
#import <Masonry/Masonry.h>
#import "ZHXMPPTool.h"
#import <UIImageView+WebCache.h>
#import "XMPPRoom.h"
#import "XMPPRoomCoreDataStorage.h"
@interface TestMessagesViewController()<UITableViewDataSource,UITableViewDelegate,ZHMessageDelegate,UITextFieldDelegate,XMPPRoomDelegate>
@property (nonatomic, strong) UITableView *chatTableview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIView *bView;
@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) XMPPRoom *xmppRoom;
@property (strong, nonatomic) XMPPRoomCoreDataStorage *xmppRoomStorage;

@end
@implementation TestMessagesViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = _chatName;
    self.messages = [NSMutableArray array];
    [ZHXMPPTool sharedInstance].messageDelegate = self;
    [self createTableview];
    [self createTextFired];
    
    //注册键盘出现的通知
    
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(keyboardWasShown:)
     
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    //注册键盘消失的通知
    
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(keyboardWillBeHidden:)
     
                                                 name:UIKeyboardWillHideNotification object:nil];
    if (self.roomJID>0) {
        [self initxmpproom];
    }
    
   
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (self.roomJID >0) {
        //退出群聊
        [self quitChatRoom:self.roomJID];
    }
}
#pragma mark 初始化聊天室
-(void)initxmpproom{
    _xmppRoomStorage  = [XMPPRoomCoreDataStorage sharedInstance];
    XMPPJID *roomJID = [XMPPJID jidWithString:self.roomJID];
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:roomJID];
    [_xmppRoom activate:[ZHXMPPTool sharedInstance].xmppStream];
    [_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
//    //加入房间
    [self joinroom];
}

#pragma mark 加入房间
-(void)joinroom{
    NSString *userJID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userJID"];
    [self.xmppRoom joinRoomUsingNickname:userJID history:nil];
    
}

#pragma mark -退出群聊
-(void)quitChatRoom:(NSString *)roomJid{
    NSString *userJID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userJID"];
    NSString* memberJid=[NSString stringWithFormat:@"%@/%@",roomJid,userJID];
    XMPPPresence* presence=[XMPPPresence presenceWithType:@"unavailable"];
    [presence addAttributeWithName:@"from" stringValue:userJID];
    [presence addAttributeWithName:@"to" stringValue:memberJid];
    [[ZHXMPPTool sharedInstance].xmppStream sendElement:presence];
}
-(void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID{
    NSLog(@"群发言了。。。。");
    
    NSString *type = [[message attributeForName:@"type"] stringValue];
    if ([type isEqualToString:@"groupchat"]) {
        NSString *msg = [[message elementForName:@"body"] stringValue];
        NSString *from = [[message attributeForName:@"from"] stringValue];
        
        //消息委托
         NSLog(@"消息 ===%@",msg);
    }
    
}
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSLog(@"新人加入群聊");
    NSLog(@"occupantJID加==%@",occupantJID);
    NSLog(@"presence加==%@",presence);
}
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSLog(@"有人退出群聊");
    NSLog(@"occupantJID退==%@",occupantJID);
    NSLog(@"presence退==%@",presence);
}
- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSLog(@"occupantJID更新==%@",occupantJID);
    NSLog(@"presence更新==%@",presence);
}


//发送群消息
- (void)sendPress:(NSString *)groupChat{
    //本地输入框中的信息
    NSString *message = groupChat;
    NSString *userJID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userJID"];
    
    if (message.length > 0){
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:message];
        
        //生成XML消息文档
        NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
        
        //消息类型
        [mes addAttributeWithName:@"type" stringValue:@"groupchat"];
        
        //发送给谁
        [mes addAttributeWithName:@"to" stringValue:self.roomJID];
        
        //由谁发送
        [mes addAttributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@/%@",self.roomJID,userJID]];
        
        //组合
        [mes addChild:body];
        
        //发送消息
        [[ZHXMPPTool sharedInstance].xmppStream sendElement:mes];
        
    }
}
- (void)createTextFired{
    
    self.bView = [[UIView alloc]init];
    self.bView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_bView];
    [_bView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset( 0);
        make.height.mas_equalTo(40);
    }];
    
    
    self.textField = [UITextField new];
    _textField.delegate = self;
    _textField.font = [UIFont systemFontOfSize:14.0];
    _textField.placeholder = @"输入要发送的消息";
    [_bView addSubview:_textField];
    [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(5);
        make.top.equalTo(_bView);
        make.right.equalTo(_bView).offset(-45);
        make.bottom.equalTo(_bView);
    }];
    
    UIButton *button = [UIButton new];
    button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"发送" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(sentMessage) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_bView addSubview:button];
    
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.bottom.equalTo(_bView);
        make.width.mas_equalTo(40);
        make.right.equalTo(_bView).offset(5);
    }];
}
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    //键盘高度
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [_bView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-keyBoardFrame.size.height);
        make.height.mas_equalTo(40);
    }];
    [super updateViewConstraints];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [self.view endEditing:YES];
    return YES;
}

-(void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [_bView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.mas_equalTo(40);
    }];
    [super updateViewConstraints];
}
#pragma makr -创建聊天TableView
- (void)createTableview{
    self.chatTableview = [UITableView new];
    _chatTableview.delegate = self;
    _chatTableview.dataSource = self;
    _chatTableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_chatTableview];
    [_chatTableview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0);
        make.right.left.bottom.equalTo(self.view);
    }];
    
}
-(void)sentMessage{
    [self sendMessage:self.textField.text];
    [self.view endEditing:YES];
}
#pragma mark - 收到消息
-(void)newMessageReceived:(id)messageContent{
    [self.messages addObject:messageContent];
    
    [self.chatTableview reloadData];
    
    
}
#pragma mark - 发送消息
- (void)sendMessage:(NSString *)message{
    if (self.roomJID.length >0) {
        [self sendPress:message];
    } else{
   
    XMPPMessage *XMPPmessage = [XMPPMessage messageWithType:@"chat" to:self.chatJID];
    [XMPPmessage addBody:message];
    [[ZHXMPPTool sharedInstance].xmppStream sendElement:XMPPmessage];
     NSString *string = [NSString stringWithFormat:@"我:%@",message];
    [self.messages addObject:string];
    [self.chatTableview reloadData];
    _textField.text = @"";
    }
}

#pragma mark -tableviewDelegate-----
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *testCellIdentfriead = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:testCellIdentfriead];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:testCellIdentfriead];
    }
    NSString *messageStr = self.messages[indexPath.row];
    if ([messageStr hasSuffix:@".jpg"]) {
        NSString *str =  [messageStr substringFromIndex:9];
        NSURL *url = [NSURL URLWithString:str];
        [cell.imageView sd_setImageWithURL:url];
    }
    cell.textLabel.text = self.messages[indexPath.row];
    return cell;
}

@end
