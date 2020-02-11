// macros

#define PROFILE_VS vs_5_0
#define PROFILE_HS hs_5_0
#define PROFILE_DS ds_5_0
#define PROFILE_PS ps_5_0

// constants

//static const float ReferenceAlpha = 0.25;
static const float HohoAlpha = 0.40;

// variables

uniform matrix	wld			: World;
uniform	matrix	wv			: WorldView; // not used
uniform matrix	wvp			: WorldViewProjection;
uniform matrix	view		: View;
uniform matrix	proj		: Projection; // not used
uniform matrix	vp			: ViewProjection;
uniform matrix	wit			: WorldInverseTranspose;

const uniform matrix	LocalBoneMats[16];
const uniform matrix	LocalBoneITMats[16];

// per material (SubScript)
cbuffer cb
{
	float Ambient;
	float Thickness;
	float ColorBlend;
	float ShadeBlend;

	float HighLight;
	float HighLightBlend;
	float HighLightPower;
	float TessFactor;

	float FrontLightPower;
	float BackLightPower;
	float UVScrollX; // OBSOLETE
	float UVScrollY; // OBSOLETE

	float4 PenColor;
	//float4 ShadowColor;
	//float4 ManColor;

	float4 FrontLight;
	float4 BackLight;
};

// per pass
cbuffer cb_per_pass
{
	float ReferenceAlpha;
	float p1;
	float p2;
	float p3;
}

uniform float4 LightDirForced : Direction;
uniform float4 UVSCR;
//uniform float SHADOW_HEIGHT;

// sampler

SamplerState ShadeTex
{
	Filter = ANISOTROPIC;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MaxAnisotropy = 16;
};

SamplerState ColorTex
{
	Filter = ANISOTROPIC;
	AddressU = WRAP;
	AddressV = WRAP;
	MaxAnisotropy = 16;
};

// resources

Texture2D	ShadeTex_texture;
Texture2D	ColorTex_texture;

// structs

struct appdata
{
	float3	Position	: POSITION;
	float2	UV			: TEXCOORD0;
	float3	Normal		: NORMAL;
	float4	VWeights	:	TEXCOORD3;
	int4	BoneIdxs	:	TEXCOORD4;
};

struct cHSData
{
	float3	Position	: POSITION;
	float2	UV			: TEXCOORD0;
	float3	Normal		: TEXCOORD1;
};

struct cHSData2
{
	float3	Position	: POSITION;
	float3	Normal		: TEXCOORD1;
};

struct cCPData
{
    float3 Position : BEZIERPOS;
};

struct cVertexData
{
	float4	Position	: SV_POSITION;
	float2	UV			: TEXCOORD0;
	float3	Normal		: TEXCOORD1;
};

struct cVertexData2
{
	float4	Position	: SV_POSITION;
};

// functions

void calc_skindeform( float3 position, float3 normal, float4 weights, int4 idxs, out float3 outpos, out float3 outnor )
{
	float4 ipos		=	float4( position, 1 );
	float3 inor		=	normal;

	float4x4 mat = LocalBoneMats[idxs.x] * weights.x +
		LocalBoneMats[idxs.y] * weights.y +
		LocalBoneMats[idxs.z] * weights.z +
		LocalBoneMats[idxs.w] * weights.w;

	float4x4 itmat = LocalBoneITMats[idxs.x] * weights.x +
		LocalBoneITMats[idxs.y] * weights.y +
		LocalBoneITMats[idxs.z] * weights.z +
		LocalBoneITMats[idxs.w] * weights.w;

	float4 pos		=	mul( ipos, mat );
	float3 nor		=	mul( inor, (float3x3)itmat );

	outpos		=	pos.xyz;
	outnor		=	nor;
}

// vertex shader

