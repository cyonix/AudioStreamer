//
//  ASVolumeView.m
//  AudioStreamer
//
//  Created by Bo Anderson on 08/04/2016.
//
//

#import "ASVolumeView.h"

@implementation ASVolumeView

- (CGSize)intrinsicContentSize
{
	return [self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
}

@end
