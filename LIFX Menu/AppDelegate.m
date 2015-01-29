//
//  AppDelegate.m
//  LIFX Menu
//
//  Created by Kyle Howells on 08/10/2014.
//  Copyright (c) 2014 Kyle Howells. All rights reserved.
//

#import "LIFXKit.framework/Headers/LIFXKit.h"
#import "AppDelegate.h"
#import "LaunchAtLoginController.h"
#import "LXMSliderMenuItem.h"

@interface AppDelegate () <LFXLightCollectionObserver, LFXLightObserver>
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *menu;

/**
 *  All the NSMenuItem objects for LFXLight's we have currently detected.
 */
@property (nonatomic, strong) NSMutableArray *lightItems;
@end



@implementation AppDelegate{
	LaunchAtLoginController *loginController;
	NSMenuItem *autorunItem;
}

#pragma mark - Application Delegate methods

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// User defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"AutoLaunch" : @YES }];
	
	
	// Variable setup
	self.lightItems = [NSMutableArray array];
	loginController = [[LaunchAtLoginController alloc] init];
	
	
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
	[self.menu addItemWithTitle:@"Turn all lights on" action:@selector(allLightsOn) keyEquivalent:@""];
	[self.menu addItemWithTitle:@"Turn all lights off" action:@selector(allLightsOff) keyEquivalent:@""];
	
	// Separator to the section with the individual lights
	[self.menu addItem:[NSMenuItem separatorItem]];
	
	
	[self.menu addItem:[NSMenuItem separatorItem]];
	autorunItem = [[NSMenuItem alloc] initWithTitle:@"Launch at login" action:@selector(autoLaunchPressed) keyEquivalent:@""];
	[self.menu addItem:autorunItem];
	[self updateAutoLaunch];
	
	self.statusItem.menu = self.menu;
	
	
	// Monitor for changes
	[[[LFXClient sharedClient] localNetworkContext].allLightsCollection addLightCollectionObserver:self];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
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

-(void)changeBrightness:(LXMSliderMenuItem *)item{
	LFXLight *light = [item representedObject];
    [light setColor:[[light color] colorWithBrightness:[[item slider] floatValue]]];
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
    
    LXMSliderMenuItem *sliderItem = [[LXMSliderMenuItem alloc] initWithTitle:@"Brightness" target:self action:@selector(changeBrightness:)];
    [sliderItem setRepresentedObject:light];
    
    [item setSubmenu:[[NSMenu alloc] init]];
    [[item submenu] addItem:sliderItem];
    
	[self updateLightMenuItem:item];
	
	[self.menu insertItem:item atIndex:(self.menu.numberOfItems - 2)];
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
	
	[item setTitle:[self titleForLight:light]];
	[item setState:((light.powerState == LFXPowerStateOn) ? NSOnState : NSOffState)];
    
    LXMSliderMenuItem *sliderMenuItem = (LXMSliderMenuItem *)[[item submenu] itemWithTitle:@"Brightness"];
    [[sliderMenuItem slider] setMinValue:LFXHSBKColorMinBrightness];
    [[sliderMenuItem slider] setMaxValue:LFXHSBKColorMaxBrightness];
    [[sliderMenuItem slider] setFloatValue:light.color.brightness];
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
-(void)light:(LFXLight *)light didChangeColor:(LFXHSBKColor *)color {
    [self updateLight:light];
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
	return ([light.label length] > 0 ? light.label : light.deviceID);
}





#pragma mark - Auto launch methods

-(BOOL)autoLaunch{
	id object = [[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLaunch"];
	return (object ? [object boolValue] : YES);
}
-(void)setAutoLaunch:(BOOL)autoLaunch{
	[[NSUserDefaults standardUserDefaults] setBool:autoLaunch forKey:@"AutoLaunch"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self updateAutoLaunch];
}

-(void)updateAutoLaunch{
	if ([self autoLaunch]) {
		if (![loginController launchAtLogin]) {
			[loginController setLaunchAtLogin:YES];
		}
		
		[autorunItem setState:NSOnState];
	}
	else {
		if ([loginController launchAtLogin]) {
			[loginController setLaunchAtLogin:NO];
		}
		
		[autorunItem setState:NSOffState];
	}
}

-(void)autoLaunchPressed{
	if (autorunItem.state == NSOnState) {
		[self setAutoLaunch:NO];
	}
	else {
		[self setAutoLaunch:YES];
	}
}


@end
