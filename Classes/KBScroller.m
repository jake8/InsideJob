//
//  KBScroller.m
//  Inside Job
//
//  Created by Ben K on 2010/11/21.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "KBScroller.h"

@implementation KBScroller


- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		[self setArrowsPosition:NSScrollerArrowsNone];	
		if ([self bounds].size.width / [self bounds].size.height < 1) {
			isVertical = YES;
		} else {
			isVertical = NO;
		}
	}
	return self;
}

- (void)drawRect:(NSRect)aRect
{		
	// Background
	[[(NSScrollView *)[self superview] backgroundColor] set];
	NSRectFill([self bounds]);
	
	NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
  [ctx saveGraphicsState];
	
	// Slot
	NSBezierPath *bz = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 4, 4) xRadius:4 yRadius:4];
	[bz addClip];
	[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
	NSRectFill([self bounds]);
	
	[ctx restoreGraphicsState];
	
	// Knob
	[ctx saveGraphicsState];
	
	[self drawKnob];
	
	[ctx restoreGraphicsState];
}

- (void)drawKnob
{	
	if (isVertical) {
		NSRect knobRect = [self rectForPart:NSScrollerKnob];
		
		knobRect = NSInsetRect(knobRect, 4, 0);
				
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:4 yRadius:4];
		[path addClip];
		
		if ([[[self superview] window] isKeyWindow]) {
			[[NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.70 alpha:0.80] set];
		}
		else {
			[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:0.80] set];
		}
		
		NSRectFill(knobRect);
	}
	else {
		NSRect knobRect = [self rectForPart:NSScrollerKnob];
		
		knobRect = NSInsetRect(knobRect, 0, 4);
		
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:4 yRadius:4];
		[path addClip];
		
		if ([[[self superview] window] isKeyWindow]) {
			[[NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.70 alpha:0.80] set];
		}
		else {
			[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:0.80] set];
		}
		
		NSRectFill(knobRect);
	}
}


+ (CGFloat)scrollerWidth
{
	return 12.0f;
}

+ (CGFloat)scrollerWidthForControlSize:(NSControlSize)controlSize
{
	return 12.0f;
}

+ (CGFloat)scrollerHeight
{
	return 12.0f;
}

+ (CGFloat)scrollerHeightForControlSize:(NSControlSize)controlSize
{
	return 12.0f;
}


@end
