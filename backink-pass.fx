	pass BackInk
	{
		SetVertexShader(CompileShader( PROFILE_VS, cBackInkVS() ));
#include "select-hull.fx"
		SetDomainShader(CompileShader( PROFILE_DS, cBackInkDS() ));
		SetGeometryShader( NULL );
		SetPixelShader(CompileShader( PROFILE_PS, cInkPS() ));
	}
