//
//  LXMSliderMenuItem.m
//  LIFX Menu
//
//  Created by Jonathan on 29/01/2015.
//  Copyright (c) 2015 Kyle Howells. All rights reserved.
//

#import "LXMSliderMenuItem.h"
@interface LXMSliderMenuItem ()
@property (nonatomic, strong, readwrite) NSSlider *slider;
@end

@implementation LXMSliderMenuItem
-(instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)aSelector {
    if (self = [super initWithTitle:title action:aSelector keyEquivalent:@""]) {
        [self setTarget:target];
        
        NSView *customView = [[NSView alloc] initWithFrame:NSMakeRect(10, 0, 150, 25)];
        NSSlider *slider = [[NSSlider alloc] init];
        [customView addSubview:slider];
        [customView setAutoresizingMask:NSViewWidthSizable];
        [slider setTranslatesAutoresizingMaskIntoConstraints:NO];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[slider]-10-|" options:0 metrics:nil views:@{@"slider" : slider}]];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[slider]|" options:0 metrics:nil views:@{@"slider" : slider}]];
        [slider setTarget:self];
        [slider setAction:@selector(sliderChanged:)];
        [self setSlider:slider];
        [self setView:customView];
    }
    return self;
}

-(void)sliderChanged:(NSSlider *)sender {
    if ([self action] && [[self target] respondsToSelector:[self action]]) {
        [[self target] performSelector:[self action] withObject:self];
    }
}

@end
