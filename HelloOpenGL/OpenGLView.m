//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by Leelen-mac1 on 14-3-21.
//  Copyright (c) 2014年 Leelen. All rights reserved.
//

#import "OpenGLView.h"

@implementation OpenGLView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setupLayer];
        [self setupContext];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        [self setupTex];
        [self render];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer *)self.layer;
    //提高性能
    _eaglLayer.opaque = YES;
}

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context)
    {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

//创建渲染缓冲区
- (void)setupRenderBuffer
{
    //  调用glGenRenderbuffers来创建一个新的render buffer object。这里返回一个唯一的integer来标记render buffer（这里把这个唯一值赋值到_colorRenderBuffer）。有时候你会发现这个唯一值被用来作为程序内的一个OpenGL 的名称。（反正它唯一嘛）
    glGenRenderbuffers(1, &_colorRenderBuffer);
    
    //调用glBindRenderbuffer ，告诉这个OpenGL：我在后面引用GL_RENDERBUFFER的地方，其实是想用_colorRenderBuffer。其实就是告诉OpenGL，我们定义的buffer对象是属于哪一种OpenGL对象
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //最后，为render buffer分配空间。renderbufferStorage
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

//创建帧缓冲区
- (void)setupFrameBuffer
{
    //Frame buffer也是OpenGL的对象，它包含了前面提到的render buffer，以及其它后面会讲到的诸如：depth buffer、stencil buffer 和 accumulation buffer。
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    //让你把前面创建的buffer render依附在frame buffer的GL_COLOR_ATTACHMENT0位置上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileShaders {
    
    // 1
    GLuint vertexShader = [self compileShader:@"Vertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"Fragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 2
    programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    _texCoordSlot = glGetAttribLocation(programHandle, "vertTexCoord");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    glEnableVertexAttribArray(_texCoordSlot);
}

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0},    {1, 0, 0, 1},   {1, 0} },// 右下
    {{1, 1, 0},     {0, 1, 0, 1},   {1, 1} },  // 右上
    {{-1, 1, 0},    {0, 0, 1, 1},   {0, 1} }, // 左上
    {{-1, -1, 0},   {0, 0, 0, 1},   {0, 0} } // 左下
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);// 绑定VBO，后面绘制的时候就不用再绑定了
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}

- (void)setupTex
{
    const unsigned int YUVWidth = 640;
    const unsigned int YUVHeight = 360;
    
    
        const unsigned int imageSize = YUVWidth * YUVHeight * 3 / 2;
        
        unsigned char buf[YUVWidth * YUVHeight * 2];
        
        
        FILE *infile = NULL;
        unsigned char *plane[3];
        
        // load filee
        char* fileName = "yuv420p_360_640.yuv";
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"yuv420p_360_640" ofType:@"yuv"];
//    NSData* tiffData = [[NSData alloc] initWithContentsOfFile:(imageName)];
    const char* fileName1 = [imageName UTF8String];
        if((infile=fopen(fileName1, "rb"))==NULL){
            printf("cannot open this file\n");
            return ;
        }
        if ( fread(buf, 1, imageSize, infile) != imageSize )
        {
            assert(false);
            return;
        }
    

        //YUV Data
        plane[0] = buf;
        plane[1] = plane[0] + YUVWidth*YUVHeight;
        plane[2] = plane[1] + YUVWidth*YUVHeight / 4;
        
        
        //Get Uniform Variables Location
        //oldTex = glGetUniformLocation(p, "tex");
        textureUniformY = glGetUniformLocation(programHandle, "tex_y");
        textureUniformU = glGetUniformLocation(programHandle, "tex_u");
        textureUniformV = glGetUniformLocation(programHandle, "tex_v");
        
        GLint errorCode = glGetError();
    
    glEnable(GL_TEXTURE_2D);
        //Init Texture
        glGenTextures(1, &id_y);
        glBindTexture(GL_TEXTURE_2D, id_y);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, YUVWidth, YUVHeight, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, plane[0]);
        
        glGenTextures(1, &id_u);
        glBindTexture(GL_TEXTURE_2D, id_u);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, YUVWidth/2, YUVHeight/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, plane[1]);
        
        glGenTextures(1, &id_v);
        glBindTexture(GL_TEXTURE_2D, id_v);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, YUVWidth/2, YUVHeight/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, plane[2]);
}

- (void)render
{
//    //调用glClearColor ，设置一个RGB颜色和透明度，接下来会用这个颜色涂满全屏。
//    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
//    //调用glClear来进行这个“填色”的动作（大概就是photoshop那个油桶嘛）。还记得前面说过有很多buffer的话，这里我们要用到GL_COLOR_BUFFER_BIT来声明要清理哪一个缓冲区。
//    glClear(GL_COLOR_BUFFER_BIT);
//    //调用OpenGL context的presentRenderbuffer方法，把缓冲区（render buffer和color buffer）的颜色呈现到UIView上
//    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    unsigned int texIndex = 0;
    // 显示YUV图像BEGIN
    glEnable(GL_TEXTURE_2D);
    
//    glActiveTexture(GL_TEXTURE0 + texIndex);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, id_y);
    glUniform1i(textureUniformY, texIndex++);
    //U
    glActiveTexture(GL_TEXTURE1 );
    glBindTexture(GL_TEXTURE_2D, id_u);
    glUniform1i(textureUniformU, texIndex++);
    //V
    glActiveTexture(GL_TEXTURE2 );
    glBindTexture(GL_TEXTURE_2D, id_v);
    glUniform1i(textureUniformV, texIndex++);
    
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

    
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}
@end
