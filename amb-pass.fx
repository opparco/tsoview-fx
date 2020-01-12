	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
		SetHullShader(CompileShader( PROFILE_HS, cMainHS() ));
		SetDomainShader(CompileShader( PROFILE_DS, cMainDS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS3() ));
	}
