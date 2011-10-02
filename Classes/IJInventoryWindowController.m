//
//  IJInventoryWindowController.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryWindowController.h"
#import "IJMinecraftLevel.h"
#import "IJInventoryItem.h"
#import "IJInventoryView.h"
#import "IJItemPropertiesViewController.h"
#import "IJWorldCollectionController.h"
#import "MAAttachedWindow.h"
#import "BWSheetController.h"


@implementation IJInventoryWindowController
@synthesize inventory;
@synthesize inventoryView, quickView, armorView;
@synthesize gameModeSegmentedControl;
@synthesize statusTextField;
@synthesize contentView;


#pragma mark -
#pragma mark Initialization

- (void)awakeFromNib
{	
	loadedWorldPath = [[NSString alloc] init];
	loadedPlayerName = [[NSString alloc] initWithString:@"Default_Player"];
	attemptedLoadWorldPath = [[NSString alloc] init];
	
	armorInventory = [[NSMutableArray alloc] init];
	quickInventory = [[NSMutableArray alloc] init];
	normalInventory = [[NSMutableArray alloc] init];
	statusTextField.stringValue = @"";
	
	[inventoryView setRows:3 columns:9 invert:NO];
	[quickView setRows:1 columns:9 invert:NO];
	[armorView setRows:4 columns:1 invert:YES];
	inventoryView.delegate = self;
	quickView.delegate = self;
	armorView.delegate = self;
	
	// Item Table View setup
	NSArray *keys = [[IJInventoryItem itemIdLookup] allKeys];
	//NSLog(@"Item CVS Data:\n%@",[IJInventoryItem itemIdLookup]);
	keys = [keys sortedArrayUsingSelector:@selector(compare:)];
	allItemIds = [[NSArray alloc] initWithArray:keys];
	filteredItemIds = [allItemIds retain];
	
	[itemTableView setTarget:self];
	[itemTableView setDoubleAction:@selector(itemTableViewDoubleClicked:)];
	[contentView selectTabViewItemAtIndex:0];
}


#pragma mark -
#pragma mark World Selection

- (BOOL)loadWorldAtPath:(NSString *)worldPath;
{
	NSString *levelPath = [worldPath stringByExpandingTildeInPath];
	
	if ([self isDocumentEdited])
	{
		[attemptedLoadWorldPath release];
		attemptedLoadWorldPath = [levelPath copy];
		// Note: We use the didDismiss selector so that any subsequent alert sheets don't bugger up
		NSBeginAlertSheet(@"Do you want to save the changes you made in this world?", @"Save", @"Don't Save", @"Cancel", self.window, self, nil, @selector(dirtyOpenSheetDidEnd:returnCode:contextInfo:), @"Load", 
                          @"Your changes will be lost if you do not save them.");
		return NO;
	}
	
	if (![IJMinecraftLevel worldExistsAtPath:levelPath])
	{
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                  @"Inside Job was unable to locate the level.dat file.");
		return NO;
	}	
	
	sessionLockValue = [IJMinecraftLevel writeToSessionLockAtPath:levelPath];
	if (![IJMinecraftLevel checkSessionLockAtPath:levelPath value:sessionLockValue])
	{
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                  @"Inside Job was unable obtain the session lock.");
		return NO;
	}
	
	NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[IJMinecraftLevel levelDataPathForWorld:levelPath]]];	
	if (!fileData)
	{
		// Error loading 
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                  @"InsideJob was unable to load the level.dat file at:/n%@", levelPath);
		return NO;
	}
	
	// Add to recent files, if the world isn't in the 'minecraft/saves' folder
	if ([self worldFolderContainsPath:levelPath]) {
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:levelPath]];
	}
	
	[self unloadWorld];
	
	[self willChangeValueForKey:@"worldTime"];
	[self willChangeValueForKey:@"levelName"];
    [self willChangeValueForKey:@"gameMode"];
	
	level = [[IJMinecraftLevel nbtContainerWithData:fileData] retain];
	inventory = [[level inventory] retain];
	
	[self didChangeValueForKey:@"worldTime"];
	[self didChangeValueForKey:@"levelName"];
    [self didChangeValueForKey:@"gameMode"];
	
	// Overwrite the placeholders with actual inventory:
	for (IJInventoryItem *item in inventory) {
		// Add a KVO so that we can set the document as edited when the count or damage values are changed.
		[item addObserver:self forKeyPath:@"count" options:0 context:@"KVO_COUNT_CHANGED"];
		[item addObserver:self forKeyPath:@"damage" options:0 context:@"KVO_DAMAGE_CHANGED"];
		
		if (IJInventorySlotQuickFirst <= item.slot && item.slot <= IJInventorySlotQuickLast)
		{
			[quickInventory replaceObjectAtIndex:item.slot - IJInventorySlotQuickFirst withObject:item];
		}
		else if (IJInventorySlotNormalFirst <= item.slot && item.slot <= IJInventorySlotNormalLast) {
			[normalInventory replaceObjectAtIndex:item.slot - IJInventorySlotNormalFirst withObject:item];
		}
		else if (IJInventorySlotArmorFirst <= item.slot && item.slot <= IJInventorySlotArmorLast) {
			[armorInventory replaceObjectAtIndex:item.slot - IJInventorySlotArmorFirst withObject:item];
		}
	}
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
    
    [gameModeSegmentedControl setSelectedSegment:[self gameMode].integerValue];
    
	[self setDocumentEdited:NO];
	statusTextField.stringValue = @"";
    
	[loadedWorldPath release];
	loadedWorldPath = [levelPath copy];
	[contentView selectTabViewItemAtIndex:1];
	NSString *statusMessage = [NSString stringWithFormat:@"Loaded world: %@",[loadedWorldPath lastPathComponent]];
	[statusTextField setStringValue:statusMessage];
	[contentView selectTabViewItemAtIndex:1];
    
	return YES;
}

