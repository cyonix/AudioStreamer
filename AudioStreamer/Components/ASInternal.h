//
//  ASInternal.h
//  AudioStreamer
//
//  Created by Bo Anderson on 04/01/2017.
//

#import "ASLogger.h"

#ifndef NDEBUG
#define ASAssert(cond, ...) \
    do {\
        if (!(cond)) {\
            NSString *reason = [NSString stringWithFormat:@"Assertion failure: %s on line %@:%d. %@",\
                                                            #cond,\
                                                            [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
                                                            __LINE__,\
                                                            [NSString stringWithFormat:@"" __VA_ARGS__]];\
            ASLogFatal(@"%@", reason);\
            [[NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil] raise];\
        }\
    } while(0)
#else
#define ASAssert(cond, ...) \
    do {\
        if (!(cond)) {\
            NSString *reason = [NSString stringWithFormat:@"Assertion failure: %s on line %@:%d. %@",\
                                                            #cond,\
                                                            [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
                                                            __LINE__,\
                                                            [NSString stringWithFormat:@"" __VA_ARGS__]];\
            ASLogFatal(@"%@", reason);\
        }\
    } while(0)
#endif

/* Converts a given OSStatus to a friendly string.
 * The return value should be freed when done */
char * OSStatusToStr(OSStatus status);
