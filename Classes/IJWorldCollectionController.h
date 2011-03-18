//
//  IJWorldCollectionController.h
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryWindowController;

@interface IJWorldCollectionController : NSObject {
	IBOutlet NSArrayController *worldArrayController;
	IBOutlet NSButton *chooseButton;
	IBOutlet IJInventoryWindowController *InventoryWindowController;
	
	NSMutableArray *worldArray;
}

- (void)openWorldAtPath:(NSString *)path;
- (IBAction)openSelectedWorld:(id)sender;

- (void)loadWorldData;


@end
