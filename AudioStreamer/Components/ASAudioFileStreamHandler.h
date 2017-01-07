//
//  ASAudioFileStreamHandler.h
//  AudioStreamer
//
//  Created by Bo Anderson on 29/08/2016.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

/**
 * Error codes that the file stream could throw.
 *
 * These are mainly used internally but can be used for comparison with
 * the <[AudioStreamer error]> property.
 *
 * ```
 * if ([[streamer error] code] == ASFileStreamParseBytesFailed)
 * {
 *     // Bad stream?
 * }
 * ```
 *
 * You can also check the domain of the error to see if it came from the
 * read stream:
 *
 * ```
 * if ([[streamer error] domain] == ASFileStreamErrorDomain)
 * {
 *     // It's a file stream error
 * }
 * ```
 */
typedef NS_ENUM(NSInteger, ASFileStreamErrorCode)
{
    /**
     * The file stream threw an error when attempting to fetch a property
     */
    ASFileStreamGetPropertyFailed = 201,
    /**
     * The file stream threw an error when attempting to set a property
     */
    ASFileStreamSetPropertyFailed = 202,
    /**
     * The file stream threw an error when parsing the stream data
     */
    ASFileStreamParseBytesFailed = 203,
    /**
     * The file stream threw an error when opening
     */
    ASFileStreamOpenFailed = 204,
};


extern NSString * const ASFileStreamErrorDomain;


@protocol ASAudioFileStreamHandlerDelegate <NSObject>

- (void)fileStreamBasicDescriptionUpdated:(AudioStreamBasicDescription)asbd;

- (void)fileStreamPreparedForAudioWithPacketSize:(UInt32)packetSize
                                      cookieData:(void *)cookieData
                                      cookieSize:(UInt32)cookieSize;
- (void)fileStreamAudioPacketsReady:(const void *)inputData
                        numberBytes:(UInt32)numberBytes
                      numberPackets:(UInt32)numberPackets
                 packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions;

- (void)fileStreamFailedWithError:(NSError *)error;

@end


@interface ASAudioFileStreamHandler : NSObject
{
    AudioFileStreamID _audioFileStream;

    AudioFileTypeID _fileType;
    AudioStreamBasicDescription _streamDescription;

    BOOL _preparedForAudio;
    BOOL _parsing;
    BOOL _closeQueued;
    BOOL _errorThrown;

    BOOL _discontinuous; /* flag to indicate the middle of a stream */
}

@property (nonatomic, weak) id <ASAudioFileStreamHandlerDelegate> delegate;

@property (nonatomic, assign, readonly, getter=isVBR) BOOL vbr;

@property (nonatomic, assign, readonly) UInt64 dataOffset;
@property (nonatomic, assign, readonly) UInt64 audioDataByteTotal;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileType:(AudioFileTypeID)fileType NS_DESIGNATED_INITIALIZER;

- (void)open;
- (void)close;

- (void)parseData:(void *)data length:(UInt32)length;

- (SInt64)seekToPacket:(SInt64)seekPacket;

- (BOOL)calculateBitrate:(double *)rate estimated:(BOOL *)estimated;
- (BOOL)duration:(double *)duration;

@end
