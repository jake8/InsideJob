//
//  IJCollectionView.m
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJCollectionView.h"


@implementation IJCollectionView

- (NSView *)hitTest:(NSPoint)aPoint
{
	// don't allow any mouse clicks for subviews in this view
	if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
		return self;
	} else {
		return nil;    
	}
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	
	// check for click count above one, which we assume means it's a double click
	if([theEvent clickCount] > 1) {
		if(delegate && [delegate respondsToSelector:@selector(doubleClick:)]) {
			[delegate performSelector:@selector(doubleClick:) withObject:self];
		}
	}
}

@end
