//
//  InsideJobAppDelegate.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "InsideJobAppDelegate.h"
#import "IJInventoryWindowController.h"

@implementation InsideJobAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[inventoryWindowController.statusTextField setStringValue:@"No world loaded!"];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	BOOL shouldClose = [inventoryWindowController windowShouldClose:nil];
	if (shouldClose)
		return NSTerminateNow;
	else
		return NSTerminateCancel;
}

@end
