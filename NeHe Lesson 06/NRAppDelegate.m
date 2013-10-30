//
//  NRAppDelegate.m
//  NeHe Lesson 06
//
//  Created by Ben Murray on 17/10/2013.
//  Copyright (c) 2013 NextRealm Ltd. All rights reserved.
//

#import "NRAppDelegate.h"

@interface NRAppDelegate (InternalMethods)
- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) createFailed;
@end

@implementation NRAppDelegate

- (id)init
{
    self = [super init];
    
    if(self){
        escPressed = FALSE;
        f1Pressed = FALSE;
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void) awakeFromNib
{
    [ NSApp setDelegate:self ];   // We want delegate notifications
    renderTimer = nil;
    [ _window makeFirstResponder:self ];
    glView = [ [ OpenGLView alloc ] initWithFrame:[ _window frame ]
                                          colorBits:16 depthBits:16 fullscreen:FALSE ];
    if( glView != nil )
    {
        [ _window setContentView:glView ];
        [ _window makeKeyAndOrderFront:self ];
        [ self setupRenderTimer ];
    }
    else
        [ self createFailed ];
}


/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
    NSTimeInterval timeInterval = 0.005;
    
    renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                      target:self
                                                    selector:@selector( updateGLView: )
                                                    userInfo:nil repeats:YES ] retain ];
    [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                    forMode:NSEventTrackingRunLoopMode ];
    [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                    forMode:NSModalPanelRunLoopMode ];
}


/*
 * Called by the rendering timer.
 */
- (void) updateGLView:(NSTimer *)timer
{
    if( glView != nil )
        [ glView drawRect:[ glView frame ] ];
}


/*
 * Handle key presses
 */
- (void) keyDown:(NSEvent *)theEvent
{
    NSLog(@"NRAppDelegate::keyDown\n");
    
    unichar unicodeKey;
    
    unicodeKey = [ [ theEvent characters ] characterAtIndex:0 ];
    
    switch( unicodeKey )
    {
        // Handle key presses here
        case 27:
            if(!escPressed){
                escPressed = TRUE;
                [NSApp terminate:self];
            }
            break;
        case 63236:
            if(!f1Pressed){
                f1Pressed = TRUE;
                if([glView isFullScreen]){
                    [glView setFullScreen:FALSE inFrame:NSMakeRect(0, 0, 640, 480)];
                }else{
                    [glView setFullScreen:TRUE inFrame:NSMakeRect(0, 0, 800, 600)];
                }
            }
            break;
        default:
            NSLog(@"NRAppDelegate::keyDown unicodeKey: %hu\n", unicodeKey);
            break;
    }
}

- (void) keyUp:(NSEvent *)theEvent
{
    NSLog(@"NRAppDelegate::keyUp\n");
    
    unichar unicodeKey;
    
    unicodeKey = [ [ theEvent characters ] characterAtIndex:0 ];
    
    switch( unicodeKey )
    {
            // Handle key presses here
        case 27:
            escPressed = FALSE;
            break;
        case 63236:
            f1Pressed = FALSE;
            break;
        default:
            NSLog(@"NRAppDelegate::keyDown unicodeKey: %hu\n", unicodeKey);
            break;
    }
}

/*
 * Set full screen.
 */
- (IBAction)setFullScreen:(id)sender
{
    [ _window setContentView:nil ];
    if( [ glView isFullScreen ] )
    {
        if( ![ glView setFullScreen:FALSE inFrame:[ _window frame ] ] )
            [ self createFailed ];
        else
            [ _window setContentView:glView ];
    }
    else
    {
        if( ![ glView setFullScreen:TRUE
                            inFrame:NSMakeRect( 0, 0, 800, 600 ) ] )
            [ self createFailed ];
    }
}


/*
 * Called if we fail to create a valid OpenGL view
 */
- (void) createFailed
{
    NSWindow *infoWindow;
    
    infoWindow = NSGetCriticalAlertPanel( @"Initialization failed",
                                         @"Failed to initialize OpenGL",
                                         @"OK", nil, nil );
    [ NSApp runModalForWindow:infoWindow ];
    [ infoWindow close ];
    [ NSApp terminate:self ];
}


/* 
 * Cleanup
 */
- (void) dealloc
{
    [ _window release ];
    [ glView release ];
    if( renderTimer != nil && [ renderTimer isValid ] )
        [ renderTimer invalidate ];
    [super dealloc];
}

@end
