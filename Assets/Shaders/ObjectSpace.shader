// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Raymarching/Object"
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
#include "utils.cginc"

float4 _Scale;
sampler2D _MainTex;

inline bool IsInnerBox(float3 pos, float3 scale){
	return 
		abs(pos.x) < scale.x * 0.5 &&
		abs(pos.y) < scale.y * 0.5 &&
		abs(pos.z) < scale.z * 0.5;
}

inline bool IsInnerSphere(float3 pos, float3 scale){
	return length(pos) < abs(scale) * 0.5;
}

float DistanceFunc(float3 pos){
	float t = _Time.x;
	float a = 6 * 3.14159265 * t;
	float s = pow(sin(a), 2.0);
	float d1 = sphere(pos, 0.75);
	float d2 = roundbox(
		repeat(pos, 0.2),
		0.1 - 0.1 * s,
		0.1 / length(pos * 2.0));
	return lerp(d1, d2, s);


}

// To Local Space
inline float3 ToLocal(float3 pos){
	return mul(unity_WorldToObject, float4(pos,1.0)).xyz * abs(_Scale);
}
float ObjectSpaceDistanceFunc(float3 pos){
	return DistanceFunc(ToLocal(pos));
}

void RayMarch(inout float3 pos, out float distance, float3 rayDir, float minDistance, int loop){

	float len = 0.0;

	for (int n = 0; n < loop; ++n) {
		distance = ObjectSpaceDistanceFunc(pos);
		len += distance;
		pos += rayDir * distance;
		if (!IsInnerBox(ToLocal(pos), _Scale) || distance < minDistance) break;
	}

	if (distance > minDistance) discard;

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
		ObjectSpaceDistanceFunc(pos + float3(  d, 0.0, 0.0)) - ObjectSpaceDistanceFunc(pos + float3( -d, 0.0, 0.0)),
		ObjectSpaceDistanceFunc(pos + float3(0.0,   d, 0.0)) - ObjectSpaceDistanceFunc(pos + float3(0.0,  -d, 0.0)),
		ObjectSpaceDistanceFunc(pos + float3(0.0, 0.0,   d)) - ObjectSpaceDistanceFunc(pos + float3(0.0, 0.0,  -d))));
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
	#include "RayMarching.cginc"
	
	// endstructs

	VertOutput vert(VertInput v){
		VertOutput o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.screenPos = o.vertex;
		o.worldPos = mul(unity_ObjectToWorld, v.vertex);
		o.worldNormal = mul(unity_ObjectToWorld, v.normal);
		return o;
	}

	GBufferOut frag(VertOutput i){
		float4 screenPos = i.screenPos;
#if UNITY_UV_STARTS_AT_TOP
		screenPos.y *= -1;
#endif
		screenPos.x *= _ScreenParams.x / _ScreenParams.y; //端から端が0~1にする
		screenPos.xy = screenPos.xy / screenPos.w;

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
		//float3 pos = camPos + _ProjectionParams.y * rayDir;
		float3 pos = i.worldPos;
		RayMarch(pos, distance, rayDir, 0.001, 100);

		float depth = GetDepth(pos);
		float3 normal = i.worldNormal * 0.5 + 0.5;
		if(distance > 0){
			normal = GetNormal(pos);
		}

		float u = (1.0 - floor(fmod(pos.x, 2.0))) * 5;
		float v = (1.0 - floor(fmod(pos.y, 2.0))) * 5;

		GBufferOut o;
		//o.diffuse  = tex2D(_MainTex, float2(u,v));
		o.diffuse = float4(1.0, 1.0, 1.0, 1.0);
		o.specular = float4(1.0, 1.0, 1.0, 1.0)	;
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
Pass{
	Tags { "LightMode" = "ShadowCaster"}

	CGPROGRAM
	#pragma target 3.0
	#pragma vertex vert_shadow
	#pragma fragment frag_shadow
	#pragma multi_compile_shadowcaster
	#pragma fragmentoption ARB_precision_hint_fastest

	struct VertShadowInput{
		float4 vertex : POSITION;
		float4 normal : NORMAL;
	};
	struct VertShadowOutput{
		V2F_SHADOW_CASTER;
		float4 screenPos : TEXCOORD1;
		float4 worldPos : TEXCOORD2;
		float4 normal : TEXCOORD3;
	};
	
	VertShadowOutput vert_shadow(VertShadowInput v)
	{
		VertShadowOutput o;
		TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
		o.screenPos = o.pos;
		o.worldPos = mul(unity_ObjectToWorld, v.vertex);
		o.normal = v.normal;
		return o;
	}

	float3 GetRayDirectionForShadow(float4 screenPos){
		float4 sp = screenPos;
#if UNITY_UV_STARTS_AT_TOP
		sp.y *= -1.0;
#endif		
		sp.xy /= sp.w;
	
		float3 camPos      = GetCameraPosition();
		float3 camDir      = GetCameraForward();
		float3 camUp       = GetCameraUp();
		float3 camSide     = GetCameraRight();
		float  focalLen    = GetCameraFocalLength();
		float  maxDistance = GetCameraMaxDistance();

		return normalize((camSide*sp.x) + (camUp*sp.y) + (camDir*focalLen));
	}

#ifdef SHADOWS_CUBE
	float4 frag_shadow(VertShadowOutput i) : SV_Target
	{
		float3 rayDir = GetRayDirectionForShadow(i.screenPos);
		float3 pos = i.worldPos;
		float distance = 0.0;
		Raymarch(pos, distance, rayDir, 0.001, 10);

		i.vec = pos - _LightPositionRange.xyz;
		SHADOW_CASTER_FRAGMENT(i);
	}
#else
	void frag_shadow(
		VertShadowOutput i,
		out float4  outColor : SV_Target,
		out float	outDepth : SV_Depth)
	{
		float3 rayDir = -UNITY_MATRIX_V[2].xyz;

		if( UNITY_MATRIX_P[3].x != 0.0 ||
			UNITY_MATRIX_P[3].y != 0.0 ||
			UNITY_MATRIX_P[3].z != 0.0) {
			rayDir = GetRayDirectionForShadow(i.screenPos);
		}
	
		float3 pos = i.worldPos;
		float distance = 0.0;
		RayMarch(pos, distance, rayDir, 0.001, 10);
		
		float4 opos = mul(unity_WorldToObject, float4(pos,1.0));
		opos = UnityClipSpaceShadowCasterPos(opos, i.normal);
		opos = UnityApplyLinearShadowBias(opos);

		outColor = outDepth = opos.z / opos.w;
	}				
#endif
	ENDCG
}
}
}
