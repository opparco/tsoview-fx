	pass Pass0
	{
		SetBlendState( KazanState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cHLMapVSB() ));
#ifdef USE_TESSELLATION
#include "select-hull2.fx"
		SetDomainShader(CompileShader( PROFILE_DS, cHLMapDSB() ));
		SetGeometryShader( NULL );
#endif
		SetPixelShader(CompileShader( PROFILE_PS, cHLMapPS() ));
	}
	pass Pass1
	{
		SetBlendState( KazanState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cHLMapVSF() ));
#ifdef USE_TESSELLATION
#include "select-hull2.fx"
		SetDomainShader(CompileShader( PROFILE_DS, cHLMapDSF() ));
		SetGeometryShader( NULL );
#endif
		SetPixelShader(CompileShader( PROFILE_PS, cHLMapPS() ));
	}