#ifdef USE_TESSELLATION
cHSData2
#else
cVertexData2
#endif
cInkVS( appdata IN )
{
#ifdef USE_TESSELLATION
	cHSData2 OUT;
#else
	cVertexData2 OUT;
#endif
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

#ifdef USE_TESSELLATION
	OUT.Position	= mul( float4( pos, 1 ), wld ).xyz;
	OUT.Normal	= mul( nor, (float3x3)wit );
#else
	pos += normalize(nor) * Thickness;
	OUT.Position	= mul( float4( pos, 1 ), wvp );
#endif

	return OUT;
}

#ifdef USE_TESSELLATION
cHSData2
#else
cVertexData2
#endif
cBackInkVS( appdata IN )
{
#ifdef USE_TESSELLATION
	cHSData2 OUT;
#else
	cVertexData2 OUT;
#endif
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

#ifdef USE_TESSELLATION
	OUT.Position	= mul( float4( pos, 1 ), wld ).xyz;
	OUT.Normal	= mul( nor, (float3x3)wit );
#else
	pos -= normalize(nor) * Thickness;
	OUT.Position	= mul( float4( pos, 1 ), wvp );
#endif

	return OUT;
}

#ifdef USE_TESSELLATION
cHSData
#else
cVertexData
#endif
cMainVS( appdata IN )
{
#ifdef USE_TESSELLATION
	cHSData OUT;
#else
	cVertexData OUT;
#endif
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

#ifdef USE_TESSELLATION
	OUT.Position	= mul( float4( pos, 1 ), wld ).xyz;
	OUT.UV		= IN.UV;
	OUT.Normal	= mul( nor, (float3x3)wit );
#else
	OUT.Position	= mul( float4( pos, 1 ), wvp );
	OUT.UV		= IN.UV;
	OUT.Normal	= mul( nor, (float3x3)wit );
#endif

	return OUT;
}

cVertexData cMainVS_UVSCR( appdata IN )
{
	cVertexData OUT;
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position	= mul( float4( pos, 1 ), wvp );
	OUT.UV		= IN.UV + UVSCR.xy;
	OUT.Normal	= mul( nor, (float3x3)wit );

	return OUT;
}

// hull shader

struct cPatchData
{
    float EdgeTess[3] : SV_TessFactor;
    float InsideTess : SV_InsideTessFactor;
	float2	UV[3]			: TEXCOORD0;
	float3	Normal[3]		: TEXCOORD3;
};

struct cPatchData2
{
    float EdgeTess[3] : SV_TessFactor;
    float InsideTess : SV_InsideTessFactor;
	float3	Normal[3]		: TEXCOORD3;
};

