//
//  IJWorldCollectionController.m
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJWorldCollectionController.h"
#import "IJInventoryWindowController.h"


@implementation IJWorldCollectionController

-(void)awakeFromNib
{
	worldArray = [[NSMutableArray alloc] init];
	//Add a new observer to the array controller of the collection view
	[worldArrayController addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:nil];
	[worldArrayController setContent:worldArray];
	
	[self loadWorldData];
	
	if ([[worldArrayController arrangedObjects] count] == 0) {
		[InventoryWindowController.contentView selectTabViewItemAtIndex:2];
		[chooseButton setEnabled:NO];
	}
}

// Observe the worldArray controller selection and change enabled state of the choose button accordingly.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualTo:@"selectionIndexes"]) {
		if ([[worldArrayController selectedObjects] count] > 0) {
			[chooseButton setEnabled:YES];
		}
		else {
			[chooseButton setEnabled:NO];
		}
	}
}

- (void)openWorldAtPath:(NSString *)path
{
	[InventoryWindowController loadWorldAtPath:path];
}

- (IBAction)openSelectedWorld:(id)sender
{
	int index = [worldArrayController selectionIndex];
	NSString *path = [[worldArray objectAtIndex:index] valueForKey:@"Path"];
	[InventoryWindowController loadWorldAtPath:path];
}


- (void)reloadWorldData
{
	//[worldArray removeAllObjects];
	//[worldArrayController setContent:worldArray];
	//[self loadWorldData];
}

- (void)loadWorldData
{
	NSString *path = [@"~/library/application support/minecraft/saves/" stringByExpandingTildeInPath];
	NSArray *folderArray = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL] retain];
	
	
	// Worlds in 'application support/minecraft/saves/'
	int index;
	for (index = 0; index < [folderArray count]; index++) {
		NSString *fileName = [folderArray objectAtIndex:index];
		NSString *filePath = [path stringByAppendingPathComponent:fileName];
		
		[self addPathToCollection:filePath withImage:[NSImage imageNamed:@"World"]];		
	}
		
	[worldArrayController	setSelectionIndex:0];
	[folderArray release];
}

- (void)addPathToCollection:(NSString *)path withImage:(NSImage *)icon
{
	NSString *fileName = [path lastPathComponent];
	NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
		
	if ([fileName hasPrefix:@"."]) {
		return;
	}
	else if (![[fileAttr valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
		return;
	}
	else if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"level.dat"]]) {
		return;
	}
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"'Created:' MMM d yyyy 'at' h:m:s a"];
	NSString *fileMeta = [formatter stringFromDate:[fileAttr valueForKey:NSFileCreationDate]];
	
	
	int arrayIndex = [[worldArrayController arrangedObjects] count];
	[worldArrayController insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
																			fileName, @"Name",
																			fileMeta, @"Meta",
																			icon, @"Icon",
																			self, @"Delegate",
																			path, @"Path",
																			nil] 
							 atArrangedObjectIndex:arrayIndex];
}

- (void)dealloc
{
	//Remove the collection view array controller selectionIndexes observer
	[worldArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
	[worldArray release];
	[super dealloc];
}

@end
