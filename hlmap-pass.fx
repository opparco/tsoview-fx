	pass Pass0
	{
		SetBlendState( KazanState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		//SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cHLMapVSB() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cHLMapPS() ));
	}
	pass Pass1
	{
		SetBlendState( KazanState, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		//SetDepthStencilState( NoDepthWriteState, 0 );

		SetVertexShader(CompileShader( PROFILE_VS, cHLMapVSF() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cHLMapPS() ));
	}
