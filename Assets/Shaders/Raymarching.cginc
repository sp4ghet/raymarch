// structs
	struct VertInput {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};

	struct VertOutput{
		float4 vertex : SV_POSITION;
		float4 screenPos : TEXCOORD0;
		float4 worldPos : TEXCOORD1;
		float3 worldNormal : TEXCOORD2;
	};

	struct GBufferOut{
		half4 diffuse	: SV_TARGET0; //rgb diffuse, a: occlusion
		half4 specular	: SV_TARGET1; //rgb specular, a: smoothness
		half4 normal	: SV_TARGET2; //rgb normal, a: unused
		half4 emission	: SV_TARGET3; //rgb emission, a: unused
		float depth		: SV_Depth;
	};