//
//  LXMSliderMenuItem.h
//  LIFX Menu
//
//  Created by Jonathan on 29/01/2015.
//  Copyright (c) 2015 Kyle Howells. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LXMSliderMenuItem : NSMenuItem
-(instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)aSelector;
@property (nonatomic, readonly) NSSlider *slider;
@end
