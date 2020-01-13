	pass Pass0
	{
		SetVertexShader(CompileShader( PROFILE_VS, cMainVS_viewnormal() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cBHLMainPS_viewnormal() ));
	}
