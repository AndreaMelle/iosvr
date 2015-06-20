attribute vec4 position;
attribute vec2 texCoord;

uniform mat4 u_MVPMatrix;

varying vec2 texCoordVarying;

void main()
{
	gl_Position = u_MVPMatrix * position;
	texCoordVarying = texCoord;
}

