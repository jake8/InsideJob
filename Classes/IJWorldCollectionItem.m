//
//  IJWorldCollectionItem.m
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJWorldCollectionItem.h"


@implementation IJWorldCollectionItem
@synthesize worldName;
@synthesize worldMeta;
@synthesize worldIcon;

- (id)init
{
	self = [super init];
	if (self != nil) {
		worldPath = [[NSString alloc] init];
	}
	return self;
}

-(id)copyWithZone:(NSZone *)zone
{
	id result = [super copyWithZone:zone];
	[NSBundle loadNibNamed:@"WorldCollectionItem" owner:result];
	return result;
}


- (void)setRepresentedObject:(id)object {
	[super setRepresentedObject: object];
	
	if (object == nil) 
		return;
	
	NSDictionary* data	= (NSDictionary*) [self representedObject];	
	
	self.worldName	= (NSString*)[data valueForKey:@"Name"];	
	self.worldMeta	= (NSString*)[data valueForKey:@"Meta"];
	self.worldIcon	= (NSImage*)[data valueForKey:@"Icon"];
	worldPath = (NSString*)[data valueForKey:@"Path"];
	delegate = [data valueForKey:@"Delegate"];
	
}

-(void)setSelected:(BOOL)flag
{
	[super setSelected:flag];
	if (flag == YES) {
		[selectionBox setBorderColor:[NSColor grayColor]];
		[selectionBox setFillColor:[NSColor whiteColor]];
	} else {
		[selectionBox setBorderColor:[NSColor clearColor]];
		[selectionBox setFillColor:[NSColor clearColor]];
	}
}

-(void)doubleClick:(id)sender
{
	if(delegate && [delegate respondsToSelector:@selector(openWorldAtPath:)]) {
		[delegate performSelector:@selector(openWorldAtPath:) withObject:worldPath];
	}
}


- (void) dealloc
{
	[worldPath release];
	[super dealloc];
}


@end
