	pass Ink
	{
		SetBlendState( NoBlendState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetRasterizerState( CcwState );

		SetVertexShader(CompileShader( PROFILE_VS, cInkVS() ));
#ifdef USE_TESSELLATION
#include "select-hull.fx"
		SetDomainShader(CompileShader( PROFILE_DS, cInkDS() ));
		SetGeometryShader( NULL );
#endif
		SetPixelShader(CompileShader( PROFILE_PS, cInkPS() ));
	}
