//
//  NTESGLView.m
//  NIM
//
//  Created by fenric on 15/9/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESGLView.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#define NTES_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define NTES_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define NTES_STRINGIZE(x) #x
#define NTES_STRINGIZE2(x) NTES_STRINGIZE(x)
#define NTES_SHADER_STRING(text) @ NTES_STRINGIZE2(text)

inline static BOOL isIOS7OrLater()
{
    return NTES_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
}

static NSString *const g_vertexShaderString = NTES_SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
 );

static BOOL validateProgram(GLuint prog)
{
    GLint status;
    
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        DDLogDebug(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        DDLogDebug(@"Failed to validate program %d", prog);
        return NO;
    }
    
    return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
    GLint status;
    const GLchar *sources = (GLchar *)shaderString.UTF8String;
    
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
        DDLogDebug(@"Failed to create shader %d", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
    
#ifdef DEBUG
    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        DDLogDebug(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
        DDLogDebug(@"Failed to compile shader:\n");
        return 0;
    }
    
    return shader;
}

static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (top - bottom);
    float tz = - (far + near) / (far - near);
    
    mout[0] = 2.0f / r_l;
    mout[1] = 0.0f;
    mout[2] = 0.0f;
    mout[3] = 0.0f;
    
    mout[4] = 0.0f;
    mout[5] = 2.0f / t_b;
    mout[6] = 0.0f;
    mout[7] = 0.0f;
    
    mout[8] = 0.0f;
    mout[9] = 0.0f;
    mout[10] = -2.0f / f_n;
    mout[11] = 0.0f;
    
    mout[12] = tx;
    mout[13] = ty;
    mout[14] = tz;
    mout[15] = 1.0f;
}

static NSString *const g_yuvFragmentShaderString = NTES_SHADER_STRING
(
 varying highp vec2 v_texcoord;
 precision mediump float;
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerU;
 uniform sampler2D SamplerV;
 uniform mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     // Subtract constants to map the video range start at 0
     yuv.x = (texture2D(SamplerY, v_texcoord).r - (16.0/255.0));
     yuv.y = (texture2D(SamplerU, v_texcoord).r - 0.5);
     yuv.z = (texture2D(SamplerV, v_texcoord).r - 0.5);
     rgb = colorConversionMatrix * yuv;
     gl_FragColor = vec4(rgb,1);
 }
 );

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164,  1.164,
    0.0,   -0.213,  2.112,
    1.793, -0.533,  0.0,
};

@interface NTESVideoRenderThread : NSObject

+ (NSThread *)thread;

@end


@implementation NTESVideoRenderThread

+ (NSThread *)thread
{
    static NSThread *theThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        theThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntryPoint:) object:nil];
        if ([theThread respondsToSelector:@selector(setQualityOfService:)]) {
            [theThread setQualityOfService:NSQualityOfServiceUserInteractive];
        }
        else {
            [theThread setThreadPriority:0.9];
        }
        [theThread start];
    });
    
    return theThread;
}

+ (void)threadEntryPoint:(id)__unused object
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.netease.video.render.thread"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

@end


@interface NTESGLVoutOverlay : NSObject
{
    UInt16 _pitches[3];
    UInt8 *_pixels[3];
}
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) int w;
@property (nonatomic, assign) int h;
@property (nonatomic, readonly) int isPrivate;
@property (nonatomic, readonly) int sarNum;
@property (nonatomic, readonly) int sarDen;

-(UInt16)pitch:(int)plane;
-(UInt8 *)pixel:(int)plane;

@end

@implementation NTESGLVoutOverlay

- (instancetype)initWithData:(NSData *)data w:(NSUInteger)w h:(NSUInteger)h
{
    if (self = [super init]) {
        _data = data;
        _w = (int)w;
        _h = (int)h;
        _isPrivate = 0;
        _sarNum = 0;
        _sarDen = 0;
        _pitches[0] = _w;
        _pitches[1] = _w / 2;
        _pitches[2] = _w / 2;
        
        UInt8 *bytes = (UInt8 *)[_data bytes];
        _pixels[0] = bytes;
        _pixels[1] = bytes + _w * _h;
        _pixels[2] = bytes + _w * _h * 5 / 4;
    }
    return self;
}

