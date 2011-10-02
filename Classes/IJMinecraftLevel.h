//
//  IJMinecraftLevel.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NBTContainer.h"

@interface IJMinecraftLevel : NBTContainer {
    
}

@property (nonatomic, copy) NSArray *inventory; // Array of IJInventoryItem objects.
@property (nonatomic, readonly) NBTContainer *worldNameContainer;
@property (nonatomic, readonly) NBTContainer *worldSeedContainer;
@property (nonatomic, readonly) NBTContainer *worldTimeContainer;
@property (nonatomic, readonly) NBTContainer *worldGameModeContainer;

+ (NSString *)levelDataPathForWorld:(NSString *)worldPath;

+ (BOOL)worldExistsAtPath:(NSString *)worldPath;

+ (int64_t)writeToSessionLockAtPath:(NSString *)worldPath;
+ (BOOL)checkSessionLockAtPath:(NSString *)worldPath value:(int64_t)checkValue;


@end
