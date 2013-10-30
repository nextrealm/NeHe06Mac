//
//  OpenGLView.m
//  NeHe Lesson 06
//
//  Created by Ben Murray on 17/10/2013.
//  Copyright (c) 2013 NextRealm Ltd. All rights reserved.
//

#import "OpenGLView.h"

@interface OpenGLView (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (void) switchToOriginalDisplayMode;
- (BOOL) initGL;
- (BOOL) loadGLTextures;
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex;
- (BOOL) loadBitmapFromViewIntoIndex:(int)texIndex;
@end

@implementation OpenGLView

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
           depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
    NSOpenGLPixelFormat *pixelFormat;
    
    colorBits = numColorBits;
    depthBits = numDepthBits;
    runningFullScreen = runFullScreen;
    originalDisplayMode = (NSDictionary *)CGDisplayCurrentMode(kCGDirectMainDisplay);
    xrot = yrot = zrot = 0;
    pixelFormat = [ self createPixelFormat:frame ];
    if( pixelFormat != nil )
    {
        NSLog(@"OpenGLView::initWithFrame pixelFormat not nil\n");
        self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
        [ pixelFormat release ];
        if( self )
        {
            NSLog(@"OpenGLView::initWithFrame self not nil\n");
            [ [ self openGLContext ] makeCurrentContext ];
            if( runningFullScreen )
                [ [ self openGLContext ] setFullScreen ];
            [ self reshape ];
            if( ![ self initGL ] )
            {
                NSLog(@"OpenGLView::initWithFrame initGL failed\n");
                [ self clearGLContext ];
                self = nil;
            }
        }
    }
    else
        self = nil;
    
    return self;
}

