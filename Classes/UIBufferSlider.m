//
//  UIBufferSlider.m
//  AudioStreamer
//
//  Created by Bo Anderson on 12/02/2015.
//
//

#import "UIBufferSlider.h"

#define DEGREES_TO_RADIANS(angle) (CGFloat)((angle) / 180.0 * M_PI)

@interface UIBufferSlider()

@property (nonatomic, assign) CGRect trackRect;

@end

@implementation UIBufferSlider

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setContinuous:NO];
    }
    return self;
}

- (void)drawRoundedHalfBarInRect:(CGRect)rect parentRect:(CGRect)parentRect
{
    CGFloat widthDiff = parentRect.size.width - rect.size.width;
    CGFloat radius;
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        radius = 1.0;
    } else {
        radius = 4.0;
    }
    CGRect innerRect = CGRectInset(rect, radius, radius);

    if (isinf(innerRect.origin.x) || isinf(innerRect.origin.y)) return;

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(rect.origin.x + radius, rect.origin.y)];
    [bezierPath addArcWithCenter:innerRect.origin radius:radius startAngle:DEGREES_TO_RADIANS(270.0) endAngle:DEGREES_TO_RADIANS(180.0) clockwise:NO];
    [bezierPath addLineToPoint:CGPointMake(rect.origin.x, innerRect.origin.y + innerRect.size.height)];
    [bezierPath addArcWithCenter:CGPointMake(innerRect.origin.x, innerRect.origin.y + innerRect.size.height) radius:radius startAngle:DEGREES_TO_RADIANS(180.0) endAngle:DEGREES_TO_RADIANS(90.0) clockwise:NO];

    if (widthDiff < radius) {
        CGFloat widthDiffRadius = radius-widthDiff;
        CGRect endInnerRect = CGRectInset(rect, widthDiffRadius, widthDiffRadius);
        [bezierPath addLineToPoint:CGPointMake(endInnerRect.origin.x + endInnerRect.size.width, rect.origin.y + rect.size.height)];
        [bezierPath addArcWithCenter:CGPointMake(endInnerRect.origin.x + endInnerRect.size.width, endInnerRect.origin.y + endInnerRect.size.height) radius:widthDiffRadius startAngle:DEGREES_TO_RADIANS(90.0) endAngle:DEGREES_TO_RADIANS(0.0) clockwise:NO];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x + rect.size.width, endInnerRect.origin.y)];
        [bezierPath addArcWithCenter:CGPointMake(endInnerRect.origin.x + endInnerRect.size.width, endInnerRect.origin.y) radius:widthDiffRadius startAngle:DEGREES_TO_RADIANS(0.0) endAngle:DEGREES_TO_RADIANS(270.0) clockwise:NO];
    } else {
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)];
    }

    [bezierPath addLineToPoint:CGPointMake(rect.origin.x + radius, rect.origin.y)];
    [bezierPath closePath];
    [bezierPath fill];
}

- (void)drawRect:(CGRect)outerRect {
    [super drawRect:outerRect];

    CGRect barRect = [self trackRectForBounds:outerRect];
    if (barRect.size.height != 0) _trackRect = barRect;
    else barRect = _trackRect;

    [[UIColor colorWithWhite:(CGFloat)0.72 alpha:(CGFloat)1.0] set];
    [self drawRoundedHalfBarInRect:barRect parentRect:barRect];

    [[UIColor redColor] set];
    CGRect bufferRect = barRect;
    bufferRect.size.width *= [self bufferValue] / 100;
    [self drawRoundedHalfBarInRect:bufferRect parentRect:barRect];

    if ([self respondsToSelector:@selector(tintColor)]) {
        [[self tintColor] set];
    } else {
        [[UIColor colorWithRed:(CGFloat)(29.0/255.0) green:(CGFloat)(98.0/255.0) blue:(CGFloat)(240.0/255.0) alpha:1.0] set];
    }
    CGRect progressRect = barRect;
    progressRect.size.width *= [self value] / 100;
    [self drawRoundedHalfBarInRect:progressRect parentRect:barRect];

    [self setMinimumTrackImage:[UIImage alloc] forState:UIControlStateNormal];
    [self setMaximumTrackImage:[UIImage alloc] forState:UIControlStateNormal];
}

- (void)setValue:(float)value
{
    [super setValue:value];
    [self setNeedsDisplay];
}

- (void)setBufferValue:(double)bufferValue
{
    _bufferValue = MIN(bufferValue, 100.0);
    [self setNeedsDisplay];
}

@end