// Triangle patch constant func (executes once for each patch)
cPatchData PatchHS(InputPatch<cHSData, 3> patch, uint patchID : SV_PrimitiveID)
{
    cPatchData pt;

	float3 rawEdgeFactors;
	rawEdgeFactors[0] = TessFactor;
	rawEdgeFactors[1] = TessFactor;
	rawEdgeFactors[2] = TessFactor;

    float3 roundedEdgeTessFactors;
    float roundedInsideTessFactor, unroundedInsideTessFactor;
    ProcessTriTessFactorsMax(rawEdgeFactors, 1.0, roundedEdgeTessFactors, roundedInsideTessFactor, unroundedInsideTessFactor);

    // Apply the edge and inside tessellation factors
    pt.EdgeTess[0] = roundedEdgeTessFactors.x;
    pt.EdgeTess[1] = roundedEdgeTessFactors.y;
    pt.EdgeTess[2] = roundedEdgeTessFactors.z;
    pt.InsideTess = roundedInsideTessFactor;
	
	pt.UV[0] = patch[0].UV;
	pt.UV[1] = patch[1].UV;
	pt.UV[2] = patch[2].UV;

	pt.Normal[0] = patch[0].Normal;
	pt.Normal[1] = patch[1].Normal;
	pt.Normal[2] = patch[2].Normal;

    return pt;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchHS")]
cCPData cTriEqualHS(InputPatch<cHSData, 3> p, uint i : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    cCPData hout;
	
	// Pass through shader.
    hout.Position = p[i].Position;
	
    return hout;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchHS")]
cCPData cTriFractionalOddHS(InputPatch<cHSData, 3> p, uint i : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    cCPData hout;
	
	// Pass through shader.
    hout.Position = p[i].Position;
	
    return hout;
}

cPatchData2 PatchHS2(InputPatch<cHSData2, 3> patch, uint patchID : SV_PrimitiveID)
{
    cPatchData2 pt;

	float3 rawEdgeFactors;
	rawEdgeFactors[0] = TessFactor;
	rawEdgeFactors[1] = TessFactor;
	rawEdgeFactors[2] = TessFactor;

    float3 roundedEdgeTessFactors;
    float roundedInsideTessFactor, unroundedInsideTessFactor;
    ProcessTriTessFactorsMax(rawEdgeFactors, 1.0, roundedEdgeTessFactors, roundedInsideTessFactor, unroundedInsideTessFactor);

    // Apply the edge and inside tessellation factors
    pt.EdgeTess[0] = roundedEdgeTessFactors.x;
    pt.EdgeTess[1] = roundedEdgeTessFactors.y;
    pt.EdgeTess[2] = roundedEdgeTessFactors.z;
    pt.InsideTess = roundedInsideTessFactor;
	
	pt.Normal[0] = patch[0].Normal;
	pt.Normal[1] = patch[1].Normal;
	pt.Normal[2] = patch[2].Normal;

    return pt;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchHS2")]
cCPData cTriEqualHS2(InputPatch<cHSData2, 3> p, uint i : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    cCPData hout;
	
	// Pass through shader.
    hout.Position = p[i].Position;
	
    return hout;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchHS2")]
cCPData cTriFractionalOddHS2(InputPatch<cHSData2, 3> p, uint i : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    cCPData hout;
	
	// Pass through shader.
    hout.Position = p[i].Position;
	
    return hout;
}

// domain shader

float2 BarycentricInterpolate(float2 v0, float2 v1, float2 v2, float3 barycentric)
{
    return barycentric.z * v0 + barycentric.x * v1 + barycentric.y * v2;
}

float2 BarycentricInterpolate(float2 v[3], float3 barycentric)
{
    return BarycentricInterpolate(v[0], v[1], v[2], barycentric);
}

float3 BarycentricInterpolate(float3 v0, float3 v1, float3 v2, float3 barycentric)
{
    return barycentric.z * v0 + barycentric.x * v1 + barycentric.y * v2;
}

float3 BarycentricInterpolate(float3 v[3], float3 barycentric)
{
    return BarycentricInterpolate(v[0], v[1], v[2], barycentric);
}

float4 BarycentricInterpolate(float4 v0, float4 v1, float4 v2, float3 barycentric)
{
    return barycentric.z * v0 + barycentric.x * v1 + barycentric.y * v2;
}

float4 BarycentricInterpolate(float4 v[3], float3 barycentric)
{
    return BarycentricInterpolate(v[0], v[1], v[2], barycentric);
}

// Orthogonal projection on to plane
// Where v1 is a point on the plane, and n is the plane normal
// v2_projected = v2 - dot(v2-v1, n) * n;
float3 ProjectOntoPlane(float3 normal, float3 p1, float3 p2)
{
	// normal has not been normalized.
	normal = normalize(normal);
    return p2 - dot(p2 - p1, normal) * normal;
}

// Phong Tessellation Domain Shader
// This domain shader applies control point weighting to the barycentric coords produced by the fixed function tessellator stage
[domain("tri")]
cVertexData cMainDS(cPatchData patch, float3 bary : SV_DomainLocation, const OutputPatch<cCPData, 3> tri)
{
    cVertexData dout;

	// Interpolate patch attributes to generated vertices.
    float3 position = BarycentricInterpolate(tri[0].Position, tri[1].Position, tri[2].Position, bary);

#if 1
    // BEGIN Phong Tessellation
    // Orthogonal projection in the tangent planes
    float3 posProjectedU = ProjectOntoPlane(patch.Normal[0], tri[0].Position, position);
    float3 posProjectedV = ProjectOntoPlane(patch.Normal[1], tri[1].Position, position);
    float3 posProjectedW = ProjectOntoPlane(patch.Normal[2], tri[2].Position, position);

    // Interpolate the projected points
    position = lerp(position, BarycentricInterpolate(posProjectedU, posProjectedV, posProjectedW, bary), 0.5);

    // END Phong Tessellation
#endif
    
    // Interpolate array of UV coordinates
	float2 uv = BarycentricInterpolate(patch.UV, bary);
    // Interpolate array of normals
    float3 normal = BarycentricInterpolate(patch.Normal, bary);

    // Transform world position to view-projection
	dout.Position = mul(float4(position, 1), vp);

    dout.UV = uv;
	dout.Normal = normal;

    return dout;
}

[domain("tri")]
cVertexData2 cInkDS(cPatchData2 patch, float3 bary : SV_DomainLocation, const OutputPatch<cCPData, 3> tri)
{
    cVertexData2 dout;

	// Interpolate patch attributes to generated vertices.
    float3 position = BarycentricInterpolate(tri[0].Position, tri[1].Position, tri[2].Position, bary);

#if 1
    // BEGIN Phong Tessellation
    // Orthogonal projection in the tangent planes
    float3 posProjectedU = ProjectOntoPlane(patch.Normal[0], tri[0].Position, position);
    float3 posProjectedV = ProjectOntoPlane(patch.Normal[1], tri[1].Position, position);
    float3 posProjectedW = ProjectOntoPlane(patch.Normal[2], tri[2].Position, position);

    // Interpolate the projected points
    position = lerp(position, BarycentricInterpolate(posProjectedU, posProjectedV, posProjectedW, bary), 0.5);
    // END Phong Tessellation
#endif
    
    // Interpolate array of normals
    float3 normal = BarycentricInterpolate(patch.Normal, bary);

	position += normalize(normal) * Thickness;

    // Transform world position to view-projection
	dout.Position = mul(float4(position, 1), vp);

    return dout;
}

[domain("tri")]
cVertexData2 cBackInkDS(cPatchData2 patch, float3 bary : SV_DomainLocation, const OutputPatch<cCPData, 3> tri)
{
    cVertexData2 dout;

	// Interpolate patch attributes to generated vertices.
    float3 position = BarycentricInterpolate(tri[0].Position, tri[1].Position, tri[2].Position, bary);

#if 1
    // BEGIN Phong Tessellation
    // Orthogonal projection in the tangent planes
    float3 posProjectedU = ProjectOntoPlane(patch.Normal[0], tri[0].Position, position);
    float3 posProjectedV = ProjectOntoPlane(patch.Normal[1], tri[1].Position, position);
    float3 posProjectedW = ProjectOntoPlane(patch.Normal[2], tri[2].Position, position);

    // Interpolate the projected points
    position = lerp(position, BarycentricInterpolate(posProjectedU, posProjectedV, posProjectedW, bary), 0.5);
    // END Phong Tessellation
#endif
    
    // Interpolate array of normals
    float3 normal = BarycentricInterpolate(patch.Normal, bary);

	position -= normalize(normal) * Thickness;

    // Transform world position to view-projection
	dout.Position = mul(float4(position, 1), vp);

    return dout;
}

// pixel shader

inline	float	calc_hdotn( float3 normal )
{
	float3	viewnor	=	mul( normal, (float3x3)view );  //カメラ空間での法線
	float3	viewlight		=	mul( LightDirForced.xyz, (float3x3)view );  //カメラ空間での光線
	const float3	eyedir		=	{0, 0, -1};
	float3	halfvec		=	normalize( eyedir + viewlight );
	return	dot( viewnor, -halfvec );
}

// (default)
// on InkState: alpha func ge
float4 cInkPS( cVertexData2 IN ) : SV_TARGET
{
	float alpha = PenColor.a;
	clip( alpha - ReferenceAlpha ); // alpha test

	return PenColor;
}

// (default)
// on DefaultState: alpha func ge
float4 cMainPS( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );

	float	ldotn		=	dot( normal, -LightDirForced.xyz );
	float	hdotn		=	calc_hdotn( normal );

	float	lp		 = saturate( ( ldotn * 0.6   ) + ( Ambient   * 0.01 ) );
	float	hp0		 = saturate( ( hdotn * 0.708 ) + ( HighLight * 0.01 ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.5 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	float alpha = texcol.a;
	clip( alpha - ReferenceAlpha ); // alpha test
	col.a = alpha;
	return col;
}

// HOHO
// on NatState: alpha func always
float4 cHohoPS( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );

	float	ldotn		=	dot( normal, -LightDirForced.xyz );
	float	hdotn		=	calc_hdotn( normal );

	float	lp		 = saturate( ( ldotn * 0.5   ) + ( Ambient   * 0.01 ) );
	float	hp0		 = saturate( ( hdotn * 0.708 ) + ( HighLight * 0.01 ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.5 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	float alpha = texcol.a * HohoAlpha;
	//clip( alpha - ReferenceAlpha ); // alpha test
	col.a = alpha;
	return col;
}

// AllAmb_
// on DefaultState: alpha func ge
float4 cMainPS3( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );

	float	ldotn		=	dot( normal, -LightDirForced.xyz );
	float	hdotn		=	calc_hdotn( normal );

	float	lp		 = saturate( ( ldotn * 0.5   ) + ( Ambient   * 0.01 ) );
	float	hp0		 = saturate( ( hdotn * 0.708 ) + ( HighLight * 0.01 ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	float alpha = texcol.a;
	clip( alpha - ReferenceAlpha ); // alpha test
	col.a = alpha;
	return col;
}

// _BHL
// on NatState: alpha func always
float4 cBHLMainPS( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );

	float	ldotn		=	dot( normal, -LightDirForced.xyz );
	//float	hdotn		=	calc_hdotn( normal );

	float	lp		 = saturate( ( ldotn * 0.5   ) + ( Ambient   * 0.01 ) );
	//float	hp0		 = saturate( ( hdotn * 0.708 ) + ( HighLight * 0.01 ) );
	//float	hp		 = pow( hp0, HighLightPower );

	float3 viewnor	= mul( normal, (float3x3)view );

	const float3	eyedir_opp		=	{ 0, 0, +1 };
	float	ldotn2		 = dot( viewnor, eyedir_opp );
	float	lp2		 = saturate( ( ldotn2 * 0.5   ) + ( Ambient   * 0.01 ) );
	//float	hp02	 = saturate( ( hdotn2 * 0.708 ) + ( HighLight * 0.01 ) );
	//float	hp2		 = pow( hp02, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.9 ) );
	float4	BHLcol = ShadeTex_texture.Sample( ShadeTex, float2( lp2, 0.9 ) );
	//float4	hl2		 = float4( hp2, hp2, hp2, 1.0 );

	return float4( shadecol.rgb, BHLcol.a );
}

// WASHOUT
// on NatState: alpha func always
float4 cMainWashOut( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );
	float3 viewnor	= mul( normal, (float3x3)view );

	float	ldotn		=	dot( viewnor, -LightDirForced.xyz ); // ! normal

	float	lp		 = saturate( ( ldotn * 0.5   ) + ( Ambient   * 0.01 ) );
	float	hp0		 = saturate( ( ldotn * 0.708 ) + ( HighLight * 0.01 ) ); // ! hdotn
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		=	float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	return float4( col.rgb, shadecol.a );
}

inline	float	calc_eyedotn( float3 normal )
{
	float3 viewnor = mul( normal, (float3x3)view );
	const float3 eyedir = { 0, 0, -1 };
	return max( 0.01, dot( viewnor, -eyedir ) );
}

// _eyedotn
// on DefaultState: alpha func ge
float4 cMainPS_eyedotn( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );

	float	ldotn		=	dot( normal, -LightDirForced.xyz );
	float	hdotn		=	calc_hdotn( normal );

	float	lp		 = saturate( ( ldotn * 0.6   ) + ( Ambient   * 0.01 ) );
	float	hp0		 = saturate( ( hdotn * 0.708 ) + ( HighLight * 0.01 ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.5 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	float	eyedotn		=	calc_eyedotn( normal );
	float	thickness	=	1.0 / eyedotn;
	float	alpha		=	1.0 - pow( abs( 1.0 - texcol.a ) , thickness );

	clip( alpha - ReferenceAlpha ); // alpha test
	col.a = alpha;
	return col;
}

// AllAmb_ _eyedotn
// on DefaultState: alpha func ge
float4 cMainPS3_eyedotn( cVertexData IN ) : SV_TARGET
{
	float3 normal = normalize( IN.Normal );

	float	ldotn		=	dot( normal, -LightDirForced.xyz );
	float	hdotn		=	calc_hdotn( normal );

	float	lp		 = saturate( ( ldotn * 0.5   ) + ( Ambient   * 0.01 ) );
	float	hp0		 = saturate( ( hdotn * 0.708 ) + ( HighLight * 0.01 ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	float	eyedotn		=	calc_eyedotn( normal );
	float	thickness	=	1.0 / eyedotn;
	float	alpha		=	1.0 - pow( abs( 1.0 - texcol.a ) , thickness );

	clip( alpha - ReferenceAlpha ); // alpha test
	col.a = alpha;
	return col;
}

#include "hlmap.fx"

// blend

BlendState KazanState
{
	BlendEnable[0] = TRUE;

	SrcBlend[0] = SRC_ALPHA;
	DestBlend[0] = ONE;
	BlendOp[0] = ADD;

	SrcBlendAlpha[0] = ONE;
	DestBlendAlpha[0] = ZERO;
	BlendOpAlpha[0] = ADD;
};

BlendState NoBlendState
{
	BlendEnable[0] = FALSE;
};

// depth stencil

DepthStencilState NoDepthState
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
	DepthFunc = LESS_EQUAL;

	StencilEnable = FALSE;
};

DepthStencilState NoDepthWriteState
{
	DepthEnable = TRUE;
	DepthWriteMask = ZERO;
	DepthFunc = LESS_EQUAL;

	StencilEnable = FALSE;
};

// rasterizer

RasterizerState NoCullingState
{
	CullMode = none;
};

RasterizerState CcwState
{
	FrontCounterClockwise = true;
};

// techniques

technique11 NAT_ShadowOff
{
#include "ink-pass.fx"
#include "nat-pass.fx"
}

technique11 ShadowOff
{
#include "ink-pass.fx"
#include "default-pass.fx"
}

technique11 NAT_ShadowOff_InkOff
{
#include "nat-pass.fx"
}

technique11 ShadowOff_InkOff
{
#include "default-pass.fx"
}

technique11 HOHO
{
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cHohoPS() ));
	}
}

technique11 NZ_ShadowOff
{
#include "ink-pass.fx"
#include "nzw-pass.fx"
}

technique11 NZ_ShadowOff_InkOff
{
#include "nzw-pass.fx"
}

technique11 NZAT_ShadowOff_InkOff
{
	pass Main
	< float ReferenceAlpha = 0.0; >
	{
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 NCZAT_ShadowOff_InkOff
{
	pass Main
	< float ReferenceAlpha = 0.0; >
	{
		SetDepthStencilState( NoDepthWriteState, 0 );
		SetRasterizerState( NoCullingState );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 KAZAN
{
	pass Main
	< float ReferenceAlpha = 0.0; >
	{
		SetBlendState( KazanState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 AURORA
{
	pass Main
	< float ReferenceAlpha = 0.0; >
	{
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_UVSCR() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 WASHOUT
{
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainWashOut() ));
	}
}

technique11 BothSide
{
#include "backink-pass.fx"
#include "ink-pass.fx"
#include "counter-pass.fx"
#include "default-pass.fx"
}

technique11 BothSide_InkOff
{
#include "counter-pass.fx"
#include "default-pass.fx"
}

technique11 AllAmb_BothSide
{
#include "backink-pass.fx"
#include "ink-pass.fx"
#include "counter-amb-pass.fx"
#include "amb-pass.fx"
}

technique11 AllAmb_BothSide_InkOff
{
#include "counter-amb-pass.fx"
#include "amb-pass.fx"
}

technique11 NAT_AllAmb_ShadowOff
{
#include "ink-pass.fx"
#include "nat-amb-pass.fx"
}

technique11 NAT_AllAmb_ShadowOff_InkOff
{
#include "nat-amb-pass.fx"
}

technique11 AllAmb_ShadowOff
{
#include "ink-pass.fx"
#include "amb-pass.fx"
}

technique11 AllAmb_ShadowOff_InkOff
{
#include "amb-pass.fx"
}

technique11 NAT_ShadowOff_BL
{
#include "ink-pass.fx"
#include "nat-pass.fx"
#include "hlmap-pass.fx"
}

technique11 NAT_ShadowOff_InkOff_BL
{
#include "nat-pass.fx"
#include "hlmap-pass.fx"
}

technique11 ShadowOff_BL
{
#include "ink-pass.fx"
#include "default-pass.fx"
#include "hlmap-pass.fx"
}

technique11 ShadowOff_InkOff_BL
{
#include "default-pass.fx"
#include "hlmap-pass.fx"
}

technique11 NAT_AllAmb_ShadowOff_BL
{
#include "ink-pass.fx"
#include "nat-amb-pass.fx"
#include "hlmap-pass.fx"
}

technique11 NAT_AllAmb_ShadowOff_InkOff_BL
{
#include "nat-amb-pass.fx"
#include "hlmap-pass.fx"
}

technique11 AllAmb_ShadowOff_BL
{
#include "ink-pass.fx"
#include "amb-pass.fx"
#include "hlmap-pass.fx"
}

technique11 AllAmb_ShadowOff_InkOff_BL
{
#include "amb-pass.fx"
#include "hlmap-pass.fx"
}

technique11 NAT_AllAmb_ShadowOff_BHL
{
#include "ink-pass.fx"
#include "nat-amb-pass.fx"
#include "bhl-pass.fx"
}

technique11 NAT_AllAmb_ShadowOff_InkOff_BHL
{
#include "nat-amb-pass.fx"
#include "bhl-pass.fx"
}

technique11 AllAmb_ShadowOff_BHL
{
#include "ink-pass.fx"
#include "amb-pass.fx"
#include "bhl-pass.fx"
}

technique11 AllAmb_ShadowOff_InkOff_BHL
{
#include "amb-pass.fx"
#include "bhl-pass.fx"
}

technique11 ShadowOff_Front
{
#include "ink-pass.fx"
	pass Main
	{
		SetDepthStencilState( NoDepthState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 ShadowOff_InkOff_Front
{
	pass Main
	{
		SetDepthStencilState( NoDepthState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 ShadowOn_eyedotn
{
#include "ink-pass.fx"
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS_eyedotn() ));
	}
}

technique11 AllAmb_ShadowOn_eyedotn
{
#include "ink-pass.fx"
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS3_eyedotn() ));
	}
}