#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (size_t) displayBitsPerPixelForMode: (CGDisplayModeRef)mode {
	
	size_t depth = 0;
	
	CFStringRef pixEnc = CGDisplayModeCopyPixelEncoding(mode);
	if(CFStringCompare(pixEnc, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		depth = 32;
	else if(CFStringCompare(pixEnc, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		depth = 16;
	else if(CFStringCompare(pixEnc, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		depth = 8;
	
	return depth;
}

- (CGDisplayModeRef) bestMatchForMode: (int)bitsPerPixel width: (CGFloat)width height: (CGFloat) height {
	
	bool exactMatch = false;
	
    // Get a copy of the current display mode
	CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
	
    // Loop through all display modes to determine the closest match.
    // CGDisplayBestModeForParameters is deprecated on 10.6 so we will emulate it's behavior
    // Try to find a mode with the requested depth and equal or greater dimensions first.
    // If no match is found, try to find a mode with greater depth and same or greater dimensions.
    // If still no match is found, just use the current mode.
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(kCGDirectMainDisplay, NULL);
    for(int i = 0; i < CFArrayGetCount(allModes); i++)	{
		CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
        
		if([self displayBitsPerPixelForMode: mode] != bitsPerPixel)
			continue;
		
		if((CGDisplayModeGetWidth(mode) >= width) && (CGDisplayModeGetHeight(mode) >= height))
		{
			displayMode = mode;
			exactMatch = true;
			break;
		}
	}
	
    // No depth match was found
    if(!exactMatch)
	{
		for(int i = 0; i < CFArrayGetCount(allModes); i++)
		{
			CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
			if([self displayBitsPerPixelForMode: mode] >= bitsPerPixel)
				continue;
			
			if((CGDisplayModeGetWidth(mode) >= width) && (CGDisplayModeGetHeight(mode) >= height))
			{
				displayMode = mode;
				break;
			}
		}
	}
	return displayMode;
}
#endif

/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
    NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
    int pixNum = 0;
    NSDictionary *fullScreenMode;
    NSOpenGLPixelFormat *pixelFormat;
    
    pixelAttribs[pixNum++] = NSOpenGLPFADoubleBuffer;
    pixelAttribs[pixNum++] = NSOpenGLPFAAccelerated;
    pixelAttribs[pixNum++] = NSOpenGLPFAColorSize;
    pixelAttribs[pixNum++] = colorBits;
    pixelAttribs[pixNum++] = NSOpenGLPFADepthSize;
    pixelAttribs[pixNum++] = depthBits;
    
    if( runningFullScreen )  // Do this before getting the pixel format
    {
        pixelAttribs[pixNum++] = NSOpenGLPFAFullScreen;
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
        fullScreenMode = (NSDictionary *)[self bestMatchForMode:colorBits width:frame.size.width height:frame.size.height];
#else
        fullScreenMode = (NSDictionary *)CGDisplayBestModeForParameters(kCGDirectMainDisplay,
                                                                         colorBits, frame.size.width,
                                                                         frame.size.height, NULL);
#endif
        CGDisplayCapture(kCGDirectMainDisplay);
        CGDisplayHideCursor(kCGDirectMainDisplay);
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
        CGDisplaySetDisplayMode(kCGDirectMainDisplay, (CGDisplayModeRef)fullScreenMode, NULL);
#else
        CGDisplaySwitchToMode(kCGDirectMainDisplay, (CFDictionaryRef)fullScreenMode);
#endif
    }
    pixelAttribs[pixNum] = 0;
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelAttribs];
    
    return pixelFormat;
}


/*
 * Enable/disable full screen mode
 */
- (BOOL) setFullScreen:(BOOL)enableFS inFrame:(NSRect)frame
{
    BOOL success = FALSE;
    NSOpenGLPixelFormat *pixelFormat;
    NSOpenGLContext *newContext;
    
    [ [ self openGLContext ] clearDrawable ];
    if( runningFullScreen )
        [ self switchToOriginalDisplayMode ];
    runningFullScreen = enableFS;
    pixelFormat = [ self createPixelFormat:frame ];
    if( pixelFormat != nil )
    {
        newContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
        if(newContext != nil)
        {
            [super setFrame:frame];
            [super setOpenGLContext:newContext];
            [newContext makeCurrentContext];
            if(runningFullScreen)
                [newContext setFullScreen];
            [self reshape];
            if([self initGL])
                success = TRUE;
        }
        [pixelFormat release];
    }
    if(!success && runningFullScreen)
        [self switchToOriginalDisplayMode];
    
    return success;
}


/*
 * Switch to the display mode in which we originally began
 */
- (void) switchToOriginalDisplayMode
{
    CGDisplaySwitchToMode( kCGDirectMainDisplay,
                          (CFDictionaryRef) originalDisplayMode );
    CGDisplayShowCursor( kCGDirectMainDisplay );
    CGDisplayRelease( kCGDirectMainDisplay );
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{
    if( ![ self loadGLTextures ] ){
        NSLog(@"OpenGLView::initGL loadGLTextures failed\n");
        return FALSE;
    }
    
    glEnable( GL_TEXTURE_2D );                // Enable texture mapping
    glShadeModel( GL_SMOOTH );                // Enable smooth shading
    glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
    glClearDepth( 1.0f );                     // Depth buffer setup
    glEnable( GL_DEPTH_TEST );                // Enable depth testing
    glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
    // Really nice perspective calculations
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
    
    return TRUE;
}


/*
 * Setup a texture from our model
 */
- (BOOL) loadGLTextures
{
    BOOL status = FALSE;
    
    NSLog(@"OpenGLView::loadGLTextures resourcePath: %@\n", [[NSBundle mainBundle] resourcePath]);
    
    if( [ self loadBitmap:[ NSString stringWithFormat:@"%@/%s",
                           [ [ NSBundle mainBundle ] resourcePath ],
                           "NeHe.bmp" ] intoIndex:0 ] )
    {
        NSLog(@"OpenGLView::loadGLTextures loadBitmap succeeded\n");
        status = TRUE;
        
        //glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
        //glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        glGenTextures( 1, &texture[ 0 ] );   // Create the texture
        
        // Typical texture generation using data from the bitmap
        glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
        
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, texSize[0].width,
                     texSize[0].height, 0, GL_BGRA,
                     GL_UNSIGNED_BYTE, texBytes[ 0 ] );
        // Linear filtering
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
        
        free( texBytes[ 0 ] );
    }
    
    return status;
}


/*
 * The NSBitmapImageRep is going to load the bitmap, but it will be
 * setup for the opposite coordinate system than what OpenGL uses, so
 * we copy things around.
 */
- (BOOL) loadBitmap:(NSString *)filename intoIndex:(int)texIndex
{
    NSLog(@"OpenGLView::loadBitmap filename: %@\n", filename);
    
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:filename];
    //CFURLRef url = CFBundleCopyResourceURL(CFBundleGetMainBundle(), filename, CFSTR("png"), CFSTR("Textures"));
    CGImageSourceRef myImageSourceRef = CGImageSourceCreateWithURL(url, NULL);
    CGImageRef myImageRef = CGImageSourceCreateImageAtIndex (myImageSourceRef, 0, NULL);
    CFRelease(myImageSourceRef);
    texSize[texIndex].width = CGImageGetWidth(myImageRef);
    texSize[texIndex].height = CGImageGetHeight(myImageRef);
    CGRect rect = {{0, 0}, {texSize[texIndex].width, texSize[texIndex].height}};
    texBytes[texIndex] = malloc(texSize[texIndex].width * texSize[texIndex].height * 4);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef myBitmapContext = CGBitmapContextCreate (texBytes[texIndex],
                                                          texSize[texIndex].width, texSize[texIndex].height, 8,
                                                          texSize[texIndex].width*4, space,
                                                          //kCGImageAlphaPremultipliedFirst);
                                                          kCGBitmapByteOrder32Host |
                                                          kCGImageAlphaPremultipliedFirst);
    //NSLog(@"OpenGLView::loadBitmap myData: %@\n", myData);
    CGContextSetBlendMode(myBitmapContext, kCGBlendModeCopy);
    CGContextTranslateCTM(myBitmapContext, 0, texSize[texIndex].height);
    CGContextScaleCTM(myBitmapContext, 1.0, -1.0);
    CGContextDrawImage(myBitmapContext, rect, myImageRef);
    CGContextRelease(myBitmapContext);
    
    return TRUE;
}

- (BOOL) loadBitmapFromViewIntoIndex:(GLuint)texIndex
{
    BOOL success = FALSE;
    
    NSBitmapImageRep * bitmap =  [self bitmapImageRepForCachingDisplayInRect:
                                  [self visibleRect]]; // 1
    NSInteger samplesPerPixel = 0;
    
    [self cacheDisplayInRect:[self visibleRect] toBitmapImageRep:bitmap]; // 2
    samplesPerPixel = [bitmap samplesPerPixel]; // 3
    glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/samplesPerPixel); // 4
    glPixelStorei (GL_UNPACK_ALIGNMENT, 1); // 5
    //if (*texIndex == 0) // 6
    glGenTextures (1, &texIndex);
    glBindTexture (GL_TEXTURE_RECTANGLE_ARB, texIndex); // 7
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB,
                    GL_TEXTURE_MIN_FILTER, GL_LINEAR); // 8
    
    if(![bitmap isPlanar] &&
       (samplesPerPixel == 3 || samplesPerPixel == 4)) { // 9
        success = TRUE;
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,
                     0,
                     samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                     [bitmap pixelsWide],
                     [bitmap pixelsHigh],
                     0,
                     samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                     GL_UNSIGNED_BYTE,
                     [bitmap bitmapData]);
    }
    
    return success;
}


