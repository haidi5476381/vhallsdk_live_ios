//
//  CONSTS.h
//  VHSDKDemo
//
//  Created by vhall on 15/10/10.
//  Copyright © 2015年 vhall. All rights reserved.
//

#ifndef CONSTS_h
#define CONSTS_h

//1、AppDelegate.mm 修改为.mm
//2、关闭bitcode
//3、plist中 App Transport Security Settings -> Allow Arbitrary Loads 设置为YES
//4、设置以下数据 检查 Bundle ID 即可观看直播

//接口文档说明： http://e.vhall.com/home/vhallapi
#define DEMO_AppKey         @"替换成您自己的AppKey"        //详见：http://e.vhall.com/home/vhallapi/authlist
#define DEMO_AppSecretKey   @"替换成您自己的AppSecretKey"  //AppSecretKey
#define DEMO_ActivityId     @"" //活动id    详见：http://e.vhall.com/home/vhallapi/active   webinar/create 创建活动
#define DEMO_AccessToken    @"" //直播Token 详见：http://e.vhall.com/home/vhallapi/audience verify/access-token 获取SDK直播操作token

#define DEMO_account        @"" //账号 详见：http://e.vhall.com/home/vhallapi/user user/register创建用户 对应 third_user_id
#define DEMO_password       @"" //密码 对应 pass字段

//#if DEBUG  // 调试状态, 打开LOG功能
#define VHLog(...) NSLog(__VA_ARGS__)
//#else // 发布状态, 关闭LOG功能
//#define VHLog(...)
//#endif

#define kViewFramePath  @"frame"

#pragma mark - iphone detection functions

#define APPDELEGATE [AppDelegate getAppDelegate]

#define IOSVersion  [[UIDevice currentDevice].systemVersion floatValue]

#define KIScreenHeight [[UIScreen mainScreen] bounds].size.height

#define KIScreenWidth [[UIScreen mainScreen] bounds].size.width

//颜色
#define MakeColor(r,g,b,a) ([UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a])
#define MakeColorRGB(hex)  ([UIColor colorWithRed:((hex>>16)&0xff)/255.0 green:((hex>>8)&0xff)/255.0 blue:(hex&0xff)/255.0 alpha:1.0])
#define MakeColorRGBA(hex,a) ([UIColor colorWithRed:((hex>>16)&0xff)/255.0 green:((hex>>8)&0xff)/255.0 blue:(hex&0xff)/255.0 alpha:a])
#define MakeColorARGB(hex) ([UIColor colorWithRed:((hex>>16)&0xff)/255.0 green:((hex>>8)&0xff)/255.0 blue:(hex&0xff)/255.0 alpha:((hex>>24)&0xff)/255.0])

#endif /* CONSTS_h */
