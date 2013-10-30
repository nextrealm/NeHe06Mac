//
//  NRAppDelegate.h
//  NeHe Lesson 06
//
//  Created by Ben Murray on 17/10/2013.
//  Copyright (c) 2013 NextRealm Ltd. All rights reserved.
//
/*
* Original Windows comment:
* "This code was created by Jeff Molofee 2000
* A HUGE thanks to Fredric Echols for cleaning up
* and optimizing the base code, making it more flexible!
* If you've found this code useful, please let me know.
* Visit my site at nehe.gamedev.net"
*/

#import <Cocoa/Cocoa.h>
#import "OpenGLView.h"

@interface NRAppDelegate : NSResponder <NSApplicationDelegate>{
    NSTimer *renderTimer;
    OpenGLView *glView;
    BOOL escPressed;
    BOOL f1Pressed;
}

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (IBAction) setFullScreen:(id)sender;
- (void) dealloc;

@property (assign) IBOutlet NSWindow *window;

@end
