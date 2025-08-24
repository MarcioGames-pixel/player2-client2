shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tint : hint_color;
uniform bool studs_enabled = false;
uniform bool shirt_enabled = false;
uniform bool pants_enabled = false;
uniform sampler2D studs : hint_albedo;
uniform sampler2D shirt : hint_albedo;
uniform sampler2D pants : hint_albedo;

void fragment() {
	vec4 final = tint;
	if (studs_enabled) {
		vec4 studs_tex = texture(studs, UV);
		final.rgb = mix(final.rgb, studs_tex.rgb, studs_tex.a);
	}
	if (pants_enabled) {
		vec4 pants_tex = texture(pants, UV);
		final.rgb = mix(final.rgb, pants_tex.rgb, pants_tex.a);
	}
	if (shirt_enabled) {
		vec4 shirt_tex = texture(shirt, UV);
		final.rgb = mix(final.rgb, shirt_tex.rgb, shirt_tex.a);
	}
	ALBEDO = final.rgb;
}
