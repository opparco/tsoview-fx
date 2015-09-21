// _BL

// variables

/* move to cbuffer cb */

// structs

struct cHLMapData
{
	float4	Position	:	SV_POSITION;
	float4	Color		:	COLOR0;
};

// functions

// vertex shader

cHLMapData	cHLMapVSB( appdata IN )
{
	cHLMapData	OUT;
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position		=	mul( float4( pos, 1.0f ), wvp );

	float4 N		=	normalize( mul(float4(nor.x,-nor.y,nor.z,0), wld) );
	float4 LightDirect	=	normalize( mul(float4(nor.x,+nor.y,nor.z,0), wvp) );

	OUT.Color		=	BackLight * ( BackLightPower + dot(N, LightDirect)*(1-0.3f) * 2 );

	return	OUT;
}

cHLMapData	cHLMapVSF( appdata IN )
{
	cHLMapData	OUT;
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

	OUT.Position		=	mul( float4( pos, 1.0f ), wvp );

	float4	N		=	normalize( mul(float4(nor.x,-nor.y,nor.z,0), wld) );
	float4	LightDirect	=	normalize( mul(float4(nor.x,+nor.y,nor.z,0), wvp) );

	OUT.Color		=	FrontLight * ( FrontLightPower  + dot(N, -LightDirect)*(1-0.3f)*1.5);

	return	OUT;
}

// pixel shader

// on KazanState: alpha func always
float4 cHLMapPS( cHLMapData IN ) : SV_TARGET
{
	return IN.Color;
}
