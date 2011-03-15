//
//  KBWorldCollectionItem.h
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KBWorldCollectionItem : NSCollectionViewItem {
	
	IBOutlet NSTextField *worldName;
	IBOutlet NSTextField *worldMeta;
	IBOutlet NSImageView *worldIcon;
	
	id delegate;
	NSString *worldPath;
	
	IBOutlet NSBox *selectionBox;

}

- (id)copyWithZone:(NSZone *)zone;
- (void)setRepresentedObject:(id)object;

@end
