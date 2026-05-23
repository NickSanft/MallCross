shader_type spatial;
// `skip_vertex_transform` lets us do the matrix math ourselves so we can
// snap clip-space xy *before* Godot's per-pixel rasterization. Without it
// Godot's default transform would run after our vertex() and overwrite
// POSITION.
// `vertex_lighting` switches lighting from per-pixel to per-vertex —
// authentic PS1/N64 look, plus the omni lights in the mall corridor still
// cast shaded variation across each face.
render_mode skip_vertex_transform, vertex_lighting;

// Solid color for the surface. Per-box materials override this from
// MallGreybox._make_box.
uniform vec3 albedo : source_color = vec3(0.8, 0.8, 0.8);

// Higher = finer grid (less wobble). 320 ≈ 1px on a 640-wide internal
// resolution. 100 gives a noticeable PS1 jitter without making nearby
// geometry look broken.
uniform float vertex_snap : hint_range(20.0, 400.0) = 100.0;


void vertex() {
	vec4 model_vertex = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec4 view_vertex = VIEW_MATRIX * model_vertex;
	vec4 clip_vertex = PROJECTION_MATRIX * view_vertex;

	// Snap xy in NDC space (after perspective divide). Skip degenerate
	// vertices behind the near plane to avoid divide-by-zero artifacts.
	if (clip_vertex.w > 0.0) {
		clip_vertex.xy /= clip_vertex.w;
		clip_vertex.xy = round(clip_vertex.xy * vertex_snap) / vertex_snap;
		clip_vertex.xy *= clip_vertex.w;
	}

	POSITION = clip_vertex;
}


void fragment() {
	ALBEDO = albedo;
}
