attribute vec4 Position; // 1
attribute vec4 SourceColor; // 2
attribute vec2 vertTexCoord;

varying vec4 DestinationColor; // 3
varying vec2 fragTexCoord;

void main(void) { // 4
    DestinationColor = SourceColor; // 5
    fragTexCoord = vertTexCoord;
    gl_Position = Position; // 6
}