-(UInt16)pitch:(int)plane
{
    return _pitches[plane];
}
-(UInt8 *)pixel:(int)plane
{
    return _pixels[plane];
}

@end

@protocol NTESGLRender
- (BOOL) isValid;
- (NSString *) fragmentShader;
- (void) resolveUniforms: (GLuint) program;
- (void) render: (NTESGLVoutOverlay *) overlay;
- (BOOL) prepareDisplay;
@end

@interface NTESGLRenderI420 : NSObject<NTESGLRender>

@end


@implementation NTESGLRenderI420 {
    GLint _uniform[1];
    GLint _uniformSamplers[3];
    GLuint _textures[3];
    
    const GLfloat *_preferredConversion;
}

- (BOOL) isValid
{
    return (_textures[0] != 0);
}

- (NSString *) fragmentShader
{
    return g_yuvFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "SamplerY");
    _uniformSamplers[1] = glGetUniformLocation(program, "SamplerU");
    _uniformSamplers[2] = glGetUniformLocation(program, "SamplerV");
    _uniform[0] = glGetUniformLocation(program, "colorConversionMatrix");
}

- (void) render: (NTESGLVoutOverlay *) overlay
{
    const NSUInteger frameHeight = overlay.h;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _textures[0])
        glGenTextures(3, _textures);
    
    _preferredConversion = kColorConversion709;
    
    const UInt8 *pixels[3] = { [overlay pixel:0], [overlay pixel:1], [overlay pixel:2]};
    const NSUInteger widths[3]  = { [overlay pitch:0], [overlay pitch:1], [overlay pitch:2] };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     (int)widths[i],
                     (int)heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (BOOL) prepareDisplay
{
    if (_textures[0] == 0)
        return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }
    
    glUniformMatrix3fv(_uniform[0], 1, GL_FALSE, _preferredConversion);
    return YES;
}

- (void) dealloc
{
    if (_textures[0])
        glDeleteTextures(3, _textures);
}

@end

@interface NTESGLView()
@property(atomic,strong) NSRecursiveLock *glActiveLock;
@property(atomic) BOOL glActivePaused;
@property(nonatomic,strong) NSLock  *appActivityLock;
@property(nonatomic)        CGFloat  scaleFactor;

@end

@implementation NTESGLView {
    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLuint          _program;
    GLint           _uniformMatrix;
    GLfloat         _vertices[8];
    GLfloat         _texCoords[8];
    
    int             _frameWidth;
    int             _frameHeight;
    
    int             _frameSarNum;
    int             _frameSarDen;
    int             _rightPaddingPixels;
    GLfloat         _rightPadding;
    int             _bytesPerPixel;
    
    GLfloat         _prevScaleFactor;
    
    id<NTESGLRender>        _renderer;
    CVOpenGLESTextureCacheRef _textureCache;
    
    BOOL            _didSetContentMode;
    BOOL            _didRelayoutSubViews;
    BOOL            _didVerticesChanged;
    BOOL            _didPaddingChanged;
    
    int             _tryLockErrorCount;
    BOOL            _didSetupGL;
    BOOL            _didStopGL;
    NSMutableArray *_registeredNotifications;
}

enum {
    NTES_ATTRIBUTE_VERTEX,
   	NTES_ATTRIBUTE_TEXCOORD,
};

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        _tryLockErrorCount = 0;
        
        self.glActiveLock = [[NSRecursiveLock alloc] init];
        _registeredNotifications = [[NSMutableArray alloc] init];
        [self registerApplicationObservers];
        
        _didSetupGL = NO;
        [self setupGLOnce];
    }
    
    return self;
}

- (BOOL)setupEAGLContext:(EAGLContext *)context
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        DDLogDebug(@"failed to make complete framebuffer object %x\n", status);
        return NO;
    }
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
    if (err) {
        DDLogDebug(@"Error at CVOpenGLESTextureCacheCreate %d\n", err);
        return NO;
    }
    
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        DDLogDebug(@"failed to setup GL %x\n", glError);
        return NO;
    }
    
    _vertices[0] = -1.0f;  // x0
    _vertices[1] = -1.0f;  // y0
    _vertices[2] =  1.0f;  // ..
    _vertices[3] = -1.0f;
    _vertices[4] = -1.0f;
    _vertices[5] =  1.0f;
    _vertices[6] =  1.0f;  // x3
    _vertices[7] =  1.0f;  // y3
    
    _texCoords[0] = 0.0f;
    _texCoords[1] = 1.0f;
    _texCoords[2] = 1.0f;
    _texCoords[3] = 1.0f;
    _texCoords[4] = 0.0f;
    _texCoords[5] = 0.0f;
    _texCoords[6] = 1.0f;
    _texCoords[7] = 0.0f;
    
    _rightPadding = 0.0f;
    
    return YES;
}

