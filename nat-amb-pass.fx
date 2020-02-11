	pass Main
	< float ReferenceAlpha = 0.0; >
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS3() ));
	}
