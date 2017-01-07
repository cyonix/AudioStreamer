//
//  ASProxyInformation.m
//  AudioStreamer
//
//  Created by Bo Anderson on 06/01/2017.
//

#import "ASProxyInformation.h"

@implementation ASProxyInformation

- (instancetype)initWithType:(ASProxyType)type host:(NSString *)host port:(uint16_t)port
{
    if ((self = [super init]))
    {
        _type = type;
        _host = host;
        _port = port;
    }
    return self;
}

@end
