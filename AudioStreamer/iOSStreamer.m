//
//  iOSStreamer.m
//  AudioStreamer
//
//  Created by Bo Anderson on 07/09/2012.
//

#import "iOSStreamer.h"
#import "ASiOSAudioQueueHandler.h"

@implementation iOSStreamer

@synthesize delegate=_delegate; // Required

- (instancetype)initWithURL:(NSURL *)url
{
    if ((self = [super initWithURL:url]))
    {
        [self setAudioQueueHandlerClass:[ASiOSAudioQueueHandler class]];
    }
    return self;
}

- (BOOL)start
{
    if (![super start]) return NO;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:audioSession];

    NSError *error;

    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success)
    {
        ASLogError(@"Error setting AVAudioSession category: %@", [error localizedDescription]);
        return YES; // The stream can still continue, but we don't get interruption handling.
    }

    success = [audioSession setActive:YES error:&error];
    if (!success)
    {
        ASLogError(@"Error activating AVAudioSession: %@", [error localizedDescription]);
    }

    return YES;
}

- (void)stop
{
    [super stop];

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;

    BOOL success = [audioSession setActive:NO error:&error];
    if (!success)
    {
        ASLogError(@"Error deactivating AVAudioSession: %@", [error localizedDescription]);
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:audioSession];
}

- (void)setDelegate:(id<iOSStreamerDelegate>)delegate
{
    [super setDelegate:delegate];
    _delegate = delegate;
}

- (void)handleInterruption:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    AVAudioSessionInterruptionType interruptionType = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType)
    {
        case AVAudioSessionInterruptionTypeBegan:
            if ([self isPlaying])
            {
                ASLogInfo(@"Interrupted");

                _interrupted = YES;

                __strong id <iOSStreamerDelegate> delegate = _delegate;
                BOOL override;
                if (delegate && [delegate respondsToSelector:@selector(streamerInterruptionDidBegin:)]) {
                    override = [delegate streamerInterruptionDidBegin:self];
                } else {
                    override = NO;
                }

                if (override) return;

                [self pause];
            }
            break;
        case AVAudioSessionInterruptionTypeEnded:
            if ([self isPaused] && _interrupted)
            {
                ASLogInfo(@"Interruption ended");

                _interrupted = NO;

                AVAudioSessionInterruptionOptions flags = [userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];

                __strong id <iOSStreamerDelegate> delegate = _delegate;
                BOOL override;
                if (delegate && [delegate respondsToSelector:@selector(streamer:interruptionDidEndWithFlags:)]) {
                    override = [delegate streamer:self interruptionDidEndWithFlags:flags];
                } else {
                    override = NO;
                }

                if (override) return;

                if (flags & AVAudioSessionInterruptionOptionShouldResume)
                {
                    ASLogInfo(@"Resuming after interruption...");
                    [self play];
                }
                else
                {
                    ASLogWarn(@"Not resuming after interruption");
                    [self stop];
                }
            }
            break;
        default:
            break;
    }
}

@end
