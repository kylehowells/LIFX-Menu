//
//  AppDelegate.m
//  LIFX Menu
//
//  Created by Kyle Howells on 08/10/2014.
//  Copyright (c) 2014 Kyle Howells. All rights reserved.
//

#import "AppDelegate.h"
#import <LIFXKit/LIFXKit.h>


@interface AppDelegate () <LFXLightCollectionObserver, LFXLightObserver>
@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *menu;

/**
 *  All the NSMenuItem objects for LFXLight's we have currently detected.
 */
@property (nonatomic, strong) NSMutableArray *lightItems;
@end



@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.lightItems = [NSMutableArray array];
	
	// Status bar item
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	self.statusItem.title = @"";
	NSImage *icon = [NSImage imageNamed:@"lifx-icon"];
	[icon setScalesWhenResized:YES];
	[icon setTemplate:YES];
	self.statusItem.image = icon;
	self.statusItem.highlightMode = YES;
	
	
	// Menu
	self.menu = [[NSMenu alloc] init];
	
	// Always there buttons
	[self.menu addItemWithTitle:@"Turn lights ON" action:@selector(allLightsOn) keyEquivalent:@""];
	[self.menu addItemWithTitle:@"Turn lights OFF" action:@selector(allLightsOff) keyEquivalent:@""];
	
	// Separator to the section with the individual lights
	[self.menu addItem:[NSMenuItem separatorItem]];
	self.statusItem.menu = self.menu;
	
	
	// Monitor for changes
	[[[LFXClient sharedClient] localNetworkContext].allLightsCollection addLightCollectionObserver:self];
}




#pragma mark - Lights control methods

/**
 *  I prefer having 2 buttons as you can have some on and some off, meaning the state of all the lights as a whole is non-binary.
 */
-(void)allLightsOn{
	LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
	[localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOn];
}
-(void)allLightsOff{
	LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
	[localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOff];
}


-(void)toggleLight:(NSMenuItem*)item{
	LFXLight *light = [item representedObject];
	[light setPowerState:((light.powerState == LFXPowerStateOn) ? LFXPowerStateOff : LFXPowerStateOn)];
}







/**
 *  Creates an NSMenuItem for the light. Attaches the light to the item be putting it as the menuItem's -representedObject. Then adds it to the menu and the array of lights
 */
-(void)addLight:(LFXLight*)light{
	if ([self menuItemForLight:light] != nil) {
		[self updateLight:light];
		return;
	}
	
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[self titleForLight:light] action:@selector(toggleLight:) keyEquivalent:@""];
	[item setRepresentedObject:light];
	[self updateLightMenuItem:item];
	
	[self.menu addItem:item];
	[self.lightItems addObject:item];
	
	[light addLightObserver:self];
}
/**
 *  Removes the light from the menu and array. Also removes self as an observer for that light.
 */
-(void)removeLight:(LFXLight *)light{
	NSMenuItem *item = [self menuItemForLight:light];
	
	if (item) {
		[self.menu removeItem:item];
		[self.lightItems removeObject:item];
	}
	
	[light removeLightObserver:self];
}






/**
 *  Gets the NSMenuItem object for that light and then updates it.
 */
-(void)updateLight:(LFXLight*)light{
	NSMenuItem *item = [self menuItemForLight:light];
	[self updateLightMenuItem:item];
}
/**
 *  Updates the title and the current state of the lights NSMenuItem.
 */
-(void)updateLightMenuItem:(NSMenuItem*)item{
	LFXLight *light = [item representedObject];
	
	[item setTitle:(light.label ?: light.deviceID)];
	[item setState:((light.powerState == LFXPowerStateOn) ? NSOnState : NSOffState)];
}







#pragma mark - Helper methods

-(NSMenuItem*)menuItemForLight:(LFXLight*)light{
	NSMenuItem *item = nil;
	
	for (NSMenuItem *menuItem in self.lightItems) {
		LFXLight *itemLight = [menuItem representedObject];
		if ([light.deviceID isEqualToString:itemLight.deviceID]) {
			item = menuItem;
			break;
		}
	}
	
	return item;
}
-(NSString*)titleForLight:(LFXLight*)light{
	return (light.label ?: light.deviceID);
}








#pragma mark - LFXLightCollectionObserver

-(void)lightCollection:(LFXLightCollection *)lightCollection didAddLight:(LFXLight *)light{
	[self addLight:light];
}
-(void)lightCollection:(LFXLightCollection *)lightCollection didRemoveLight:(LFXLight *)light{
	[self removeLight:light];
}


#pragma mark - LFXLightObserver

-(void)light:(LFXLight *)light didChangeLabel:(NSString *)label{
	[self updateLight:light];
}
-(void)light:(LFXLight *)light didChangePowerState:(LFXPowerState)powerState{
	[self updateLight:light];
}





-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