- (BOOL)setupGL
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];
    
    _scaleFactor = [[UIScreen mainScreen] scale];
    if (_scaleFactor < 0.1f)
        _scaleFactor = 1.0f;
    _prevScaleFactor = _scaleFactor;
    
    [eaglLayer setContentsScale:_scaleFactor];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (_context == nil) {
        DDLogDebug(@"failed to setup EAGLContext\n");
        return NO;
    }
    
    EAGLContext *prevContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_context];
    
    _didSetupGL = NO;
    if ([self setupEAGLContext:_context]) {
        DDLogDebug(@"OK setup GL\n");
        _didSetupGL = YES;
    }
    
    [EAGLContext setCurrentContext:prevContext];
    return _didSetupGL;
}

- (BOOL)setupGLGuarded
{
    if (![self tryLockGLActive]) {
        return NO;
    }
    
    BOOL didSetupGL = [self setupGL];
    [self unlockGLActive];
    return didSetupGL;
}

- (BOOL)setupGLOnce
{
    if (_didSetupGL)
        return YES;
    
    if ([self isApplicationActive] == NO)
        return NO;
    
    __block BOOL didSetup = NO;
    if ([NSThread isMainThread]) {
        didSetup = [self setupGLGuarded];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            didSetup = [self setupGLGuarded];
        });
    }
    
    return didSetup;
}

- (BOOL)isApplicationActive
{
    UIApplicationState appState = [UIApplication sharedApplication].applicationState;
    switch (appState) {
        case UIApplicationStateActive:
            return YES;
        case UIApplicationStateInactive:
        case UIApplicationStateBackground:
        default:
            return NO;
    }
}

- (void)dealloc
{
    [self lockGLActive];
    
    _didStopGL = YES;
    _renderer = nil;
    
    EAGLContext *prevContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_context];
    
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    if (_textureCache) {
        CFRelease(_textureCache);
        _textureCache = 0;
    }
    
    [EAGLContext setCurrentContext:prevContext];
    
    _context = nil;
    
    [self unregisterApplicationObservers];
    
    [self unlockGLActive];
}

- (void)setScaleFactor:(CGFloat)scaleFactor
{
    _scaleFactor = scaleFactor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _didRelayoutSubViews = YES;
}

