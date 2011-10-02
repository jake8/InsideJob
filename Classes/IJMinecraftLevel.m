//
//  IJMinecraftLevel.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJMinecraftLevel.h"
#import "IJInventoryItem.h"

@implementation IJMinecraftLevel

- (NBTContainer *)containerWithName:(NSString *)theName inArray:(NSArray *)array
{
	for (NBTContainer *container in array)
	{
		if ([container.name isEqual:theName])
			return container;
	}
	return nil;
}

- (NBTContainer *)inventoryList
{
	// Inventory is found in:
	// - compound "Data"
	//   - compound "Player"
	//     - list "Inventory"
	//       *
	NBTContainer *dataCompound = [self childNamed:@"Data"];
	NBTContainer *playerCompound = [dataCompound childNamed:@"Player"];
	NBTContainer *inventoryList = [playerCompound childNamed:@"Inventory"];
	// TODO: Check for error conditions here.
	return inventoryList;
}

- (NSArray *)inventory
{
	NSMutableArray *output = [NSMutableArray array];
	for (NSArray *listItems in [self inventoryList].children)
	{
		IJInventoryItem *invItem = [[IJInventoryItem alloc] init];
		
		invItem.itemId = [[self containerWithName:@"id" inArray:listItems].numberValue shortValue];
		invItem.count = [[self containerWithName:@"Count" inArray:listItems].numberValue unsignedCharValue];
		invItem.damage = [[self containerWithName:@"Damage" inArray:listItems].numberValue shortValue];
		invItem.slot = [[self containerWithName:@"Slot" inArray:listItems].numberValue unsignedCharValue];
		[output addObject:invItem];
		[invItem release];
	}
	return output;
}

- (void)setInventory:(NSArray *)newInventory
{
	NSMutableArray *newChildren = [NSMutableArray array];
	NBTContainer *inventoryList = [self inventoryList];
	
	if (inventoryList.listType != NBTTypeCompound)
	{
		// There appears to be a bug in the way Minecraft writes empty inventory lists; it appears to
		// set the list type to 'byte', so we will correct it here.
		NSLog(@"%s Fixing inventory list type; was %d.", __PRETTY_FUNCTION__, inventoryList.listType);
		inventoryList.listType = NBTTypeCompound;
	}
	
	for (IJInventoryItem *invItem in newInventory)
	{
		NSArray *listItems = [NSArray arrayWithObjects:
							  [NBTContainer containerWithName:@"id" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.itemId]],
							  [NBTContainer containerWithName:@"Damage" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.damage]],
							  [NBTContainer containerWithName:@"Count" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.count]],
							  [NBTContainer containerWithName:@"Slot" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.slot]],
							  nil];
		[newChildren addObject:listItems];
	}
	inventoryList.children = newChildren;
}

- (NBTContainer *)worldTimeContainer
{
	return [[self childNamed:@"Data"] childNamed:@"Time"];
}

- (NBTContainer *)worldSeedContainer
{
	return [[self childNamed:@"Data"] childNamed:@"RandomSeed"];
}

- (NBTContainer *)worldNameContainer
{
	return [[self childNamed:@"Data"] childNamed:@"LevelName"];
}

- (NBTContainer *)worldGameModeContainer
{
	return [[self childNamed:@"Data"] childNamed:@"GameType"];
}



#pragma mark -
#pragma mark Helpers

+ (BOOL)worldExistsAtPath:(NSString *)worldPath
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self levelDataPathForWorld:worldPath]];
}

+ (NSString *)levelDataPathForWorld:(NSString *)worldPath
{
	return [worldPath stringByAppendingPathComponent:@"level.dat"];
}

+ (NSData *)dataWithInt64:(int64_t)v
{
	NSMutableData *data = [NSMutableData data];
	uint32_t v0 = htonl(v >> 32);
	uint32_t v1 = htonl(v);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
	return data;
}
+ (int64_t)int64FromData:(NSData *)data
{
	uint8_t *bytes = (uint8_t *)[data bytes];
	uint64_t n = ntohl(*((uint32_t *)(bytes + 0)));
	n <<= 32;
	n += ntohl(*((uint32_t *)(bytes + 4)));
	return n;
}

+ (int64_t)writeToSessionLockAtPath:(NSString *)worldPath
{
	NSString *path = [worldPath stringByAppendingPathComponent:@"session.lock"];
	NSDate *now = [NSDate date];
	NSTimeInterval interval = [now timeIntervalSince1970];
	int64_t milliseconds = (int64_t)(interval * 1000.0);
	// write as number of milliseconds
	
	NSData *data = [self dataWithInt64:milliseconds];
	[data writeToFile:path atomically:YES];
	
	return milliseconds;
}

+ (BOOL)checkSessionLockAtPath:(NSString *)worldPath value:(int64_t)checkValue
{
	NSString *path = [worldPath stringByAppendingPathComponent:@"session.lock"];
	NSData *data = [NSData dataWithContentsOfFile:path];
    
	if (!data)
	{
		NSLog(@"Failed to read session lock at %@", path);
		return NO;
	}
	
	int64_t milliseconds = [self int64FromData:data];
	return checkValue == milliseconds;
}


@end
