//
//  OpenGLView.h
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
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface OpenGLView : NSOpenGLView {
    int colorBits, depthBits;
    BOOL runningFullScreen;
    NSDictionary *originalDisplayMode;
    GLenum texFormat[ 1 ];   // Format of texture (GL_RGB, GL_RGBA)
    NSSize texSize[ 1 ];     // Width and height
    char *texBytes[ 1 ];     // Texture data
    GLfloat xrot;       // X rotation
    GLfloat yrot;       // Y rotation
    GLfloat zrot;       // Z rotation
    GLuint texture[ 1 ];     // Storage for one texture
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
           depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (BOOL) isFullScreen;
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (size_t) displayBitsPerPixelForMode: (CGDisplayModeRef)mode;
- (CGDisplayModeRef) bestMatchForMode: (int)bits width: (CGFloat)width height: (CGFloat) height;
#endif
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame;
- (void) dealloc;

@end
