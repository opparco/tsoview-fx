	pass Counter
	< float LP1 = 0.5; >
	{
		SetRasterizerState( CcwState );

		SetVertexShader(CompileShader( PROFILE_VS, cMainVS() ));
#include "tessellation.fx"
		SetPixelShader(CompileShader( PROFILE_PS, cMainPS() ));
	}
