varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D tex;

void main()
{
	mediump vec3 rgb;
    rgb = texture2D(tex, texCoordVarying).rgb;
    
//    rgb[0] = texCoordVarying[0];
//    rgb[1] = texCoordVarying[1];
//    rgb[2] = texCoordVarying[0] * texCoordVarying[1];
    
	gl_FragColor = vec4(rgb,1);
}