- (void)saveWorld
{
	NSString *levelPath = loadedWorldPath;
	if (inventory == nil)
		return; // no world loaded, nothing to save
	
	if (![IJMinecraftLevel checkSessionLockAtPath:levelPath value:sessionLockValue]) {
		NSBeginCriticalAlertSheet(@"Another application has modified this world.", @"Reload", nil, nil, self.window, self, @selector(sessionLockAlertSheetDidEnd:returnCode:contextInfo:), nil, nil, 
                                  @"The session lock was changed by another application.");
		return;
	}
    
	NSMutableArray *newInventory = [NSMutableArray array];
	for (NSArray *items in [NSArray arrayWithObjects:armorInventory, quickInventory, normalInventory, nil]) {
		for (IJInventoryItem *item in items) {
			// Validate item count
			if (item.count < -1)
				[item setCount:-1];
			if (item.count > 64)
				[item setCount:64];
            
			// Add item if it's valid
			if ((item.count > 0 || item.count == -1) && item.itemId > 0)
				[newInventory addObject:item];
		}
	}
    
	[level setInventory:newInventory];
	
	NSString *dataPath = [IJMinecraftLevel levelDataPathForWorld:levelPath];
	NSString *backupPath = [dataPath stringByAppendingPathExtension:@"insidejobbackup"];
	
	BOOL success = NO;
	NSError *error = nil;
	
	// Remove a previously-created .insidejobbackup, if it exists:
	
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath]) {
		success = [[NSFileManager defaultManager] removeItemAtPath:backupPath error:&error];
		if (success != YES) {
			NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                      @"Inside Job was unable to remove the prior backup of this level file.", [error localizedDescription]);
			return;
		}
	}
	
	// Create the backup:
	success = [[NSFileManager defaultManager] copyItemAtPath:dataPath toPath:backupPath error:&error];
	if (success != YES) {
		NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
		NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                  @"Inside Job was unable to create a backup of the existing level file.", [error localizedDescription]);
		return;
	}
	
	
	// Write the new level.dat out:
	success = [[level writeData] writeToURL:[NSURL fileURLWithPath:dataPath] options:0 error:&error];
	if (success != YES) {
		NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
		
		NSError *restoreError = nil;
		success = [[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:dataPath error:&restoreError];
		if (success != YES) {
			NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [restoreError localizedDescription]);
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                      @"Inside Job was unable to save to the existing level file, and the backup could not be restored.", [error localizedDescription], [restoreError localizedDescription]);
		} else {
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
                                      @"Inside Job was unable to save to the existing level file, and the backup was successfully restored.", [error localizedDescription]);
		}
		return;
	}
	
	[self setDocumentEdited:NO];
	statusTextField.stringValue = @"World saved.";
}

