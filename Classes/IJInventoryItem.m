//
//  IJInventoryItem.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryItem.h"


@implementation IJInventoryItem

@synthesize itemId, slot, damage, count;

+ (id)emptyItemWithSlot:(uint8_t)slot
{
	IJInventoryItem *obj = [[[[self class] alloc] init] autorelease];
	obj.slot = slot;
	return obj;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		itemId = [decoder decodeIntForKey:@"itemId"];
		slot = [decoder decodeIntForKey:@"slot"];
		damage = [decoder decodeIntForKey:@"damage"];
		count = [decoder decodeIntForKey:@"count"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:itemId forKey:@"itemId"];
	[coder encodeInt:slot forKey:@"slot"];
	[coder encodeInt:damage forKey:@"damage"];
	[coder encodeInt:count forKey:@"count"];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p itemId=%d name=%@ count=%d slot=%d damage=%d",
			NSStringFromClass([self class]), self, itemId, self.humanReadableName, count, slot, damage];
}

- (NSString *)humanReadableName
{
	NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:[NSNumber numberWithShort:self.itemId]];
	NSString *name = [itemData objectForKey:@"Name"];
	if (name) {
		name = [name stringByAppendingString:[NSString stringWithFormat:@" (%d)", self.itemId]];
		return name;
	}
	else
		return [NSString stringWithFormat:@"%d", self.itemId];
}

+ (NSImage *)imageForItemId:(uint16_t)itemId withDamage:(uint16_t)damage
{
	NSSize itemImageSize = NSMakeSize(32, 32);
	NSPoint atlasOffset;
	NSUInteger itemsPerRow = 9;
	NSUInteger pixelsPerColumn = 36;
	NSUInteger pixelsPerRow = 56;
	NSImage *atlas;
	BOOL notFound = FALSE; 
	
	int index = 0;
	
	// Blocks
	if ((itemId <= 25 || (itemId >= 27 && itemId <= 33) || (itemId >= 35 && itemId <= 109) || (itemId == 96)) &&
			(itemId != 36 || itemId != 95))
	{
		if (itemId <= 5) {
			index = itemId - 1;
		}
		else if (itemId == 6) {
			if (damage > 2)
				damage = 0;
			index = itemId - 1 + damage;			
		}
		else if (itemId <= 16) {
			index = itemId + 1;
		}
		else if (itemId == 17) {
			if (damage > 2)
				damage = 0;
			index = itemId + 1 + damage;
		}
		else if (itemId <= 34) {
			index = itemId + 3;		
		}
		else if (itemId == 35) {
			if (damage > 15)
				damage = 0;
			index = itemId + 10 + damage;
		}
		else if (itemId <= 43) {
			index = itemId + 24;
		}
		else if (itemId == 44) {
			if (damage > 5)
				damage = 0;
			index = itemId + 24 + damage;
		}
		else if (itemId <= 109) {
			index = itemId + 36;
		}

		atlasOffset = NSMakePoint(36, 75);
	}
	// Items
	else if (itemId >= 256 && itemId <= 368)
	{
		index = itemId - 256;
		if (itemId >= 352 && itemId <= 368)
			index = itemId - 241;
		if (itemId == 351) {
			if (damage > 15)
				damage = 0;
			index = itemId - 256 + damage;
		}

		atlasOffset = NSMakePoint(445, 75);
	}
	else if (itemId >= 2256 && itemId <= 2257 )
	{
		index = itemId - 2222;
		atlasOffset = NSMakePoint(445, pixelsPerRow*14+18);
	}
	else
	{
		NSLog(@"%s error: unrecognized item id %d", __PRETTY_FUNCTION__, itemId);
		index = 0;
		atlasOffset = NSMakePoint(1, 30);
		notFound = TRUE;
	}
	
	atlasOffset.x += pixelsPerColumn * (index % itemsPerRow);
	atlasOffset.y += pixelsPerRow    * (index / itemsPerRow);
	
	NSRect atlasRect = NSMakeRect(atlasOffset.x, atlasOffset.y, itemImageSize.width, itemImageSize.height);
	
	if (notFound != TRUE) {
		atlas = [NSImage imageNamed:@"DataValuesV110Transparent.png"];
	}else {
		atlas = [NSImage imageNamed:@"blockNotFound.png"];
	}

	NSImage *output = [[NSImage alloc] initWithSize:itemImageSize];
	
	atlasRect.origin.y = atlas.size.height - atlasRect.origin.y;
	
	[NSGraphicsContext saveGraphicsState];
	
	[output lockFocus];
	
	[atlas drawInRect:NSMakeRect(0, 0, itemImageSize.width, itemImageSize.height)
			 fromRect:atlasRect
			operation:NSCompositeCopy
			 fraction:1.0];
	
	[output unlockFocus];
	
	[NSGraphicsContext restoreGraphicsState];
	
	return [output autorelease];
}

- (NSImage *)image
{
	return [IJInventoryItem imageForItemId:itemId withDamage:damage];
}

+ (NSDictionary *)itemIdLookup
{
	static NSDictionary *lookup = nil;
	if (!lookup)
	{
		NSError *error = nil;
    NSString *lines = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Items" withExtension:@"csv"]
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
		NSMutableDictionary *building = [NSMutableDictionary dictionary];
		[lines enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"#"] || [line length] == 0) // ignore lines with a # prefix or empty ones
				return;
			NSArray *components = [line componentsSeparatedByString:@","];
			if ([components count] == 0)
				return;
			NSNumber *itemId = [NSNumber numberWithShort:[[components objectAtIndex:0] intValue]];
			
			NSNumber *itemDamage = [NSNumber numberWithShort:0];
			if ([components count] > 2) {
				itemDamage = [NSNumber numberWithShort:[[components objectAtIndex:2] intValue]];
			}
			NSString *itemName = [components objectAtIndex:1];

			NSArray *objects = [NSArray arrayWithObjects:itemName, itemDamage, nil];
			NSArray *keys = [NSArray arrayWithObjects:@"Name", @"Damage",nil];
			NSDictionary *itemData = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
			[building setObject:itemData forKey:itemId];
		}];
		lookup = [[NSDictionary alloc] initWithDictionary:building];
	}
	return lookup;
}

@end
