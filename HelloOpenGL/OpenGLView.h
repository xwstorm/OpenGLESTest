//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by Leelen-mac1 on 14-3-21.
//  Copyright (c) 2014年 Leelen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
@interface OpenGLView : UIView
{
    //If you plan to use OpenGL for your rendering, use this class as the backing layer for your views by returning it from your view’s layerClass class method.
    CAEAGLLayer *_eaglLayer;
    //An EAGLContext object manages an OpenGL ES rendering context—the state information, commands, and resources needed to draw using OpenGL ES. To execute OpenGL ES commands, you need a current rendering context.
    EAGLContext *_context;
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _texCoordSlot;
    
    GLuint id_y, id_u, id_v; // 纹理id
    GLuint textureUniformY, textureUniformU,textureUniformV;
    GLuint programHandle;
}

@end