- (void)dirtyOpenSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{	
	if (returnCode == NSAlertDefaultReturn) // Save
	{
		if ([(NSString *)contextInfo isEqualToString:@"Load"]) {
			[self saveWorld];
			[self loadWorldAtPath:attemptedLoadWorldPath];
		}
		else {
			[self saveWorld];
			[self unloadWorld];
			[contentView selectTabViewItemAtIndex:0];
		}		
	}
	else if (returnCode == NSAlertAlternateReturn) // Don't save
	{
		[self setDocumentEdited:NO]; // Slightly hacky -- prevent the alert from being put up again.
		if ([(NSString *)contextInfo isEqualToString:@"Load"]) {
			[self loadWorldAtPath:attemptedLoadWorldPath];
		}
		else {
			[self unloadWorld];
			[contentView selectTabViewItemAtIndex:0];
		}
	}
	
}

- (void)sessionLockAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{	
	[self setDocumentEdited:NO];
	[self loadWorldAtPath:loadedWorldPath];
}

- (void)setDocumentEdited:(BOOL)edited
{
	[super setDocumentEdited:edited];
	if (edited)
		statusTextField.stringValue = @"World has unsaved changes.";
}

- (BOOL)isDocumentEdited
{
	return [self.window isDocumentEdited];
}


#pragma mark -
#pragma mark Actions

- (IBAction)openWorld:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    // Set up the panel
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    
    // Display the NSOpenPanel
    [openPanel beginWithCompletionHandler:^(NSInteger runResult){
        if (runResult == NSFileHandlingPanelOKButton) {
            NSString *filePath = [[[openPanel URLs] objectAtIndex:0] path]; 
            [self loadWorldAtPath:filePath];
        }
    }];
}

- (IBAction)reloadWorldInformation:(id)sender
{	
	if (loadedWorldPath != nil && ![loadedWorldPath isEqualToString:@""])
		[self loadWorldAtPath:loadedWorldPath];
}

- (IBAction)showWorldSelector:(id)sender
{
	if ([self isDocumentEdited])
	{
		// Note: We use the didDismiss selector so that any subsequent alert sheets don't bugger up
		NSBeginAlertSheet(@"Do you want to save the changes you made in this world?", @"Save", @"Don't Save", @"Cancel", self.window, self, nil, @selector(dirtyOpenSheetDidEnd:returnCode:contextInfo:), @"Select", 
                          @"Your changes will be lost if you do not save them.");
		return;
	}
	
	// Clear inventory and unload world
	[self unloadWorld];
	
	// Show world selector
	[worldCollectionController reloadWorldData];
	[contentView selectTabViewItemAtIndex:0];
}

- (IBAction)addItem:(id)sender
{
	int16_t itemID = [newItemField intValue];
	if (itemID <= 0) {
		[newItemSheetController setSheetErrorMessage:@"Invalid item id."];
		return;
	}
	
	[newItemSheetController closeSheet:self];
	[newItemSheetController setSheetErrorMessage:@""];
	[self addInventoryItem:itemID selectItem:YES];
}

- (IBAction)clearInventoryItems:(id)sender
{
	[self setDocumentEdited:YES];
	[self clearInventory];
}

- (IBAction)copyWorldSeed:(id)sender
{
	NSString *worldSeed = [NSString stringWithFormat:@"%@",[level worldSeedContainer].numberValue];
	
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
	[pb declareTypes:types owner:self];
	[pb setString:worldSeed forType:NSStringPboardType];
}

- (IBAction)incrementTime:(id)sender
{
	if ([sender selectedSegment] == 0) {		
		int wTime = [[self worldTime] intValue];
		int result = wTime - (24000 - (wTime % 24000));
		[self setWorldTime:[NSNumber numberWithInt:result]];
	}
	else if ([sender selectedSegment] == 1) {
		int wTime = [[self worldTime] intValue];
		int result = wTime + (24000 - (wTime % 24000));
		[self setWorldTime:[NSNumber numberWithInt:result]];
	}
}

- (NSNumber *)gameMode
{
    return [level worldGameModeContainer].numberValue;
}

