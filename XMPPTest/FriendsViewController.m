//
//  FriendsViewController.m
//  XMPPTest
//
//  Created by 周海 on 16/8/11.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#import "FriendsViewController.h"
#import "ZHXMPPTool.h"
#import <Masonry/Masonry.h>
#import "TestMessagesViewController.h"
#import <XMPPRoom.h>
#import <XMPPStream.h>
@interface FriendsViewController()<UITableViewDataSource,UITableViewDelegate,ZHXMPPToolFriendsStataDelegate,XMPPRoomDelegate>
@property (nonatomic, strong) UITableView *friendListTable;
@property (nonatomic, strong) NSMutableArray *contactsArr; // 联系人数组
@property (nonatomic, strong) NSMutableArray *homeList;           // 群聊房间列表
@property (strong, nonatomic) XMPPRoom *xmppRoom;
@end
static NSString *friendCellIdentfriead = @"cell";
@implementation FriendsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.homeList = [NSMutableArray array];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"联系人";
    
    [self createUI];
    [ZHXMPPTool sharedInstance].delegate = self;
    
    NSString *userJID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userJID"];
   
   
    //向xmpp发送一个iq请求,获取群聊房间列表
    NSXMLElement *queryElement= [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/disco#items"];
    NSXMLElement *iqElement = [NSXMLElement elementWithName:@"iq"];
    [iqElement addAttributeWithName:@"type" stringValue:@"get"];
    [iqElement addAttributeWithName:@"from" stringValue:userJID];
    [iqElement addAttributeWithName:@"to" stringValue:@"conference.zhouhai.local"];
    [iqElement addAttributeWithName:@"id" stringValue:@"getexistroomid"];
    [iqElement addChild:queryElement];
    [[ZHXMPPTool sharedInstance].xmppStream sendElement:iqElement];
}



- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.hidesBackButton = YES;
}
#pragma mark -CreateUI
- (void)createUI{
    self.friendListTable = [UITableView new];
    _friendListTable.delegate = self;
    _friendListTable.dataSource = self;
    _friendListTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    _friendListTable.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_friendListTable];
    [_friendListTable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0);
        make.right.left.bottom.equalTo(self.view);
    }];
}
#pragma mark -ZHXMPPToolFriendsStataDelegate-----
- (void)friendsStataChange{
    //从存储器中取出我得好友数组，更新数据源
    self.contactsArr = [NSMutableArray arrayWithArray:[ZHXMPPTool sharedInstance].xmppRosterMemoryStorage.unsortedUsers];
    [self.friendListTable reloadData];
}

#pragma mark - 获取群聊列表
-(void)getHomeChatList:(NSArray *)homesArray{
//    [self.homeList addObjectsFromArray:homesArray];
    
    for (NSArray *data  in homesArray){
        NSLog(@" 群jid==%@",[[data objectAtIndex:0] stringValue]);
        NSLog(@" 群名称==%@",[[data objectAtIndex:1] stringValue]);
        NSString *roomName = [[data objectAtIndex:1] stringValue];
        if (![roomName isEqualToString:@"??"]) {
            [self.homeList addObject:data];
        }
    }
    [self.friendListTable reloadData];
}
#pragma mark -tableviewDelegate-----
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
   return   (section == 0) ?  @"群聊" :  @"我的好友" ;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return   (section == 0) ?  self.homeList.count:  self.contactsArr.count ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friendCellIdentfriead];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:friendCellIdentfriead];
    }
    if (indexPath.section == 0) {
        NSArray *dataArr = self.homeList[indexPath.row];
        NSString *roomName = [[dataArr objectAtIndex:1] stringValue];
        cell.textLabel.text = roomName;
        
    } else{
        cell.textLabel.text = [self nameAtContactsIndexPath:indexPath];
        cell.detailTextLabel.text = [self getFreadStataIndexPath:indexPath];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    TestMessagesViewController *testVC = [[TestMessagesViewController alloc] init];
    if (indexPath.section == 0) {
        NSArray *dataArr = self.homeList[indexPath.row];
        NSString *roomJid = [[dataArr objectAtIndex:0] stringValue];
        NSString *roomName = [[dataArr objectAtIndex:1] stringValue];
        testVC.roomJID = roomJid;
        testVC.chatName = roomName;
    } else{
        XMPPUserMemoryStorageObject *user = self.contactsArr[indexPath.row];
        testVC.chatJID = user.jid;
        testVC.chatName = user.jid.user;
    }
    [self.navigationController pushViewController:testVC animated:YES];
}

#pragma mark - 获取好友名称
- (NSString *)nameAtContactsIndexPath:(NSIndexPath *)indexpath{
    XMPPUserMemoryStorageObject *userMenoryStorageObject = self.contactsArr[indexpath.row];
    return userMenoryStorageObject.jid.user;
}
#pragma mark - 获取好友在线状态
- (NSString *)getFreadStataIndexPath:(NSIndexPath *)indexPath{
     XMPPUserMemoryStorageObject *userMemoryStorageObject = self.contactsArr[indexPath.row];
    //查找数据库
    XMPPRosterCoreDataStorage *storage  = [ZHXMPPTool sharedInstance].xmppRosterStorage;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:storage.mainThreadManagedObjectContext];
    
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jidStr = %@", userMemoryStorageObject.jid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [storage.mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    XMPPUserCoreDataStorageObject *user = [fetchedObjects objectAtIndex:0];
    //下面主要获取头像，由于没有头像。这里注释掉
//    NSData *photoData = [[ZHXMPPTool sharedInstance].xmppvCardAvatarModule photoDataForJID:user.jid];
    if ([user isOnline]) {
        return @"[在线]";
    } else {
        return @"[离线]";
    }
}
@end
