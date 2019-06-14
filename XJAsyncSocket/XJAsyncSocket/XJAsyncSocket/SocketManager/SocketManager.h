//
//  SocketManager.h
//  XJIM
//
//  Created by Alien on 2019/6/13.
//  Copyright © 2019 ouwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/CocoaAsyncSocket-umbrella.h>
//首先是定义枚举,记录连接的状态
typedef NS_ENUM(NSUInteger, LinkStatus)
{
    LinkStatus_Unlink   = 0, // 未连接
    LinkStatus_Linking  = 1, // 连接中
    LinkStatus_Linked   = 2, // 连接成功了
    LinkStatus_Logout   = 3 // 退出登录(退出软件用户时的情况，不需要重连)
};

//设置代理方法
@protocol SocketLinkerDelegate <NSObject>
//连接成功
- (void)socketDidConnectToHost:(NSString *_Nullable)host port:(uint16_t)port;
//连接失败的代理,外界操作处理,比如停止发送心跳包,申请重连
- (void)socketDidDisconnectWithError:(NSError *_Nullable)error;
//读取Socket数据
- (void)socketDidResponse:(NSData *_Nullable)data;
@end

@protocol ConnectStateDelegate <NSObject>
//连接状态改变
- (void)connectDidChangeConnectState:(LinkStatus )newState;
@end
NS_ASSUME_NONNULL_BEGIN

@interface SocketManager : NSObject
/**连接状态*/
@property (nonatomic,assign) LinkStatus linkStatus;
@property(nonatomic,strong) GCDAsyncSocket *asyncSocket;
@property (nonatomic, weak) id<SocketLinkerDelegate> delegate;//连接状态监听
@property (nonatomic, weak) id <ConnectStateDelegate> connectStateDelegate;
//单例
+ (SocketManager *)shareInstance;
//连接
- (void)connectToServer;
//断开
- (void)cutOffSocket;
// 发送数据包
- (void)sendMsgPacket:(NSData *)packet;
// 读取消息包
- (void)readMsgPacket;
//判断Socket连接状态供外界调用
- (BOOL)isSocketConnected;
@end

NS_ASSUME_NONNULL_END