- (void)setGameMode:(NSNumber *)gameMode
{
    [self willChangeValueForKey:@"gameMode"];
	[level worldGameModeContainer].numberValue = gameMode;
	[self didChangeValueForKey:@"gameMode"];
	[self setDocumentEdited:YES];
}

- (IBAction)changeGameMode:(id)sender {
    [self setGameMode:[NSNumber numberWithInt:[sender selectedSegment]]];
}

- (void)saveDocument:(id)sender
{
	[self saveWorld];
}

- (void)delete:(id)sender
{
    //	IJInventoryItem *item = [outlineView itemAtRow:[outlineView selectedRow]];
    //	item.count = 0;
    //	item.itemId = 0;
    //	item.damage = 0;
    //	[self setDocumentEdited:YES];
    //	[outlineView reloadItem:item];
}

- (BOOL)worldFolderContainsPath:(NSString *)path
{
	NSString *filePath = [path stringByStandardizingPath];
	NSString *worldFolder = [[@"~/library/application support/minecraft/saves/" stringByExpandingTildeInPath] stringByStandardizingPath];
    
	if (![[filePath stringByDeletingLastPathComponent] isEqualToString:worldFolder]) {
		return YES;
	}
	return NO;
}

- (IBAction)makeSearchFieldFirstResponder:(id)sender
{
	[itemSearchField becomeFirstResponder];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if (anItem.action == @selector(saveDocument:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(reloadWorldInformation:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(showWorldSelector:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(copyWorldSeed:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(clearInventoryItems:)) {
		return inventory != nil;
	}
	return YES;
}

- (NSNumber *)worldTime
{
	return 	[level worldTimeContainer].numberValue;
}

- (void)setWorldTime:(NSNumber *)number
{
	[self willChangeValueForKey:@"worldTime"];
	[level worldTimeContainer].numberValue = number;
	[self didChangeValueForKey:@"worldTime"];
	[self setDocumentEdited:YES];
}

- (NSString *)levelName
{
	return 	[level worldNameContainer].stringValue;
}

- (void)setLevelName:(NSString *)name
{
	[self willChangeValueForKey:@"levelName"];
	[level worldNameContainer].stringValue = name;
	[self didChangeValueForKey:@"levelName"];
	[self setDocumentEdited:YES];
}


#pragma mark -
#pragma mark IJInventoryViewDelegate

- (IJInventoryView *)inventoryViewForItemArray:(NSMutableArray *)theItemArray
{
	if (theItemArray == normalInventory) {
		return inventoryView;
	}
	if (theItemArray == quickInventory) {
		return quickView;
	}
	if (theItemArray == armorInventory) {
		return armorView;
	}
	return nil;
}

- (NSMutableArray *)itemArrayForInventoryView:(IJInventoryView *)theInventoryView slotOffset:(int*)slotOffset
{
	if (theInventoryView == inventoryView) {
		if (slotOffset) *slotOffset = IJInventorySlotNormalFirst;
		return normalInventory;
	}
	else if (theInventoryView == quickView) {
		if (slotOffset) *slotOffset = IJInventorySlotQuickFirst;
		return quickInventory;
	}
	else if (theInventoryView == armorView) {
		if (slotOffset) *slotOffset = IJInventorySlotArmorFirst;
		return armorInventory;
	}
	return nil;
}

- (void)inventoryView:(IJInventoryView *)theInventoryView removeItemAtIndex:(int)itemIndex
{
	int slotOffset = 0;
	NSMutableArray *itemArray = [self itemArrayForInventoryView:theInventoryView slotOffset:&slotOffset];
	
	if (itemArray) {
		IJInventoryItem *item = [IJInventoryItem emptyItemWithSlot:slotOffset + itemIndex];
		[itemArray replaceObjectAtIndex:itemIndex withObject:item];
		[theInventoryView setItems:itemArray];
	}
	[self setDocumentEdited:YES];
}

- (void)inventoryView:(IJInventoryView *)theInventoryView setItem:(IJInventoryItem *)item atIndex:(int)itemIndex
{
	int slotOffset = 0;
	NSMutableArray *itemArray = [self itemArrayForInventoryView:theInventoryView slotOffset:&slotOffset];
	
	if (itemArray) {
		[itemArray replaceObjectAtIndex:itemIndex withObject:item];
		item.slot = slotOffset + itemIndex;
		[theInventoryView setItems:itemArray];
	}
	[self setDocumentEdited:YES];
}

- (void)inventoryView:(IJInventoryView *)theInventoryView selectedItemAtIndex:(int)itemIndex
{
	// Show the properties window for this item.
	IJInventoryItem *lastItem = propertiesViewController.item;
	
	NSPoint itemLocationInView = [theInventoryView pointForItemAtIndex:itemIndex];
	NSPoint point = [theInventoryView convertPoint:itemLocationInView toView:nil];
	point.x += 16 + 8;
	point.y -= 16;
	
	NSArray *items = [self itemArrayForInventoryView:theInventoryView slotOffset:nil];
	IJInventoryItem *selectedItem = [items objectAtIndex:itemIndex];
    
	if (selectedItem.itemId == 0 || lastItem == selectedItem) {
		// The window may not be invisible at this point,
		// caused by the MAAttachedWindow not calling NSWindowDidResignKey
		// or the window not resigning key. (This bug needs to be fixed)
		[propertiesWindow setAlphaValue:0.0];
		propertiesViewController.item = nil;
		return; // can't show info on nothing
	}
	
	if (!propertiesViewController) {
		propertiesViewController = [[IJItemPropertiesViewController alloc] initWithNibName:@"ItemPropertiesView" bundle:nil];
		
		propertiesWindow = [[MAAttachedWindow alloc] initWithView:propertiesViewController.view
												  attachedToPoint:point
														 inWindow:self.window
														   onSide:MAPositionRight
													   atDistance:0];
		[propertiesWindow setBackgroundColor:[NSColor controlBackgroundColor]];
		[propertiesWindow setViewMargin:4.0];
		[propertiesWindow setAlphaValue:0.95];
		[propertiesWindow setArrowHeight:10];
		[[self window] addChildWindow:propertiesWindow ordered:NSWindowAbove];
	}
	if (observerObject) {
		[[NSNotificationCenter defaultCenter] removeObserver:observerObject];
	}
	observerObject = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
																	   object:propertiesWindow
																		queue:[NSOperationQueue mainQueue]
																   usingBlock:^(NSNotification *notification) {
																	   [propertiesViewController commitEditing];
                                                                       // Validate item
																	   if (selectedItem.count == 0)
																		   selectedItem.itemId = 0;
                                                                       if (selectedItem.count < -1)
                                                                           selectedItem.count = -1;
                                                                       if (selectedItem.count > 64)
                                                                           selectedItem.count = 64;
                                                                       if (selectedItem.damage < 0)
                                                                           selectedItem.damage = 0;
                                                                       
																	   [theInventoryView reloadItemAtIndex:itemIndex];
																	   [propertiesWindow setAlphaValue:0.0];
																   }];
	propertiesViewController.item = selectedItem;
	[propertiesWindow setPoint:point side:MAPositionRight];
	[propertiesWindow makeKeyAndOrderFront:nil];
	[propertiesWindow setAlphaValue:0.9];
}

#pragma mark -
#pragma mark IJInventoryItemDelegate

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context;
{
	if(context == @"KVO_COUNT_CHANGED"){
		[self setDocumentEdited:YES];
	}	
	if(context == @"KVO_DAMAGE_CHANGED"){
		[self setDocumentEdited:YES];
	}	
}


#pragma mark -
#pragma mark Inventory

- (void)clearInventory
{	
	[armorInventory removeAllObjects];
	[quickInventory removeAllObjects];
	[normalInventory removeAllObjects];
	
	// Add placeholder inventory items:
	for (int i = 0; i < IJInventorySlotQuickLast + 1 - IJInventorySlotQuickFirst; i++) {
		[quickInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotQuickFirst + i]];
	}
	
	for (int i = 0; i < IJInventorySlotNormalLast + 1 - IJInventorySlotNormalFirst; i++) {
		[normalInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotNormalFirst + i]];
	}
	
	for (int i = 0; i < IJInventorySlotArmorLast + 1 - IJInventorySlotArmorFirst; i++) {
		[armorInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotArmorFirst + i]];
	}	
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];	
}

