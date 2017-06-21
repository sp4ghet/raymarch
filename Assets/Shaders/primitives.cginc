#ifndef primitives_h
#define primitives_h
#include "utils.cginc"
float PI = 3.14159265;
// Signed Distance Functions
float RecursiveTetrahedron(float3 p)
{
    p = repeat(p / 2, 3.0);

    const float3 a1 = float3( 1.0,  1.0,  1.0);
    const float3 a2 = float3(-1.0, -1.0,  1.0);
    const float3 a3 = float3( 1.0, -1.0, -1.0);
    const float3 a4 = float3(-1.0,  1.0, -1.0);

    const float scale = 2.0;
    float d;
    for (int n = 0; n < 20; ++n) {
        float3 c = a1; 
        float minDist = length(p - a1);
        d = length(p - a2); if (d < minDist) { c = a2; minDist = d; }
        d = length(p - a3); if (d < minDist) { c = a3; minDist = d; }
        d = length(p - a4); if (d < minDist) { c = a4; minDist = d; }
        p = scale * p - c * (scale - 1.0);
    }
 
    return length(p) * pow(scale, float(-n));
}

float roundbox(float3 pos, float3 sides, float radius){
    return length(max(abs(pos)-sides, 0.)) - radius;
}

float sphere(float3 pos, float radius){
    return length(pos) - radius;
}

float hexprism( float3 p, float2 h )
{
    float3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float floor(float3 pos)
{
    return dot(pos, float3(0.0, 1.0, 0.0)) + 1.0;
}

float torus( float3 p, float2 t )
{
  float2 q = float2(length(p.xy)-t.x,p.z);
  return length(q)-t.y;
}
#endif