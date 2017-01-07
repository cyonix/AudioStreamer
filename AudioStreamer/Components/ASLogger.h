//
//  ASLogger.h
//  AudioStreamer
//
//  Created by Bo Anderson on 29/08/2016.
//

#import <Foundation/Foundation.h>

#define ASLogVerbose(fmt, args...) [[ASLogger sharedInstance] logVerbose:@"%s " fmt, __PRETTY_FUNCTION__, ##args]
#define ASLogDebug(fmt, args...) [[ASLogger sharedInstance] logDebug:@"%s " fmt, __PRETTY_FUNCTION__, ##args]
#define ASLogInfo(fmt, args...) [[ASLogger sharedInstance] logInfo:@"%s " fmt, __PRETTY_FUNCTION__, ##args]
#define ASLogWarn(fmt, args...) [[ASLogger sharedInstance] logWarn:@"%s " fmt, __PRETTY_FUNCTION__, ##args]
#define ASLogError(fmt, args...) [[ASLogger sharedInstance] logError:@"%s " fmt, __PRETTY_FUNCTION__, ##args]
#define ASLogFatal(fmt, args...) [[ASLogger sharedInstance] logFatal:@"%s " fmt, __PRETTY_FUNCTION__, ##args]

/**
 * Log levels. Used to filter out certain levels of logging.
 *
 * Each level down the chain towards verbose will include the previous log levels.
 * For example, ASLogLevelWarn will include ASLogLevelError and ASLogLevelFatal.
 *
 * See <[AudioStreamer logLevel]> for more information.
 */
typedef NS_ENUM(NSUInteger, ASLogLevel)
{
    /**
     * No logging will occur.
     */
    ASLogLevelNone = 0,
    /**
     * Logging will only occur in the event of a fatal error such as an assertion.
     */
    ASLogLevelFatal,
    /**
     * Logging will occur when the streamer encounters a error that has caused the streamer
     * to stop.
     */
    ASLogLevelError,
    /**
     * Logging will occur when the streamer encounters an issue but not necessarily one that
     * has resulted in the streamer having to stop.
     */
    ASLogLevelWarn,
    /**
     * Logging will occur when the streamer has reached a point of interest in its streaming.
     */
    ASLogLevelInfo,
    /**
     * Logging will occur when the streamer has information that may be useful when debugging
     * the streamer.
     */
    ASLogLevelDebug,
    /**
     * Logging will occur at most steps in the streamer's process. Expect a lot of logs!
     */
    ASLogLevelVerbose
};

typedef void (^ASLogHandler)(NSString *);


@interface ASLogger : NSObject

@property (readwrite) ASLogLevel logLevel;

@property (readwrite, copy) ASLogHandler logHandler;

+ (instancetype)sharedInstance;

- (void)logVerbose:(NSString *)msgFmt, ... NS_FORMAT_FUNCTION(1, 2);
- (void)logDebug:(NSString *)msgFmt, ... NS_FORMAT_FUNCTION(1, 2);
- (void)logInfo:(NSString *)msgFmt, ... NS_FORMAT_FUNCTION(1, 2);
- (void)logWarn:(NSString *)msgFmt, ... NS_FORMAT_FUNCTION(1, 2);
- (void)logError:(NSString *)msgFmt, ... NS_FORMAT_FUNCTION(1, 2);
- (void)logFatal:(NSString *)msgFmt, ... NS_FORMAT_FUNCTION(1, 2);

@end
