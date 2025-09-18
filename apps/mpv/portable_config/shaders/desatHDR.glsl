//!PARAM Strength
//!DESC Desat Strength
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.3

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Desaturation smooth 


#define Thresh 3/255.
#define w 2/255.
#define CoefLuma vec4(0.2126, 0.7152, 0.0722, 0) //sRGB, HDTV

/* simple threshold with mpv glsl 
Strength*desaturation [0 to1.0], 0: full color, 1: grayscale.
*/

vec4 hook()  {
   vec4 c0 = HOOKED_texOff(0);
   float desaturation = smoothstep(Thresh + w, Thresh - w, dot(c0, CoefLuma));
   // return vec4(desaturation, 1);
   c0.rgb = mix(c0.rgb, vec3(dot(c0, CoefLuma)), Strength*desaturation);

   return c0;
}