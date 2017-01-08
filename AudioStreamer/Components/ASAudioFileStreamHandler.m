//
//  ASAudioFileStreamHandler.m
//  AudioStreamer
//
//  Created by Bo Anderson on 29/08/2016.
//

#import "ASAudioFileStreamHandler.h"
#import "ASInternal.h"


NSString * const ASFileStreamErrorDomain = @"com.alexcrichton.audiostreamer.ASAudioFileStreamHandler";


@implementation ASAudioFileStreamHandler

/* AudioFileStream callback when packets are available */
static void ASPacketsProc(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets,
                          const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    ASAudioFileStreamHandler *handler = (__bridge ASAudioFileStreamHandler *)inClientData;
    [handler handleAudioPackets:inInputData
                    numberBytes:inNumberBytes
                  numberPackets:inNumberPackets
             packetDescriptions:inPacketDescriptions];
}

/* AudioFileStream callback when properties are available */
static void ASPropertyListenerProc(void *inClientData, AudioFileStreamID inAudioFileStream,
                                   AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    ASAudioFileStreamHandler *handler = (__bridge ASAudioFileStreamHandler *)inClientData;
    [handler handlePropertyChangeForFileStream:inAudioFileStream
                          fileStreamPropertyID:inPropertyID
                                       ioFlags:ioFlags];
}


- (instancetype)initWithFileType:(AudioFileTypeID)fileType
{
    if ((self = [super init]))
    {
        _fileType = fileType;
    }
    return self;
}

- (void)open
{
    OSStatus osErr = AudioFileStreamOpen((__bridge void *)self, ASPropertyListenerProc,
                                         ASPacketsProc, _fileType, &_audioFileStream);
    [self checkStatusForError:osErr errorCode:ASFileStreamOpenFailed];
}

- (void)close
{
    if (_audioFileStream == NULL) return;

    if (_parsing)
    {
        _closeQueued = YES;
    }
    else
    {
        OSStatus osErr = AudioFileStreamClose(_audioFileStream);
        ASAssert(osErr == noErr, @"AudioFileStreamClose returned error \"%@\"", [[self class] descriptionForAFSErrorCode:osErr]);
        _audioFileStream = NULL;
    }
}

- (void)dealloc
{
    [self close];
}

- (BOOL)checkStatusForError:(OSStatus)status errorCode:(ASFileStreamErrorCode)errorCode
{
    if (status != noErr)
    {
        [self failWithErrorCode:errorCode extraInfo:[[self class] descriptionForAFSErrorCode:status]];
        return YES;
    }
    return NO;
}

- (void)failWithErrorCode:(ASFileStreamErrorCode)errorCode
{
    [self failWithErrorCode:errorCode extraInfo:@""];
}

- (void)failWithErrorCode:(ASFileStreamErrorCode)errorCode extraInfo:(NSString *)extraInfo
{
    if (_errorThrown) return;
    _errorThrown = YES;

    ASLogError(@"File stream encountered an error: %@ (%@)", [[self class] descriptionForErrorCode:errorCode], extraInfo);

    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:
                                   NSLocalizedString([[self class] descriptionForErrorCode:errorCode], nil),
                               NSLocalizedFailureReasonErrorKey:
                                   NSLocalizedString(extraInfo, nil)};
    NSError *error = [NSError errorWithDomain:ASFileStreamErrorDomain code:errorCode userInfo:userInfo];

    [self close];
    [[self delegate] fileStreamFailedWithError:error];
}

