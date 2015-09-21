	pass Pass0
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_viewnormal() ));
                SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cBHLMainPS_viewnormal() ));
	}
