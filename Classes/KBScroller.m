//
//  KBScroller.m
//  IRCBot
//
//  Created by Ben K on 2010/11/21.
//  All code is provided under the New BSD license.
//

#import "KBScroller.h"

@implementation KBScroller
@synthesize overlaysContent;


- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		[self setArrowsPosition:NSScrollerArrowsNone];	
		if ([self bounds].size.width / [self bounds].size.height < 1) {
			isVertical = YES;
		} else {
			isVertical = NO;
		}
		overlaysContent = YES;
	}
	return self;
}


- (void)setOverlaysContent:(BOOL)flag
{
	NSLog(@"setTransparentScroller");
	overlaysContent = flag;
}

- (void)drawRect:(NSRect)aRect
{	
	// Background
	[[(NSScrollView *)[self superview] backgroundColor] set];
	NSRectFill([self bounds]);
	
	// Slot
	NSBezierPath *bz = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 4, 4) xRadius:4 yRadius:4];
	[bz addClip];
	[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
	NSRectFill([self bounds]);

	
	// Knob
	if ([self knobProportion] > 0.0) {
		
		if (isVertical) {
			NSRect knobRect;
			NSRect slotRect = [self rectForPart:NSScrollerKnobSlot];			
		
			float knobHeight = roundf(slotRect.size.height * [self knobProportion]);
		
			if (knobHeight < 40)
				knobHeight = 40;
		
			float knobY = slotRect.origin.y + roundf((slotRect.size.height - knobHeight) * [self floatValue]);
			knobRect = NSMakeRect(4, knobY, 7, knobHeight);
		
			NSBezierPath *bz = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:4 yRadius:4];
			[bz addClip];
			
			if (overlaysContent) {
				if ([[[self superview] window] isKeyWindow]) {
					[[NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.70 alpha:0.80] set];
				}
				else {
					[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:0.80] set];
				}
			}
			else {
				if ([[[self superview] window] isKeyWindow]) {
					[[NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.70 alpha:0.80] set];
				}
				else {
					[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:0.80] set];
				}				
			}

			NSRectFill(knobRect);
		}
		else {
			NSRect knobRect;
			NSRect slotRect = [self rectForPart:NSScrollerKnobSlot];			
			
			float knobWidth = roundf(slotRect.size.width * [self knobProportion]);
			
			if (knobWidth < 25)
				knobWidth = 25;
			
			float knobX = slotRect.origin.x + roundf((slotRect.size.width - knobWidth) * [self floatValue]);
			knobRect = NSMakeRect(knobX, 4, knobWidth, 8);
			
			NSBezierPath *bz = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:4 yRadius:4];
			[bz addClip];

			if (overlaysContent) {
				if ([[[self superview] window] isKeyWindow]) {
					[[NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.70 alpha:0.80] set];
				}
				else {
					[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:0.80] set];
				}
			}
			else {
				if ([[[self superview] window] isKeyWindow]) {
					[[NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.70 alpha:0.80] set];
				}
				else {
					[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:0.80] set];
				}				
			}
			
			NSRectFill(knobRect);
		}
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
