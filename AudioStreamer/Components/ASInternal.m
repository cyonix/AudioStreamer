//
//  ASInternal.m
//  AudioStreamer
//
//  Created by Bo Anderson on 06/01/2017.
//

#import "ASInternal.h"

/* Converts a given OSStatus to a friendly string.
 * The return value should be freed when done */
char * OSStatusToStr(OSStatus status)
{
    char *str = calloc(7, sizeof(char));
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig((uint32_t)status);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4]))
    {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    }
    else if (status > -200000 && status < 200000)
    {
        free(str);
        size_t needed = (size_t)snprintf(NULL, 0, "%d", (int)status);
        str = malloc(needed + 1);
        sprintf(str, "%d", (int)status);
    }
    else
    {
        free(str);
        size_t needed = (size_t)snprintf(NULL, 0, "0x%x", (int)status);
        str = malloc(needed + 1);
        sprintf(str, "0x%x", (int)status);
    }
    return str;
}
