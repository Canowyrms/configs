//!PARAM vibr
//!DESC Saturates/deSaturates
//!TYPE float
//!MINIMUM -1
-0.1

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Vibrance

#define CoefLuma vec4(0.2126, 0.7152, 0.0722, 0) //sRGB, HDTV
float Thresh = 30.0/255.0;
float w = 30.0/255.0;

vec4 hook() {
	vec4 c0 = HOOKED_texOff(0);
	float lum = (c0.r + c0.g + c0.b)/3.0;

	// Calculate the saturation of the color
    float maxColor = max(max(c0.r, c0.g), c0.b);
    float minColor = min(min(c0.r, c0.g), c0.b);
    float colorSat = (maxColor - minColor) / max(maxColor, 1e-5); // Prevent division by zero
	// colorSat = min(colorSat, 0.9);
	// vec3 sat = mix(vec3(dot(c0, CoefLuma)), c0.rgb, 1+vibr - colorSat*abs(vibr));
	vec3 sat = mix(vec3(dot(c0, CoefLuma)), c0.rgb, clamp(1+vibr - colorSat*abs(vibr), 0.0, 1.0));
	float delta = smoothstep(Thresh-w, Thresh+w, lum);
	sat = mix(sat, c0.rgb, delta);
	delta = smoothstep(0.9, 0.99, colorSat);
	c0.rgb = mix(c0.rgb, sat, delta);
	return c0;
}