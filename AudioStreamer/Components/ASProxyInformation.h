//
//  ASProxyInformation.h
//  AudioStreamer
//
//  Created by Bo Anderson on 06/01/2017.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ASProxyType)
{
    ASProxySystem = 0,
    ASProxySOCKS,
    ASProxyHTTP,
};

@interface ASProxyInformation : NSObject

@property (nonatomic, assign, readonly) ASProxyType type;
@property (nonatomic, copy, readonly) NSString *host;
@property (nonatomic, assign, readonly) uint16_t port;

- (instancetype)initWithType:(ASProxyType)type host:(NSString *)host port:(uint16_t)port;

@end
