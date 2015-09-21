	pass Counter
	{
		SetRasterizerState( CcwState );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
                SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS3() ));
	}
