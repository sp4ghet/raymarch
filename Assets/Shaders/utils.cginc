#ifndef UTILS
#define UTILS
// Operators
float3 twistY(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return mul(m, p);
}


float3 mod(float3 a, float3 b){
    return frac(abs(a / b)) * abs(b);
}

float3 repeat(float3 pos, float3 span){
    return mod(pos, span) - span * 0.5;
}

float displacement(float d, float3 p){
    float freq = 5;
    return d + sin(freq*p.x)*sin(freq*p.y)*sin(freq*p.z);
}

float smin( float a, float b){
    float k = 0.5f;
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return lerp( b, a, h ) - k*h*(1.0-h);
}

float blend(float d1, float d2){
    return smin(d1, d2);
}

#endif