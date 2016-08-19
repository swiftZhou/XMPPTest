//
//  ZHXMPPHeader.h
//  XMPPTest
//
//  Created by 周海 on 16/8/10.
//  Copyright © 2016年 zhouhai. All rights reserved.
//

#ifndef ZHXMPPHeader_h
#define ZHXMPPHeader_h

#import "XMPPReconnect.h"
#import "XMPPAutoPing.h"


#import "XMPPRoster.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPRosterMemoryStorage.h"  //遵循 XMPPRosterStorage接口
#import "XMPPUserMemoryStorageObject.h" //遵循 XMPPUser接口

//聊天记录模块的导入
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPMessageArchiving_Contact_CoreDataObject.h" //最近联系人
#import "XMPPMessageArchiving_Message_CoreDataObject.h"



#import "XMPPvCardTempModule.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"

//#import "JSQSystemSoundPlayer.h"
#endif /* ZHXMPPHeader_h */
