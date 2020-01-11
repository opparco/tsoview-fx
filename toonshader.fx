// macros

#define PROFILE_VS vs_5_0
#define PROFILE_PS ps_5_0

// variables

uniform matrix	wld			: World;
uniform	matrix	wv			: WorldView;
uniform matrix	wvp			: WorldViewProjection;
uniform matrix	view			: View;
uniform matrix	proj			: Projection;

const uniform matrix	LocalBoneMats[16];

cbuffer cb
{
	float Ambient;
	float Thickness;
	float ColorBlend;
	float ShadeBlend;

	float HighLight;
	float HighLightBlend;
	float HighLightPower;
	float UVScroll;

	float FrontLightPower;
	float BackLightPower;
	float UVScrollX;
	float UVScrollY;

	float4 PenColor;
	//float4 ShadowColor;
	//float4 ManColor;

	float4 FrontLight;
	float4 BackLight;
};

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

struct cVertexData
{
	float4	Position	: SV_POSITION;
	float2	UV			: TEXCOORD0;
	float4	Normal		: TEXCOORD1;
};

struct cVertexData2
{
	float4	Position	: SV_POSITION;
};

// functions

void calc_skindeform( float3 position, float3 normal, float4 weights, int4 idxs, out float3 outpos, out float3 outnor )
{
	float4 ipos		=	float4( position, 1 );
	float4 inor		=	float4( normal, 0 );

	float4x4 mat = LocalBoneMats[idxs.x] * weights.x +
		LocalBoneMats[idxs.y] * weights.y +
		LocalBoneMats[idxs.z] * weights.z +
		LocalBoneMats[idxs.w] * weights.w;

	float4 pos		=	mul( ipos, mat );
	float4 nor		=	mul( inor, mat );

	outpos		=	pos.xyz;
	outnor		=	normalize( nor.xyz );
}

// vertex shader

cVertexData cMainVS( appdata IN )
{
	cVertexData OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position	= mul( float4( pos, 1.0f ), wvp );
	OUT.UV		= IN.UV;
	OUT.Normal	= normalize( mul( float4( nor, 0.0f ), wld ) );

	return OUT;
}

cVertexData cMainVS_viewnormal( appdata IN )
{
	cVertexData OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position	= mul( float4( pos, 1.0f ), wvp );
	OUT.UV		= IN.UV;
	OUT.Normal	= normalize( mul( float4( nor, 0.0f ), wv ) );

	return OUT;
}

cVertexData cMainVS_UVSCR( appdata IN )
{
	cVertexData OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position	= mul( float4( pos, 1.0f ), wvp );
	OUT.UV		= IN.UV + UVSCR.xy;
	OUT.Normal	= normalize( mul( float4( nor, 0.0f ), wld ) );

	return OUT;
}

cVertexData2 cInkVS( appdata IN )
{
	cVertexData2 OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	pos = pos + ( normalize( nor ) * Thickness );
	OUT.Position = mul( float4( pos, 1.0f ), wvp );

	return OUT;
}

cVertexData2 cBackInkVS( appdata IN )
{
	cVertexData2 OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	pos = pos + ( normalize( nor ) *-Thickness );
	OUT.Position = mul( float4( pos, 1.0f ), wvp );

	return OUT;
}

cVertexData cMainVS_XScroll( appdata IN )
{
	cVertexData OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position	= mul( float4( pos, 1.0f ), wvp );
	OUT.UV		= IN.UV + UVSCR.xx * float2( UVScroll, 0 );
	OUT.Normal	= normalize( mul( float4( nor, 0.0f ), wld ) );

	return OUT;
}

cVertexData cMainVS_XYScroll( appdata IN )
{
	cVertexData OUT;
	float3 pos, nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position	= mul( float4( pos, 1.0f ), wvp );
	OUT.UV		= IN.UV + UVSCR.xx * float2( UVScrollX, UVScrollY );
	OUT.Normal	= normalize( mul( float4( nor, 0.0f ), wld ) );

	return OUT;
}

// pixel shader

// (default)
// on DefaultState: alpha func ge
float4 cMainPS( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.6   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.5 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 ); // old
	//col += hl * HighLightBlend;

	clip(col.a - 0.25f); // alpha test
	return float4( col.rgb, texcol.a );
}

// NAT_
// on NatState: alpha func always
float4 cMainPSnAT( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.6   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.5 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 ); // old
	//col += hl * HighLightBlend;

	return float4( col.rgb, texcol.a );
}

// AllAmb_
// on DefaultState: alpha func ge
float4 cMainPS3( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.5   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 ); // old
	//col += hl * HighLightBlend;

	clip(col.a - 0.25f); // alpha test
	return float4( col.rgb, texcol.a );
}

// NAT_AllAmb_
// on NatState: alpha func always
float4 cMainPS3nAT( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.5   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 ); // old
	//col += hl * HighLightBlend;

	return float4( col.rgb, texcol.a );
}