+ (NSString *)descriptionForErrorCode:(ASFileStreamErrorCode)errorCode
{
    switch (errorCode)
    {
        case ASFileStreamGetPropertyFailed:
            return @"File stream get property failed";
        case ASFileStreamSetPropertyFailed:
            return @"File stream set property failed";
        case ASFileStreamParseBytesFailed:
            return @"Parse bytes failed";
        case ASFileStreamOpenFailed:
            return @"Failed to open file stream";
    }
}

 + (NSString *)descriptionForAFSErrorCode:(OSStatus)osErr
{
    switch (osErr)
    {
        case kAudioFileStreamError_BadPropertySize:
            return @"The size for an internal property call to the file stream was incorrect. This is a bug.";
        case kAudioFileStreamError_DataUnavailable:
            return @"The file stream could not get data for an internal property call. This is a bug.";
        case kAudioFileStreamError_DiscontinuityCantRecover:
            return @"The file stream reached a state where it could not recover.";
        case kAudioFileStreamError_IllegalOperation:
            return @"An illegal operation on the file stream was attempted. This is a bug.";
        case kAudioFileStreamError_InvalidFile:
            return @"The given HTTP stream is invalid. Perhaps an unsupported format?";
        case kAudioFileStreamError_InvalidPacketOffset:
            return @"The packet offset for the file stream is invalid. The HTTP stream could be malformed.";
        case kAudioFileStreamError_NotOptimized:
            return @"The given HTTP stream is not optimized for streaming.";
        case kAudioFileStreamError_UnspecifiedError:
            return @"An unknown error occurred in the file stream.";
        case kAudioFileStreamError_UnsupportedDataFormat:
        case kAudioFileStreamError_UnsupportedFileType:
            return @"The given HTTP stream is of an unsupported format.";
        case kAudioFileStreamError_UnsupportedProperty:
            return @"An internal property call is unsupported for this stream. This is a bug.";
        case kAudioFileStreamError_ValueUnknown:
            return @"An internal property call to the file stream could not retrieve a value. This is a bug.";
        default:
            break;
    }
    char *str = OSStatusToStr(osErr);
    NSString *ret = [NSString stringWithFormat:@"AudioFileStream error code %s", str];
    free(str);
    return ret;
 }

- (void)parseData:(void *)data length:(UInt32)length
{
    _parsing = YES;

    UInt32 parseFlags;
    if (_discontinuous)
        parseFlags = kAudioFileStreamParseFlag_Discontinuity;
    else
        parseFlags = 0;

    OSStatus osErr = AudioFileStreamParseBytes(_audioFileStream, length, data, parseFlags);
    
    _parsing = NO;

    if (_closeQueued) [self close];
    [self checkStatusForError:osErr errorCode:ASFileStreamParseBytesFailed];
}

- (SInt64)seekToPacket:(SInt64)seekPacket
{
    UInt32 ioFlags = 0;
    SInt64 packetAlignedByteOffset;
    OSStatus osErr = AudioFileStreamSeek(_audioFileStream, seekPacket, &packetAlignedByteOffset, &ioFlags);
    if (osErr != noErr || (ioFlags & kAudioFileStreamSeekFlag_OffsetIsEstimated))
        return -1;

    _discontinuous = _vbr;

    return packetAlignedByteOffset;
}

- (BOOL)calculateBitrate:(double *)rate estimated:(BOOL *)estimated
{
    if (!_preparedForAudio) return NO;
    else if (_vbr)
    {
        // Method one - exact
        UInt32 bitrate;
        UInt32 bitrateSize = sizeof(bitrate);
        OSStatus status = AudioFileStreamGetProperty(_audioFileStream,
                                                     kAudioFileStreamProperty_BitRate,
                                                     &bitrateSize, &bitrate);
        if (status == 0) {
            *rate = bitrate;
            *estimated = NO;
            return YES;
        }

        // Method two - average
        double packetsPerSec = _streamDescription.mSampleRate / _streamDescription.mFramesPerPacket;
        if (packetsPerSec <= 0) return NO;

        Float64 bytesPerPacket;
        UInt32 bytesPerPacketSize = sizeof(bytesPerPacket);
        status = AudioFileStreamGetProperty(_audioFileStream,
                                            kAudioFileStreamProperty_AverageBytesPerPacket,
                                            &bytesPerPacketSize, &bytesPerPacket);
        if (status == 0) {
            *rate = 8.0 * bytesPerPacket * packetsPerSec;
            *estimated = YES;
            return YES;
        }

        return NO;
    }
    else
    {
        *rate = 8.0 * _streamDescription.mSampleRate * _streamDescription.mBytesPerPacket * _streamDescription.mFramesPerPacket;
        *estimated = NO;
        return YES;
    }
}

