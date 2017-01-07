//
//  ASLogger.m
//  AudioStreamer
//
//  Created by Bo Anderson on 29/08/2016.
//

#import "ASLogger.h"

@implementation ASLogger

+ (instancetype)sharedInstance
{
    static ASLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ASLogger alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
#ifdef DEBUG
        _logLevel = ASLogLevelInfo;
#else
        _logLevel = ASLogLevelError;
#endif
    }
    return self;
}

- (void)logWithLevel:(ASLogLevel)logLevel message:(NSString *)msgFmt arguments:(va_list)args
{
    if (logLevel <= [self logLevel])
    {
        NSString *msg = [[NSString alloc] initWithFormat:msgFmt arguments:args];

        if ([self logHandler])
            [self logHandler](msg);
        else
            NSLog(@"%@", msg);
    }
}

- (void)logVerbose:(NSString *)msgFmt, ...
{
    va_list argList;
    va_start(argList, msgFmt);
    [self logWithLevel:ASLogLevelVerbose message:msgFmt arguments:argList];
    va_end(argList);
}

- (void)logDebug:(NSString *)msgFmt, ...
{
    va_list argList;
    va_start(argList, msgFmt);
    [self logWithLevel:ASLogLevelDebug message:msgFmt arguments:argList];
    va_end(argList);
}

- (void)logInfo:(NSString *)msgFmt, ...
{
    va_list argList;
    va_start(argList, msgFmt);
    [self logWithLevel:ASLogLevelInfo message:msgFmt arguments:argList];
    va_end(argList);
}

- (void)logWarn:(NSString *)msgFmt, ...
{
    va_list argList;
    va_start(argList, msgFmt);
    [self logWithLevel:ASLogLevelWarn message:msgFmt arguments:argList];
    va_end(argList);

}
- (void)logError:(NSString *)msgFmt, ...
{
    va_list argList;
    va_start(argList, msgFmt);
    [self logWithLevel:ASLogLevelError message:msgFmt arguments:argList];
    va_end(argList);
}

- (void)logFatal:(NSString *)msgFmt, ...
{
    va_list argList;
    va_start(argList, msgFmt);
    [self logWithLevel:ASLogLevelFatal message:msgFmt arguments:argList];
    va_end(argList);
}

@end