- (void)unloadWorld
{
	[self clearInventory];
	
	[self willChangeValueForKey:@"worldTime"];
	[self willChangeValueForKey:@"levelName"];
	
	[level release];
	level = nil;
	
	for (IJInventoryItem *item in inventory) {
		[item removeObserver:self forKeyPath:@"count"];
		[item removeObserver:self forKeyPath:@"damage"];
	}	
	
	[inventory release];
	inventory = nil;
	[self didChangeValueForKey:@"worldTime"];
	[self didChangeValueForKey:@"levelName"];
	
	statusTextField.stringValue = @"No world loaded.";
}

- (void)loadInventory:(NSArray *)newInventory
{
	[armorInventory removeAllObjects];
	[quickInventory removeAllObjects];
	[normalInventory removeAllObjects];
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
    
	for (IJInventoryItem *item in inventory) {
		[item removeObserver:self forKeyPath:@"count"];
		[item removeObserver:self forKeyPath:@"damage"];
	}	
	
	[inventory release];
	inventory = nil;
	
	inventory = [newInventory retain];
	
	// Add placeholder inventory items:
	for (int i = 0; i < IJInventorySlotQuickLast + 1 - IJInventorySlotQuickFirst; i++)
		[quickInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotQuickFirst + i]];
	
	for (int i = 0; i < IJInventorySlotNormalLast + 1 - IJInventorySlotNormalFirst; i++)
		[normalInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotNormalFirst + i]];
	
	for (int i = 0; i < IJInventorySlotArmorLast + 1 - IJInventorySlotArmorFirst; i++)
		[armorInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotArmorFirst + i]];
	
	
	// Overwrite the placeholders with actual inventory:
	for (IJInventoryItem *item in inventory) {
		// Add a KVO so that we can set the document as edited when the count or damage values are changed.
		[item addObserver:self forKeyPath:@"count" options:0 context:@"KVO_COUNT_CHANGED"];
		[item addObserver:self forKeyPath:@"damage" options:0 context:@"KVO_DAMAGE_CHANGED"];
        
		if (IJInventorySlotQuickFirst <= item.slot && item.slot <= IJInventorySlotQuickLast) {
			[quickInventory replaceObjectAtIndex:item.slot - IJInventorySlotQuickFirst withObject:item];
		}
		else if (IJInventorySlotNormalFirst <= item.slot && item.slot <= IJInventorySlotNormalLast) {
			[normalInventory replaceObjectAtIndex:item.slot - IJInventorySlotNormalFirst withObject:item];
		}
		else if (IJInventorySlotArmorFirst <= item.slot && item.slot <= IJInventorySlotArmorLast) {
			[armorInventory replaceObjectAtIndex:item.slot - IJInventorySlotArmorFirst withObject:item];
		}
	}
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
    
	[self setDocumentEdited:YES];	
}