- (BOOL)duration:(double *)duration
{
    double packetDuration = _streamDescription.mFramesPerPacket / _streamDescription.mSampleRate;
    if (packetDuration <= 0) return NO;

    UInt64 packetCount;
    UInt32 packetCountSize = sizeof(packetCount);
    OSStatus status = AudioFileStreamGetProperty(_audioFileStream,
                                                 kAudioFileStreamProperty_AudioDataPacketCount,
                                                 &packetCountSize, &packetCount);
    if (status == noErr && packetCount != 0)
    {
        *duration = packetCount * packetDuration;
        return YES;
    }

    return NO;
}

//
// handleAudioPackets:numberBytes:numberPackets:packetDescriptions:
//
// Object method which handles the implementation of ASPacketsProc
//
// Parameters:
//    inInputData - the packet data
//    inNumberBytes - byte size of the data
//    inNumberPackets - number of packets in the data
//    inPacketDescriptions - packet descriptions
//
- (void)handleAudioPackets:(const void *)inInputData
               numberBytes:(UInt32)inNumberBytes
             numberPackets:(UInt32)inNumberPackets
        packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions
{
    if (_closeQueued) return;

    // we have successfully read the first packets from the audio stream, so
    // clear the "discontinuous" flag
    if (_discontinuous) {
        _discontinuous = NO;
    }

    if (!_preparedForAudio)
    {
        _preparedForAudio = YES;
        _vbr = (inPacketDescriptions != NULL);

        UInt32 packetSize = 0;
        if (_vbr)
        {
            /* Try to determine the packet size, eventually falling back to some
             reasonable default of a size */
            UInt32 sizeOfUInt32 = sizeof(packetSize);
            OSStatus osErr = AudioFileStreamGetProperty(_audioFileStream,
                                                        kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32,
                                                        &packetSize);

            if (osErr || packetSize == 0) {
                osErr = AudioFileStreamGetProperty(_audioFileStream,
                                                   kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32,
                                                   &packetSize);
                if (osErr) {
                    packetSize = 0;
                }
            }
        }

        /* Some audio formats have a "magic cookie" which needs to be transferred from
         the file stream to the audio queue. If any of this fails it's "OK" because
         the stream either doesn't have a magic or error will propagate later */

        void *cookieData = NULL;
        UInt32 cookieSize = 0;
        Boolean writable;
        OSStatus ignorableError;
        ignorableError = AudioFileStreamGetPropertyInfo(_audioFileStream,
                                                        kAudioFileStreamProperty_MagicCookieData, &cookieSize,
                                                        &writable);
        if (!ignorableError)
        {
            // get the cookie data
            cookieData = calloc(1, cookieSize);
            if (cookieData != NULL)
            {
                ignorableError = AudioFileStreamGetProperty(_audioFileStream,
                                                            kAudioFileStreamProperty_MagicCookieData, &cookieSize,
                                                            cookieData);
                if (ignorableError)
                {
                    free(cookieData);
                    cookieData = NULL;
                }
            }
        }

        [[self delegate] fileStreamPreparedForAudioWithPacketSize:packetSize cookieData:cookieData cookieSize:cookieSize];
        if (_closeQueued) return; // Something happened during the delegate call. Abort.
    }

    [[self delegate] fileStreamAudioPacketsReady:inInputData
                                     numberBytes:inNumberBytes
                                   numberPackets:inNumberPackets
                              packetDescriptions:inPacketDescriptions];
}

