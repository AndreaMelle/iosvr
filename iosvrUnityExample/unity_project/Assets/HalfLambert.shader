Shader "Diffuse/HalfLambert"
{
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque"}

        CGPROGRAM
        #include "UnityCG.cginc"
        #pragma surface surf NPR noambient
 
        uniform fixed4 _Color;
 
        half4 LightingNPR(SurfaceOutput o, half3 lightdir, half3 halfdir, fixed atten)
        {
            half lambert = saturate(dot(o.Normal, lightdir));
            lambert = lambert * 0.5 + 0.5;
            fixed4 diff = fixed4(_LightColor0.rgb * 2 * atten * o.Albedo.rgb * lambert, 1.0);
            return diff;
        }
 
        struct Input
        {
            half2 uv_MainTex;
        };
 
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = _Color.rgb;
        }
        ENDCG
    }
    FallBack "Diffuse"
}