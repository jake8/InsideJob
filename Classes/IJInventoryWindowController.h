//
//  IJInventoryWindowController.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IJInventoryView.h"

@class IJInventoryView;
@class IJMinecraftLevel;
@class MAAttachedWindow;
@class IJItemPropertiesViewController;

@interface IJInventoryWindowController : NSWindowController <NSWindowDelegate, IJInventoryViewDelegate> {
			
	
	IJMinecraftLevel *level;
	NSArray *inventory;
	
	NSTextField *statusTextField;
	IBOutlet NSTabView *contentView;

	
	IBOutlet IJInventoryView *inventoryView;
	IBOutlet IJInventoryView *quickView;
	IBOutlet IJInventoryView *armorView;
	
	
	NSMutableArray *armorInventory;
	NSMutableArray *quickInventory;
	NSMutableArray *normalInventory;
	
	// Search/Item List
	IBOutlet NSSearchField *itemSearchField;
	IBOutlet NSTableView *itemTableView;
	NSArray *allItemIds;
	NSArray *filteredItemIds;
	
	// 
	IJItemPropertiesViewController *propertiesViewController;
	MAAttachedWindow *propertiesWindow;
	id observerObject;
	
	// Document
	int64_t sessionLockValue;
	NSString *loadedWorldPath;
	NSString *attemptedLoadWorldPath;
}

@property (nonatomic, assign) IBOutlet NSTextField *statusTextField;
@property (nonatomic, assign) IBOutlet NSTabView *contentView;
@property (nonatomic, retain) NSNumber *worldTime;

- (IBAction)openWorld:(id)sender;
- (IBAction)reloadWorldInformation:(id)sender;
- (IBAction)updateItemSearchFilter:(id)sender;
- (IBAction)makeSearchFieldFirstResponder:(id)sender;
- (IBAction)itemTableViewDoubleClicked:(id)sender;

- (void)saveWorld;
- (BOOL)loadWorldAtPath:(NSString *)path;
- (BOOL)isDocumentEdited;


@end