// on InkState: alpha func ge
float4 cInkPS( cVertexData2 IN ) : SV_TARGET
{
	clip(PenColor.a - 0.25f); // alpha test
	return PenColor;
}

// _BHL
// on NatState: alpha func always
float4 cBHLMainPS_viewnormal( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.5   ) + ( Ambient   * 0.01 ) ) );
	//float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	//float	hp		 = pow( hp0, HighLightPower );

	float	L2		 = dot( IN.Normal, float4(0,0,1,0) );
	float	lp2		 = min( 1.0, max( 0.0, ( L2 * 0.5   ) + ( Ambient   * 0.01 ) ) );
	//float	hp02		 = min( 1.0, max( 0.0, ( L2 * 0.708 ) + ( HighLight * 0.01 ) ) );
	//float	hp2		 = pow( hp02, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.9 ) );
	float4	BHLcol = ShadeTex_texture.Sample( ShadeTex, float2( lp2, 0.9 ) );
	//float4	hl2		 = float4( hp2, hp2, hp2, 1.0 );

	return float4( shadecol.rgb, BHLcol.a );
}

// WASHOUT
// on NatState: alpha func always
float4 cMainWashOut_viewnormal( cVertexData IN ) : SV_TARGET
{
	float	L		=	dot( IN.Normal, float4(0,0,1,0) );
	float	lp		=	min( 1.0, max( 0.0, ( L * 0.5   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		=	min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		=	pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		=	float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 );

	return float4( col.rgb, shadecol.a );
}

inline	float	calc_eyedotn( float4 normal )
{
	float4	esnormal	=	mul( normal, view );
	float4	eyedir		=	{0, 0, -1, 0};
	return	max( 0.01, dot(esnormal, -eyedir) );
}

// _eyedotn
// on DefaultState: alpha func ge
float4 cMainPS_eyedotn( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.6   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.5 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 ); // old
	//col += hl * HighLightBlend;

	float	eyedotn		=	calc_eyedotn( IN.Normal );
	float	thickness	=	1.0 / eyedotn;
	float	alpha		=	1.0 - pow( abs( 1.0 - texcol.a ) , thickness);

	clip(col.a - 0.25f); // alpha test
	return float4( col.rgb, alpha );
}

// AllAmb_ _eyedotn
// on DefaultState: alpha func ge
float4 cMainPS3_eyedotn( cVertexData IN ) : SV_TARGET
{
	float	L		 = dot( IN.Normal, -LightDirForced );
	float	lp		 = min( 1.0, max( 0.0, ( L * 0.5   ) + ( Ambient   * 0.01 ) ) );
	float	hp0		 = min( 1.0, max( 0.0, ( L * 0.708 ) + ( HighLight * 0.01 ) ) );
	float	hp		 = pow( hp0, HighLightPower );

	float4	shadecol = ShadeTex_texture.Sample( ShadeTex, float2( lp, 0.1 ) );
	float4	texcol   = ColorTex_texture.Sample( ColorTex, IN.UV  );
	float4	hl		 = float4( hp, hp, hp, 1.0 );

	float4	col;
	col = ( texcol * ( ColorBlend * 0.1 ) ) * ( shadecol * ( ShadeBlend * 0.1 ) );
	col += hl * ( HighLightBlend * 0.0025 ); // old
	//col += hl * HighLightBlend;

	float	eyedotn		=	calc_eyedotn( IN.Normal );
	float	thickness	=	1.0 / eyedotn;
	float	alpha		=	1.0 - pow( abs( 1.0 - texcol.a ) , thickness);

	clip(col.a - 0.25f); // alpha test
	return float4( col.rgb, alpha );
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
	CullMode = NONE;
};

RasterizerState CcwState
{
	FrontCounterClockwise = FALSE;
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
	{
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPSnAT() ));
	}
}

technique11 NCZAT_ShadowOff_InkOff
{
	pass Main
	{
		SetDepthStencilState( NoDepthWriteState, 0 );
		SetRasterizerState( NoCullingState );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPSnAT() ));
	}
}

technique11 KAZAN
{
	pass Main
	{
		SetBlendState( KazanState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPSnAT() ));
	}
}

technique11 AURORA
{
	pass Main
	{
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_UVSCR() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPSnAT() ));
	}
}

technique11 WASHOUT
{
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_viewnormal() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainWashOut_viewnormal() ));
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

technique11 SCROLL
{
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_XScroll() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 XYSCROLL
{
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_XYScroll() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 ShadowOff_Front
{
#include "ink-pass.fx"
	pass Main
	{
		SetDepthStencilState( NoDepthState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 ShadowOff_InkOff_Front
{
	pass Main
	{
		SetDepthStencilState( NoDepthState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
}

technique11 ShadowOn_eyedotn
{
#include "ink-pass.fx"
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS_eyedotn() ));
	}
}

technique11 AllAmb_ShadowOn_eyedotn
{
#include "ink-pass.fx"
	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS3_eyedotn() ));
	}
}