- (void)layoutOnDisplayThread
{
    int backingWidth  = 0;
    int backingHeight = 0;
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if (_backingWidth != backingWidth || _backingHeight != backingHeight) {
        _backingWidth  = backingWidth;
        _backingHeight = backingHeight;
        _didVerticesChanged = YES;
    }
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        
        DDLogDebug(@"failed to make complete framebuffer object %x", status);
        
    } else {
        
        DDLogDebug(@"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    _didSetContentMode = YES;
    
    [self performSelector:@selector(displayInRenderThread:)
                 onThread:[NTESVideoRenderThread thread]
               withObject:[[NTESGLVoutOverlay alloc] initWithData:nil w:0 h:0]
            waitUntilDone:NO];
}

- (BOOL)setupDisplay: (NTESGLVoutOverlay *) overlay
{
    
    if (_renderer == nil) {
        if (overlay == nil) {
            return NO;
        } else {
            _renderer = [[NTESGLRenderI420 alloc] init];
            _bytesPerPixel = 1;
            DDLogDebug(@"OK use I420 GL renderer");
        }
        
        if (![self loadShaders]) {
            return NO;
        }
    }
    
    if (overlay) {
        if (_frameWidth  != overlay.w ||
            _frameHeight != overlay.h ||
            _frameSarNum != overlay.sarNum ||
            _frameSarDen != overlay.sarDen) {
            _frameWidth  = overlay.w;
            _frameHeight = overlay.h;
            _frameSarNum = overlay.sarNum;
            _frameSarDen = overlay.sarDen;
            _didVerticesChanged = YES;
        }
        
        if (!overlay.isPrivate  && _frameWidth > 0) {
            int frameBufferWidth   = [overlay pitch:0] / _bytesPerPixel;
            int rightPaddingPixels = frameBufferWidth - _frameWidth;
            if (rightPaddingPixels != _rightPaddingPixels) {
                _rightPaddingPixels = rightPaddingPixels;
                _rightPadding       = ((GLfloat)_rightPaddingPixels) / frameBufferWidth;
            }
        }
    }
    
    return YES;
}

- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    _program = glCreateProgram();
    
    vertShader = compileShader(GL_VERTEX_SHADER, g_vertexShaderString);
    if (!vertShader)
        goto exit;
    
    fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.fragmentShader);
    if (!fragShader)
        goto exit;
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    glBindAttribLocation(_program, NTES_ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, NTES_ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        DDLogDebug(@"Failed to link program %d", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
    
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    [_renderer resolveUniforms:_program];
    
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        DDLogDebug(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(_program);
        _program = 0;
    }
    
    return result;
}

- (void)updateVertices
{
    float width                 = _frameWidth;
    float height                = _frameHeight;
    const float dW              = (float)_backingWidth	/ width;
    const float dH              = (float)_backingHeight / height;
    float dd                    = 1.0f;
    float nW                    = 1.0f;
    float nH                    = 1.0f;
    
    if (_frameSarNum > 0 && _frameSarDen > 0) {
        width = width * _frameSarNum / _frameSarDen;
    }
    
    switch (self.contentMode) {
        case UIViewContentModeScaleToFill:
            break;
        case UIViewContentModeCenter:
            nW = 1.0f / dW / [UIScreen mainScreen].scale;
            nH = 1.0f / dH / [UIScreen mainScreen].scale;
            break;
        case UIViewContentModeScaleAspectFill:
            dd = MAX(dW, dH);
            nW = (width  * dd / (float)_backingWidth );
            nH = (height * dd / (float)_backingHeight);
            break;
        case UIViewContentModeScaleAspectFit:
        default:
            dd = MIN(dW, dH);
            nW = (width  * dd / (float)_backingWidth );
            nH = (height * dd / (float)_backingHeight);
            break;
    }
    
    _vertices[0] = - nW;
    _vertices[1] = - nH;
    _vertices[2] =   nW;
    _vertices[3] = - nH;
    _vertices[4] = - nW;
    _vertices[5] =   nH;
    _vertices[6] =   nW;
    _vertices[7] =   nH;
}

- (void) render:(NSData *)yuvData width:(NSUInteger)width height:(NSUInteger)height
{
    NTESGLVoutOverlay *overlay = [[NTESGLVoutOverlay alloc] initWithData:yuvData w:width h:height];
    
    [self performSelector:@selector(displayInRenderThread:)
                 onThread:[NTESVideoRenderThread thread]
               withObject:overlay
            waitUntilDone:NO];
}


- (void)displayInRenderThread:(NTESGLVoutOverlay *)overlay
{
    if ([self setupGLOnce]) {
        // gles throws gpus_ReturnNotPermittedKillClient, while app is in background
        if (![self tryLockGLActive]) {
            if (0 == (_tryLockErrorCount % 100)) {
                DDLogDebug(@"NTESGLView:display: unable to tryLock GL active: %d\n", _tryLockErrorCount);
            }
            _tryLockErrorCount++;
            return;
        }
        
        _tryLockErrorCount = 0;
        if (!_didStopGL) {
            if (_context == nil) {
                DDLogDebug(@"NTESGLView: nil EAGLContext\n");
                return;
            }
            EAGLContext *prevContext = [EAGLContext currentContext];
            [EAGLContext setCurrentContext:_context];
            [self displayInternal:overlay];
            [EAGLContext setCurrentContext:prevContext];
        }
        
        [self unlockGLActive];
    }
}

- (void)displayInternal: (NTESGLVoutOverlay *)overlay
{
    CGFloat newScaleFactor = _scaleFactor;
    if (_prevScaleFactor != newScaleFactor) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        [eaglLayer setContentsScale:newScaleFactor];
        
        _prevScaleFactor = newScaleFactor;
    }
    
    if (![self setupDisplay:overlay]) {
        DDLogDebug(@"NTESGLView: setupDisplay failed\n");
        return;
    }
    
    if (_didRelayoutSubViews) {
        _didRelayoutSubViews = NO;
        [self layoutOnDisplayThread];
    }
    
    if (_didSetContentMode || _didVerticesChanged) {
        _didSetContentMode = NO;
        _didVerticesChanged = NO;
        [self updateVertices];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    
    if (overlay) {
        [_renderer render:overlay];
    }
    
    if ([_renderer prepareDisplay]) {
        _texCoords[0] = 0.0f;
        _texCoords[1] = 1.0f;
        _texCoords[2] = 1.0f - _rightPadding;
        _texCoords[3] = 1.0f;
        _texCoords[4] = 0.0f;
        _texCoords[5] = 0.0f;
        _texCoords[6] = 1.0f - _rightPadding;
        _texCoords[7] = 0.0f;
        
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(NTES_ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(NTES_ATTRIBUTE_VERTEX);
        glVertexAttribPointer(NTES_ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, _texCoords);
        glEnableVertexAttribArray(NTES_ATTRIBUTE_TEXCOORD);
        
#if 0
        if (!validateProgram(_program))
        {
            DDLogDebug(@"Failed to validate program");
            return;
        }
#endif
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context presentRenderbuffer:GL_RENDERBUFFER];
        
    }
}

#pragma mark AppDelegate

- (void) lockGLActive
{
    [self.glActiveLock lock];
}

- (void) unlockGLActive
{
    @synchronized(self) {
        [self.glActiveLock unlock];
    }
}

- (BOOL) tryLockGLActive
{
    if (![self.glActiveLock tryLock])
        return NO;
    
    if (self.glActivePaused) {
        [self.glActiveLock unlock];
        return NO;
    }
    
    return YES;
}

- (void)toggleGLPaused:(BOOL)paused
{
    [self lockGLActive];
    self.glActivePaused = paused;
    [self unlockGLActive];
}

- (void)registerApplicationObservers
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationWillEnterForegroundNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationDidBecomeActiveNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationWillResignActiveNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationDidEnterBackgroundNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationWillTerminateNotification];
}