- (NSMutableArray *)inventoryArrayWithEmptySlot:(NSUInteger *)slot
{
	for (NSMutableArray *inventoryArray in [NSArray arrayWithObjects:quickInventory, normalInventory, nil]) {
		__block BOOL found = NO;
		
		[inventoryArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
			IJInventoryItem *item = obj;
			if (item.count == 0) {
				*slot = index;
				*stop = YES;
				found = YES;
			}
		}];
		
		if (found) {
			return inventoryArray;
		}
	}
	return nil;
}

- (NSArray *)currentInventory
{
	NSMutableArray *inventoryArray = [[[NSMutableArray alloc] init] autorelease];
	
	[inventoryArray addObjectsFromArray:armorInventory];
	[inventoryArray addObjectsFromArray:quickInventory];
	[inventoryArray addObjectsFromArray:normalInventory];
    
	return inventoryArray;
}

- (void)addInventoryItem:(short)item selectItem:(BOOL)flag
{
	NSUInteger slot;
	NSMutableArray *inventoryArray = [self inventoryArrayWithEmptySlot:&slot];
	if (!inventoryArray)
		return;
	
	IJInventoryItem *inventoryItem = [inventoryArray objectAtIndex:slot];
	inventoryItem.itemId = item;
	inventoryItem.count = 1;
	[self setDocumentEdited:YES];
	
	IJInventoryView *invView = [self inventoryViewForItemArray:inventoryArray];
	[invView reloadItemAtIndex:slot];
	if (flag) {
		[self inventoryView:invView selectedItemAtIndex:slot];
	}
}


