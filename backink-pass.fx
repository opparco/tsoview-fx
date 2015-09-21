	pass BackInk
	{
		SetVertexShader(CompileShader( PROFILE_VS, cBackInkVS() ));
                SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cInkPS() ));
	}
