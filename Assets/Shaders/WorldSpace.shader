Shader "Raymarching/World"
{
Properties{
    _MainTex ("Main Texture", 2D) = "" {}
}

SubShader
{
Tags { "RenderType"="Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10"}
Cull Off

CGINCLUDE

#include "UnityCG.cginc"
#include "primitives.cginc"

float DistanceFunc(float3 pos){
    float d1 = RecursiveTetrahedron(pos);
    return d1;
}

float3 GetCameraPosition()		{	return _WorldSpaceCameraPos;		}
float3 GetCameraForward()		{	return -UNITY_MATRIX_V[2].xyz;		}
float3 GetCameraUp()			{	return UNITY_MATRIX_V[1].xyz;		}
float3 GetCameraRight()			{	return UNITY_MATRIX_V[0].xyz;		}
float GetCameraFocalLength()	{	return abs(UNITY_MATRIX_P[1][1]);	}
float GetCameraMaxDistance()	{	return _ProjectionParams.z - _ProjectionParams.y; }

float GetDepth(float3 pos){
    float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1));
#if defined(SHARED_TARGET_GLSL)
    return (vpPos.z / vpPos.w) * 0.5 + 0.5;
#else
    return vpPos.z / vpPos.w;
#endif
}

float3 GetNormal(float3 pos){
    const float d = 0.001;
    return 0.5 + 0.5 * normalize(float3(
        DistanceFunc(pos + float3(  d, 0.0, 0.0)) - DistanceFunc(pos + float3( -d, 0.0, 0.0)),
        DistanceFunc(pos + float3(0.0,   d, 0.0)) - DistanceFunc(pos + float3(0.0,  -d, 0.0)),
        DistanceFunc(pos + float3(0.0, 0.0,   d)) - DistanceFunc(pos + float3(0.0, 0.0,  -d))));
}


ENDCG

Pass
{

    Tags {"LightMode" = "Deferred"}

    Stencil {
        Comp Always
        Pass Replace
        Ref 128
    }
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #pragma target 3.0
    #pragma multi_compile ___ UNITY_HDR_ON
            
    #include "UnityCG.cginc"
    sampler2D _MainTex;
            
    // structs
    struct VertInput {
        float4 vertex : POSITION;
    };

    struct VertOutput{
        float4 vertex : SV_POSITION;
        float4 screenPos : TEXCOORD0;
    };

    struct GBufferOut{
        half4 diffuse	: SV_TARGET0; //rgb diffuse, a: occlusion
        half4 specular	: SV_TARGET1; //rgb specular, a: smoothness
        half4 normal	: SV_TARGET2; //rgb normal, a: unused
        half4 emission	: SV_TARGET3; //rgb emission, a: unused
        float depth		: SV_Depth;
    };
    // endstructs

    VertOutput vert(VertInput v){
        VertOutput o;
        o.vertex = v.vertex;
        o.screenPos = o.vertex;
        return o;
    }

    GBufferOut frag(VertOutput i){
        float4 screenPos = i.screenPos;
#if UNITY_UV_STARTS_AT_TOP
        screenPos.y *= -1;
#endif
        screenPos.x *= _ScreenParams.x / _ScreenParams.y; //端から端が0~1にする

        float3 camPos	= GetCameraPosition();
        float3 camDir	= GetCameraForward();
        float3 camUp	= GetCameraUp();
        float3 camSide	= GetCameraRight();
        float focalLen	= GetCameraFocalLength();
        float maxDist	= GetCameraMaxDistance();

        // Create worldspace ray from screen position and camera transform
        float3 rayDir = normalize(
            camSide * screenPos.x +
            camUp	* screenPos.y + 
            camDir	* focalLen);

        float distance = 0.;
        float len = 0.;
        float3 pos = camPos + _ProjectionParams.y * rayDir;

        for(int i = 0 ; i < 50; ++i){
            distance = DistanceFunc(pos);
            len += distance;
            pos += rayDir * distance;
            if(distance < 0.001 || len > maxDist) break;
        }

        if(distance > 0.001) discard;

        float depth = GetDepth(pos);
        float3 normal = GetNormal(pos);

        float u = (1.0 - floor(fmod(pos.x, 2.0))) * 5;
        float v = (1.0 - floor(fmod(pos.y, 2.0))) * 5;

        GBufferOut o;
        //o.diffuse  = tex2D(_MainTex, float2(u,v));
        o.diffuse = float4(1.0, 1.0, 1.0, 1.0);
        o.specular = float4(0.5, 0.5, 0.5, 1.0);
        o.emission = float4(0.0, 0.0, 0.0, 0.0);
        o.depth    = depth;
        o.normal   = float4(normal, 1.0);

#ifndef UNITY_HDR_ON
        o.emission = exp2(-o.emission);
#endif

        return o;

    }


    ENDCG
}
}
}
