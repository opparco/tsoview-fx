	pass Main
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPSnAT() ));
	}