#pragma mark -
#pragma mark Item Picker

- (IBAction)updateItemSearchFilter:(id)sender
{
	NSString *filterString = [sender stringValue];
	
	if (filterString.length == 0) {
		[filteredItemIds autorelease];
		filteredItemIds = [allItemIds retain];
		[itemTableView reloadData];
		return;
	}
	
	NSMutableArray *results = [NSMutableArray array];
	
	for (NSNumber *itemId in allItemIds) {
		NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemId];
		NSString *name = [itemData objectForKey:@"Name"];
		NSRange range = [name rangeOfString:filterString options:NSCaseInsensitiveSearch];
		
		if (range.location != NSNotFound) {
			[results addObject:itemId];
			continue;
		}
		
		// Also search the item id:
		range = [[itemId stringValue] rangeOfString:filterString];
		if (range.location != NSNotFound) {
			[results addObject:itemId];
			continue;
		}
	}
	
	[filteredItemIds autorelease];
	filteredItemIds = [results retain];
	[itemTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
	return filteredItemIds.count;
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSNumber *itemId = [filteredItemIds objectAtIndex:row];
	NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemId];
	NSNumber *itemDamage = [itemData objectForKey:@"Damage"];
	
	if ([tableColumn.identifier isEqual:@"itemId"]) {
		return itemId;
	}
	else if ([tableColumn.identifier isEqual:@"image"]) {
		return [IJInventoryItem imageForItemId:[itemId shortValue] withDamage:[itemDamage shortValue]];
	}
	else {
		NSString *name = [itemData objectForKey:@"Name"];
		return name;
	}
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:IJPasteboardTypeInventoryItem, nil] owner:nil];
	
	NSNumber *itemId = [filteredItemIds objectAtIndex:[rowIndexes firstIndex]];
	
	IJInventoryItem *item = [[IJInventoryItem alloc] init];
	item.itemId = [itemId shortValue];
	item.count = 1;
	item.damage = 0;
	item.slot = 0;
	
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:item]
			forType:IJPasteboardTypeInventoryItem];
	
	[item release];
    
	return YES;
}

- (IBAction)itemTableViewDoubleClicked:(id)sender
{
	short selectedItem = [[filteredItemIds objectAtIndex:[itemTableView selectedRow]] shortValue];
	[self addInventoryItem:selectedItem selectItem:YES];
}

#pragma mark -
#pragma mark NSWindowDelegate

- (void)dirtyCloseSheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSAlertOtherReturn) { // Cancel
		return;
	}
	
	if (returnCode == NSAlertDefaultReturn){ // Save
		[self saveWorld];
		[self.window performClose:nil];
	}
	else if (returnCode == NSAlertAlternateReturn) { // Don't save
		[self setDocumentEdited:NO]; // Slightly hacky -- prevent the alert from being put up again.
		[self unloadWorld];
		[self.window performClose:nil];
	}
}


- (BOOL)windowShouldClose:(id)sender
{
	if ([self isDocumentEdited]) {
		// Note: We use the didDismiss selector because the sheet needs to be closed in order for performClose: to work.
		NSBeginAlertSheet(@"Do you want to save the changes you made in this world?", @"Save", @"Don't Save", @"Cancel", self.window, self, nil, @selector(dirtyCloseSheetDidDismiss:returnCode:contextInfo:), nil, 
                          @"Your changes will be lost if you do not save them.");
		return NO;
	}
	
	if (level != nil && sender != nil) {
		[self unloadWorld];
		[contentView selectTabViewItemAtIndex:0];
		return NO;
	}
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:nil];
}


#pragma mark -
#pragma mark NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(moveDown:)) {
		if ([itemTableView numberOfRows] > 0) {
			[self.window makeFirstResponder:itemTableView];
			[itemTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		}
		return YES;
	}
	return NO;
}


#pragma mark -
#pragma mark Cleanup

- (void)dealloc
{
	[loadedWorldPath release];
	[attemptedLoadWorldPath release];
	[propertiesViewController release];
	[armorInventory release];
	[quickInventory release];
	[normalInventory release];
    [gameModeSegmentedControl release];
	[inventory release];
	[level release];
	[super dealloc];
}

@end
