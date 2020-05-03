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

#ifdef USE_TESSELLATION
cHSData2
#else
cHLMapData
#endif
cHLMapVSB( appdata IN )
{
#ifdef USE_TESSELLATION
	cHSData2	OUT;
#else
	cHLMapData	OUT;
#endif
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

#ifdef USE_TESSELLATION
	OUT.Position		=	mul( float4( pos, 1 ), wld ).xyz;
	OUT.Normal	= mul( nor, (float3x3)wit );
#else
	OUT.Position		=	mul( float4( pos, 1 ), wvp );

	float4 N		=	normalize( mul(float4(nor.x,-nor.y,nor.z,0), wld) );
	float4 L	=	normalize( mul(float4(nor.xyz,0), wvp) );

	OUT.Color		=	BackLight * ( BackLightPower + dot(N, L)*(1-0.3f) * 2 );
#endif

	return	OUT;
}

#ifdef USE_TESSELLATION
cHSData2
#else
cHLMapData
#endif
cHLMapVSF( appdata IN )
{
#ifdef USE_TESSELLATION
	cHSData2	OUT;
#else
	cHLMapData	OUT;
#endif
	float3	pos;
	float3	nor;

	calc_skindeform( IN.Position, IN.Normal, IN.VWeights, IN.BoneIdxs, pos, nor );

#ifdef USE_TESSELLATION
	OUT.Position		=	mul( float4( pos, 1 ), wld ).xyz;
	OUT.Normal	= mul( nor, (float3x3)wit );
#else
	OUT.Position		=	mul( float4( pos, 1 ), wvp );

	float4	N		=	normalize( mul(float4(nor.x,-nor.y,nor.z,0), wld) );
	float4	L	=	normalize( mul(float4(nor.xyz,0), wvp) );

	OUT.Color		=	FrontLight * ( FrontLightPower  + dot(N, -L)*(1-0.3f)*1.5);
#endif

	return	OUT;
}

// domain shader

// Phong Tessellation Domain Shader
// This domain shader applies control point weighting to the barycentric coords produced by the fixed function tessellator stage
[domain("tri")]
cHLMapData cHLMapDSB(cPatchData2 patch, float3 bary : SV_DomainLocation, const OutputPatch<cCPData, 3> tri)
{
    cHLMapData dout;

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

    // Transform world position to view-projection
	dout.Position = mul(float4(position, 1), vp);

	float4 N		=	normalize( mul(float4(normal.x,-normal.y,normal.z,0), wld) );
	float4 L	=	normalize( mul(float4(normal.xyz,0), wvp) );

	dout.Color		=	BackLight * ( BackLightPower + dot(N, L)*(1-0.3f) * 2 );

    return dout;
}

[domain("tri")]
cHLMapData cHLMapDSF(cPatchData2 patch, float3 bary : SV_DomainLocation, const OutputPatch<cCPData, 3> tri)
{
    cHLMapData dout;

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

    // Transform world position to view-projection
	dout.Position = mul(float4(position, 1), vp);

	float4	N		=	normalize( mul(float4(normal.x,-normal.y,normal.z,0), wld) );
	float4	L	=	normalize( mul(float4(normal.xyz,0), wvp) );

	dout.Color		=	FrontLight * ( FrontLightPower  + dot(N, -L)*(1-0.3f)*1.5);

    return dout;
}

// pixel shader

// on KazanState: alpha func always
float4 cHLMapPS( cHLMapData IN ) : SV_TARGET
{
	return IN.Color;
}