/*
 * Resize ourself
 */
- (void) reshape
{
    NSRect sceneBounds;
    
    [ [ self openGLContext ] update ];
    sceneBounds = [ self bounds ];
    // Reset current viewport
    glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
    glMatrixMode( GL_PROJECTION );   // Select the projection matrix
    glLoadIdentity();                // and reset it
    // Calculate the aspect ratio of the view
    gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, 100.0f );
    glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
    glLoadIdentity();                // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
    // Clear the screen and depth buffer
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glLoadIdentity();   // Reset the current modelview matrix
    
    glTranslatef( 0.0f, 0.0, -5.0f );      // Move into screen 5 units
    // Rotate on X axis
    glRotatef( xrot, 1.0f, 0.0f, 0.0f );
    // Rotate on Y axis
    glRotatef( yrot, 0.0f, 1.0f, 0.0f );
    // Rotate on Z axis
    glRotatef( zrot, 0.0f, 0.0f, 1.0f );
    
    glBindTexture( GL_TEXTURE_2D, texture[0] );   // Select our texture
    
    glBegin( GL_QUADS );
    // Front face
    glTexCoord2f( 0.0f, 0.0f );
    glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom left
    glTexCoord2f( 1.0f, 0.0f );
    glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom right
    glTexCoord2f( 1.0f, 1.0f );
    glVertex3f(  1.0f,  1.0f,  1.0f );   // Top right
    glTexCoord2f( 0.0f, 1.0f );
    glVertex3f( -1.0f,  1.0f,  1.0f );   // Top left
    
    // Back face
    glTexCoord2f( 1.0f, 0.0f );
    glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom right
    glTexCoord2f( 1.0f, 1.0f );
    glVertex3f( -1.0f,  1.0f, -1.0f );   // Top right
    glTexCoord2f( 0.0f, 1.0f );
    glVertex3f(  1.0f,  1.0f, -1.0f );   // Top left
    glTexCoord2f( 0.0f, 0.0f );
    glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom left
    
    // Top face
    glTexCoord2f( 0.0f, 1.0f );
    glVertex3f( -1.0f,  1.0f, -1.0f );   // Top left
    glTexCoord2f( 0.0f, 0.0f );
    glVertex3f( -1.0f,  1.0f,  1.0f );   // Bottom left
    glTexCoord2f( 1.0f, 0.0f );
    glVertex3f(  1.0f,  1.0f,  1.0f );   // Bottom right
    glTexCoord2f( 1.0f, 1.0f );
    glVertex3f(  1.0f,  1.0f, -1.0f );   // Top right
    
    // Bottom face
    glTexCoord2f( 1.0f, 1.0f );
    glVertex3f( -1.0f, -1.0f, -1.0f );   // Top right
    glTexCoord2f( 0.0f, 1.0f );
    glVertex3f(  1.0f, -1.0f, -1.0f );   // Top left
    glTexCoord2f( 0.0f, 0.0f );
    glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom left
    glTexCoord2f( 1.0f, 0.0f );
    glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom right
    
    // Right face
    glTexCoord2f( 1.0f, 0.0f );
    glVertex3f(  1.0f, -1.0f, -1.0f );   // Bottom right
    glTexCoord2f( 1.0f, 1.0f );
    glVertex3f(  1.0f,  1.0f, -1.0f );   // Top right
    glTexCoord2f( 0.0f, 1.0f );
    glVertex3f(  1.0f,  1.0f,  1.0f );   // Top left
    glTexCoord2f( 0.0f, 0.0f );
    glVertex3f(  1.0f, -1.0f,  1.0f );   // Bottom left
    
    // Left face
    glTexCoord2f( 0.0f, 0.0f );
    glVertex3f( -1.0f, -1.0f, -1.0f );   // Bottom left
    glTexCoord2f( 1.0f, 0.0f );
    glVertex3f( -1.0f, -1.0f,  1.0f );   // Bottom right
    glTexCoord2f( 1.0f, 1.0f );
    glVertex3f( -1.0f,  1.0f,  1.0f );   // Top right
    glTexCoord2f( 0.0f, 1.0f );
    glVertex3f( -1.0f,  1.0f, -1.0f );   // Top left
    glEnd();
    
    [ [ self openGLContext ] flushBuffer ];
    
    xrot += 0.3f;
    yrot += 0.2f;
    zrot += 0.4f;
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
    return runningFullScreen;
}


/*
 * Cleanup
 */
- (void) dealloc
{
    if( runningFullScreen )
        [ self switchToOriginalDisplayMode ];
    [ originalDisplayMode release ];
}

@end
