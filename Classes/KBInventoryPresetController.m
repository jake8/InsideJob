//
//  KBInventoryPresetController.m
//  InsideJob
//
//  Created by Ben K on 2011/03/15.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "KBInventoryPresetController.h"
#import "IJInventoryWindowController.h"
#import "IJInventoryItem.h"
#import "BWSheetController.h"


@implementation KBInventoryPresetController
@synthesize presetArray;



#pragma mark -
#pragma mark Initialization

-(void)awakeFromNib
{
	presetArray = [[NSMutableArray alloc] init];
	
	armorInventory = [[NSMutableArray alloc] init];
	quickInventory = [[NSMutableArray alloc] init];
	normalInventory = [[NSMutableArray alloc] init];	
	
	//Checks to see AppSupport folder exits if not create it.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *folderPath = [@"~/Library/Application Support/Inside Job/" stringByExpandingTildeInPath];
	if ([fileManager fileExistsAtPath: folderPath] == NO) {
		[fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:NULL];
	}
	
	[self reloadPresetList];
}



#pragma mark -
#pragma mark Actions

- (IBAction)savePreset:(id)sender
{
	if ([[newPresetName stringValue] isEqualToString:@""]) {
		[newPresetSheetController setSheetErrorMessage:@"Fill in a preset name."];
		return;
	}
	
	NSString *folderPath = [@"~/Library/Application Support/Inside Job/" stringByExpandingTildeInPath];
	NSString *presetPath = [folderPath stringByAppendingPathComponent:[newPresetName stringValue]];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: presetPath]) {
		[newPresetSheetController setSheetErrorMessage:@"A preset with that name already exists."];
		return;
	}
		
	NSArray *inventoryData = [inventoryController currentInventory];
	NSMutableArray *newPreset = [NSMutableArray array];
	
	int index;
	for (index = 0; index < [inventoryData count]; index++) {
		IJInventoryItem *item = [inventoryData objectAtIndex:index];
		if (item.count > 0 && item.itemId > 0) {
			[newPreset addObject:item];
		}
	}
	
	[NSKeyedArchiver archiveRootObject:newPreset toFile:presetPath];
	
	[newPresetSheetController closeSheet:self];
	[newPresetSheetController setSheetErrorMessage:@""];
	
	[self reloadPresetList];
}

- (IBAction)deletePreset:(id)sender
{
	NSString *presetPath = [sender representedObject];	
	[[NSFileManager defaultManager] removeItemAtPath:presetPath error:NULL];
	[self reloadPresetList];
}

- (IBAction)loadPreset:(id)sender
{
	NSString *presetPath = [sender representedObject];	
	NSArray *newInventory = [NSKeyedUnarchiver unarchiveObjectWithFile:presetPath];
	
	[inventoryController clearInventory];
	[inventoryController setInventory:newInventory];
}


#pragma mark -
#pragma mark Methods

- (void)reloadPresetList
{
	[presetMenu removeAllItems];
	[presetArray removeAllObjects];

	NSString *folderPath = [@"~/Library/Application Support/Inside Job/" stringByExpandingTildeInPath];
	NSArray *folderArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:NULL];
	
	int index;
	for (index = 0; index < [folderArray count]; index++) {
		NSString *fileName = [folderArray objectAtIndex:index];
		NSString *filePath = [folderPath stringByAppendingPathComponent:[folderArray objectAtIndex:index]];
		
		NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
		
		if (![[fileAttr valueForKey:NSFileType] isEqualToString:NSFileTypeRegular])
			continue;
		
		if ([fileName hasPrefix:@"."])
			continue;
		
		[presetArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
														fileName, @"Name",
														filePath, @"Path",
														nil]];
	}	
	
	if ([presetArray count] == 0) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
		[menuItem setTitle:@"No Presets Saved"];
		[menuItem setEnabled:NO];
		[presetMenu addItem:menuItem];
	}
	else {
		for (index = 0; index < [presetArray count]; index++) {
			NSDictionary *itemData = [presetArray objectAtIndex:index];
			
			NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
			[menuItem setTitle:[itemData valueForKey:@"Name"]];
			[menuItem setRepresentedObject:[itemData valueForKey:@"Path"]];
			[menuItem setTarget:self];
			[menuItem setAction:@selector(loadPreset:)];
			[presetMenu addItem:menuItem];
			
			NSMenuItem *menuItemDelete = [[[NSMenuItem alloc] init] autorelease];
			[menuItemDelete setTitle:[NSString stringWithFormat:@"Delete %@",[itemData valueForKey:@"Name"]]];
			[menuItemDelete setRepresentedObject:[itemData valueForKey:@"Path"]];
			[menuItemDelete setAlternate:YES];
			[menuItemDelete setKeyEquivalentModifierMask:NSAlternateKeyMask];
			[menuItemDelete setTarget:self];
			[menuItemDelete setAction:@selector(deletePreset:)];
			[presetMenu addItem:menuItemDelete];
		}
	}
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if (anItem.action == @selector(loadPreset:))
		return inventoryController.inventory != nil;
	if (anItem.action == @selector(deletePreset:))
		return inventoryController.inventory != nil;

	return YES;
}


#pragma mark -
#pragma mark Cleanup

- (void)dealloc
{
	[presetArray release];
	[armorInventory release];
	[quickInventory release];
	[normalInventory release];	
	[super dealloc];
}

@end