//
// handlePropertyChangeForFileStream:fileStreamPropertyID:ioFlags:
//
// Object method which handles implementation of ASPropertyListenerProc
//
// Parameters:
//    inAudioFileStream - should be the same as self->audioFileStream
//    inPropertyID - the property that changed
//    ioFlags - the ioFlags passed in
//
- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
                     fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
                                  ioFlags:(UInt32 *)ioFlags
{
    assert(inAudioFileStream == _audioFileStream);

    switch (inPropertyID)
    {
        case kAudioFileStreamProperty_ReadyToProducePackets:
            ASLogInfo(@"ready for packets");
            _discontinuous = YES;
            break;

        case kAudioFileStreamProperty_DataOffset: {
            SInt64 offset;
            UInt32 offsetSize = sizeof(offset);
            OSStatus osErr = AudioFileStreamGetProperty(inAudioFileStream,
                                                        kAudioFileStreamProperty_DataOffset,
                                                        &offsetSize, &offset);
            if ([self checkStatusForError:osErr errorCode:ASFileStreamGetPropertyFailed])
                break;

            _dataOffset = (UInt64)offset;

            ASLogDebug(@"have data offset: %llu", _dataOffset);
            break;
        }

        case kAudioFileStreamProperty_AudioDataByteCount: {
            UInt32 byteCountSize = sizeof(_audioDataByteTotal);
            OSStatus osErr = AudioFileStreamGetProperty(inAudioFileStream,
                                                        kAudioFileStreamProperty_AudioDataByteCount,
                                                        &byteCountSize, &_audioDataByteTotal);
            if ([self checkStatusForError:osErr errorCode:ASFileStreamGetPropertyFailed])
                break;

            ASLogDebug(@"have byte total: %llu", _audioDataByteTotal);
            break;
        }

        case kAudioFileStreamProperty_DataFormat: {
            /* If we seeked, don't re-read the data */
            if (_streamDescription.mSampleRate == 0) {
                UInt32 descSize = sizeof(_streamDescription);

                OSStatus osErr = AudioFileStreamGetProperty(inAudioFileStream,
                                                            kAudioFileStreamProperty_DataFormat,
                                                            &descSize, &_streamDescription);
                if ([self checkStatusForError:osErr errorCode:ASFileStreamGetPropertyFailed])
                    break;

                [[self delegate] fileStreamBasicDescriptionUpdated:_streamDescription];
            }
            ASLogInfo(@"have data format");
            break;
        }

        case kAudioFileStreamProperty_FormatList: {
            Boolean outWriteable;
            UInt32 formatListSize;
            OSStatus osErr = AudioFileStreamGetPropertyInfo(inAudioFileStream,
                                                            kAudioFileStreamProperty_FormatList,
                                                            &formatListSize, &outWriteable);
            if ([self checkStatusForError:osErr errorCode:ASFileStreamGetPropertyFailed])
                break;

            AudioFormatListItem *formatList = malloc(formatListSize);
            if (formatList == NULL)
            {
                [self failWithErrorCode:ASFileStreamGetPropertyFailed];
                break;
            }

            osErr = AudioFileStreamGetProperty(inAudioFileStream,
                                               kAudioFileStreamProperty_FormatList,
                                               &formatListSize, formatList);
            if ([self checkStatusForError:osErr errorCode:ASFileStreamGetPropertyFailed])
            {
                free(formatList);
                break;
            }
            
            for (UInt32 i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i++)
            {
                AudioStreamBasicDescription pasbd = formatList[i].mASBD;
                
                if (pasbd.mFormatID == kAudioFormatMPEG4AAC_HE || pasbd.mFormatID == kAudioFormatMPEG4AAC_HE_V2)
                {
                    _streamDescription = pasbd;
                    [[self delegate] fileStreamBasicDescriptionUpdated:pasbd];
                    break;
                }
            }
            free(formatList);
            break;
        }
    }
}

@end
