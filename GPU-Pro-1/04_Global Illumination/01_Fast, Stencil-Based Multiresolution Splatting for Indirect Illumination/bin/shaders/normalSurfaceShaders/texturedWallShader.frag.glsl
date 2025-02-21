#version 120 
#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D       wallTex, spotLight, causticMap0;
uniform sampler2DShadow shadowMap0, causticDepth0;
uniform float			useShadowMap, useCausticMap;

uniform vec4 amb, dif;
uniform float lightIntensity;
uniform vec4 sceneAmbient;

vec4 IsPointIlluminated( vec4 smapCoord )
{
	return ( all(equal(smapCoord.xyz,clamp(smapCoord.xyz,vec3(0),vec3(1)))) ? 
					shadow2D( shadowMap0, smapCoord.xyz ).x * texture2D( spotLight, smapCoord.xy, 0.0 ): 
					vec4(0.0) );
}

vec4 CausticContribution( vec4 smapCoord )
{
	return ( all(equal(smapCoord.xyz,clamp(smapCoord.xyz,vec3(0),vec3(1)))) ? 
					shadow2D( causticDepth0, smapCoord.xyz ).x * texture2D( causticMap0, smapCoord.xy ): 
					vec4(0.0) );
}

void main( void )
{
	vec3 toLight = normalize( gl_LightSource[0].position.xyz - gl_TexCoord[5].xyz );
	vec3 norm = normalize( gl_TexCoord[6].xyz );
	//float NdotL = lightIntensity * max( 0.0, dot( norm, toLight ) );
	float NdotL = lightIntensity * abs( dot( norm, toLight ) );
	vec4 color = texture2D( wallTex, gl_TexCoord[0].xy );
	
	// Compute the shadow map coordinate.  This is wasted if not using shadow/caustic mapping.
	//   However, it's relatively cheap to compute.
	vec4 smapCoord = vec4( dot( gl_EyePlaneS[7], gl_TexCoord[5] ), dot( gl_EyePlaneT[7], gl_TexCoord[5] ),
						   dot( gl_EyePlaneR[7], gl_TexCoord[5] ), dot( gl_EyePlaneQ[7], gl_TexCoord[5] ) );
	smapCoord /= smapCoord.w;
	smapCoord.z = smapCoord.z <= 0.0 ? 0.0 : smapCoord.z;
	
	// Determine if this location is lit (look in shadow map, if using that).
	//    The trailing 0.05 is an ambient term.
	vec4 lit = ( useShadowMap>0 ? IsPointIlluminated( smapCoord )*NdotL : vec4(NdotL) ) + sceneAmbient + amb;
	lit += (useCausticMap>0 ? CausticContribution( smapCoord )*NdotL : vec4( 0.0 ) );
	
	gl_FragColor = lit * color;
	gl_FragColor.a = length( gl_TexCoord[5].xyz );
	
}