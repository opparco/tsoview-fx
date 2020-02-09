	pass BackInk
	{
		SetVertexShader(CompileShader( PROFILE_VS, cBackInkVS() ));
#ifdef USE_TESSELLATION
#include "select-hull2.fx"
		SetDomainShader(CompileShader( PROFILE_DS, cBackInkDS() ));
		SetGeometryShader( NULL );
#endif
		SetPixelShader(CompileShader( PROFILE_PS, cInkPS() ));
	}
