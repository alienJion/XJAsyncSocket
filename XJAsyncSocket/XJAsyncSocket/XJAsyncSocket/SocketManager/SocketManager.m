//
//  SocketManager.m
//  XJIM
//
//  Created by Alien on 2019/6/13.
//  Copyright © 2019 ouwen. All rights reserved.
//

#import "SocketManager.h"
#define SocketHost @"192.168.1.137"
#define SocketPort 7002
@interface SocketManager()<GCDAsyncSocketDelegate>

//握手次数
@property(nonatomic,assign) NSInteger pushCount;

// 心跳计时器
@property (nonatomic, strong) NSTimer *beatTimer;
@end
@implementation SocketManager

// 添加心跳定时器
- (void)addBeatTimer
{
    // 长连接定时器
    self.beatTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.beatTimer forMode:NSRunLoopCommonModes];
}
// 心跳连接
- (void)longConnectToSocket
{
//    [[ChatManager shareInstance] sendBeatMessage];
}

//全局访问点
+ (SocketManager *)shareInstance {
    static SocketManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

//可以在这里做一些初始化操作
- (instancetype)init
{
    self = [super init];
    if (self) {
        /**
         *  LQ~ 初始状态为未连接
         */
        self.linkStatus = LinkStatus_Unlink;
    }
    return self;
}

#pragma mark-----------Delegate------------
//连接成功的回调
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"socket连接成功");
    [self addBeatTimer];//发送心跳包
    //    [self sendDataToServer];
    //记录连接成功状态
    self.linkStatus = LinkStatus_Linked;
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidConnectToHost:port:)])
    {
        //代理执行连接成功后的操作
        [self.delegate socketDidConnectToHost:host port:port];
    }
    //对读数据进行设置
    [self readMsgPacket];
}
/**
 读取数据（连接成功向服务器发送数据后,服务器会有响应）
 
 @param sock 客户端socket
 @param data 读取到的数据
 @param tag 本次读取的标记
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

    [self readMsgPacket];
    //服务器推送次数
    self.pushCount++;
    
    //在这里进行校验操作,情况分为成功和失败两种,成功的操作一般都是拉取数据
    //收到了服务器传给的数据,相对应的读数据的类来处理收到的数据
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidResponse:)])
    {
        [self.delegate socketDidResponse:[data mutableCopy]];
    }
}
/**
 客户端socket断开 （连接失败的回调）
 
 @param sock 客户端socket
 @param err 错误描述
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"Socket连接失败");
    // 判断连接状态不是主动断开连接的时候
    if(self.linkStatus != LinkStatus_Logout)
    {
        self.linkStatus = LinkStatus_Unlink;
        if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidDisconnectWithError:)])
        {
            //LQ~ 说明连接失败,要传给外界信号,我连接出错了,其余的事自己搞定
            [self.delegate socketDidDisconnectWithError:err];
        }
    }
    self.pushCount = 0;
    [self reconnectServer];
}
#pragma mark-----------Func----------------
/**发起连接*/
- (void)connectToServer {
    if (LinkStatus_Linking != self.linkStatus) {
        self.pushCount = 0;
        self.asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *error = nil;
        if (![self.asyncSocket connectToHost:SocketHost onPort:SocketPort error:&error]) {
            /*LQ~ 如果socktet连接失败,返回NO,记录连接为LINKSTATE_UNLINK */
            self.linkStatus = LinkStatus_Unlink;
        }
        if (error != nil)
        {
            //当有错误的时候抛出异常错误信息
            @throw [NSException exceptionWithName:@"GCDAsyncSocket" reason:[error localizedDescription] userInfo:nil];
        }
        //当socktet连接成功的时候,记录连接的状态,连接中
        self.linkStatus = LinkStatus_Linking;
    }
}
//切断连接
- (void)cutOffSocket {
    NSLog(@"socket断开连接");
    self.pushCount = 0;
    [self.beatTimer invalidate];
    self.beatTimer = nil;
    [self.asyncSocket disconnect];
    self.linkStatus = LinkStatus_Logout;
}
#pragma mark 读取数据
- (void)readMsgPacket
{
    if (self.linkStatus == LinkStatus_Linked && self.asyncSocket.isConnected == YES)
    {
        //当确认连接成功后,就可以开始读服务器发送的数据了,设置超时的时间和tag值
        //告诉asyncSocket可以准备好读信息了
        [self.asyncSocket readDataWithTimeout:-1 tag:200];
    }else{
        //如果连接失败了,要传给外界信号,我连接出错了,其余的事自己搞定
        if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidDisconnectWithError:)])
        {
            [self.delegate socketDidDisconnectWithError:nil];
        }
    }
}
//发送数据包
- (void)sendMsgPacket:(NSData *)packet
{
    if ((packet.length && self.linkStatus == LinkStatus_Linked) && self.asyncSocket.isConnected == YES)
    {
        //确定当前Socket是连接着的,发送数据
        [self.asyncSocket writeData:packet withTimeout:-1 tag:1];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidDisconnectWithError:)])
        {
            //LQ~ 说明连接失败,要传给外界信号,我连接出错了,其余的事自己搞定
            [self.delegate socketDidDisconnectWithError:nil];
        }
    }
    //每次发完之后都要对读取消息进行一次设置
    [self readMsgPacket];
}


//查看scoket的连接状态,供外界调用查看
- (BOOL)isSocketConnected
{
    return self.asyncSocket.isConnected;
}
-(void)setLinkStatus:(LinkStatus)linkStatus{
    _linkStatus = linkStatus;
    if (self.connectStateDelegate && [self.connectStateDelegate respondsToSelector:@selector(connectDidChangeConnectState:)])
    {
        //连接状态发生了改变,外界代理去做相应的处理
        [self.connectStateDelegate connectDidChangeConnectState:linkStatus];
    }
}
//连接失败,重新连接
- (void)reconnectServer {
    //    如果网络有问题就暂停，网路恢复继续连接
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    BOOL result = (state == UIApplicationStateActive);
    //程序在前台才进行重连
    if (result) {
        NSError *error = nil;
        [self.asyncSocket connectToHost:SocketHost onPort:SocketPort error:&error];
        if (error) {
            NSLog(@"SocektConnectError:%@",error);
        }
    }
    
}




@end