- (void)unregisterApplicationObservers
{
    for (NSString *name in _registeredNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:name
                                                      object:nil];
    }
}

- (void)applicationWillEnterForeground
{
    DDLogDebug(@"NTESGLView:applicationWillEnterForeground: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:NO];
}

- (void)applicationDidBecomeActive
{
    DDLogDebug(@"NTESGLView:applicationDidBecomeActive: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:NO];
}

- (void)applicationWillResignActive
{
    DDLogDebug(@"NTESGLView:applicationWillResignActive: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:YES];
}

- (void)applicationDidEnterBackground
{
    DDLogDebug(@"NTESGLView:applicationDidEnterBackground: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:YES];
}

- (void)applicationWillTerminate
{
    DDLogDebug(@"NTESGLView:applicationWillTerminate: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:YES];
}

#pragma mark snapshot

- (UIImage*)snapshot
{
    [self lockGLActive];
    
    UIImage *image = [self snapshotInternal];
    
    [self unlockGLActive];
    
    return image;
}

- (UIImage*)snapshotInternal
{
    if (isIOS7OrLater()) {
        return [self snapshotInternalOnIOS7AndLater];
    } else {
        return [self snapshotInternalOnIOS6AndBefore];
    }
}

- (UIImage*)snapshotInternalOnIOS7AndLater
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    // Render our snapshot into the image context
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    
    // Grab the image from the context
    UIImage *complexViewImage = UIGraphicsGetImageFromCurrentImageContext();
    // Finish using the context
    UIGraphicsEndImageContext();
    
    return complexViewImage;
}

- (UIImage*)snapshotInternalOnIOS6AndBefore
{
    EAGLContext *prevContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_context];
    
    GLint backingWidth, backingHeight;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "viewRenderbuffer" with the actual name of the renderbuffer object defined in your class.
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger length = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(length * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels((int)x, (int)y, (int)width, (int)height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, length, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    [EAGLContext setCurrentContext:prevContext];
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

@end
