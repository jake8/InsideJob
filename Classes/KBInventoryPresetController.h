//
//  KBInventoryPresetController.h
//  InsideJob
//
//  Created by Ben K on 2011/03/15.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryWindowController;
@class BWSheetController;

@interface KBInventoryPresetController : NSObject {
	
	IBOutlet IJInventoryWindowController *inventoryController;
	IBOutlet BWSheetController *newPresetSheetController;
	
	IBOutlet NSMenu *presetMenu;
	NSMutableArray *presetArray;
	
	NSMutableArray *armorInventory;
	NSMutableArray *quickInventory;
	NSMutableArray *normalInventory;	
	
	IBOutlet NSTextField *newPresetName;
	IBOutlet NSTextField *newPresetErrorLabel;
}

@property (copy) NSArray *presetArray;

- (IBAction)savePreset:(id)sender;
- (IBAction)loadPreset:(id)sender;
- (IBAction)deletePreset:(id)sender;

- (void)reloadPresetList;

@end
