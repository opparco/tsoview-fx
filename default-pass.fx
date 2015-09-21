	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
                SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
