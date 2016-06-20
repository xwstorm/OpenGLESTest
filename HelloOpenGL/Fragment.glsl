precision mediump float;
precision lowp float;
varying lowp vec4 DestinationColor; // 1
varying lowp vec2 fragTexCoord;

uniform sampler2D tex_y;
uniform sampler2D tex_u;
uniform sampler2D tex_v;

void main(void) { // 2
    gl_FragColor = DestinationColor; // 3
    
    vec3 yuv;
    yuv.x = 1.0;
    yuv.y = 0.0;
    yuv.z = 0.0;
    
    
    vec3 rgb;
    yuv.x = texture2D(tex_y, fragTexCoord).r;
    yuv.y = texture2D(tex_u, fragTexCoord).r - 0.5;
    yuv.z = texture2D(tex_v, fragTexCoord).r - 0.5;
    
//    yuv.x = fragTexCoord.x;
//    yuv.y = fragTexCoord.y;
//    yuv.z = fragTexCoord.x;
//    if (fragTexCoord.x > 0.2) {
//        yuv.x = 0.3;
//        yuv.y = -0.147;
//        yuv.z = 0.5;
//    }
//
//    yuv.x = 1;
//    yuv.y = 0;
//    yuv.z = 0;
    
    rgb = mat3( 1.0,       1.0,         1.0,
               0.0,       -0.39465,  2.03211,
               1.13983, -0.58060,  0.0)  * yuv;
    gl_FragColor = vec4(rgb, 1);
    gl_FragColor = vec4(rgb.r, rgb.g, rgb.b, 1.0);
//    gl_FragColor = vec4(yuv, 1);
}