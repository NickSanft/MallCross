class_name TimeOfDayMath
extends RefCounted

# Pure math helpers for the day/night cycle. Time-of-day is a float in
# [0.0, 1.0): 0.0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk.
#
# Keyframes are stored as plain Dictionaries keyed by `time` so the
# interpolation function can accept either a Color list or a float list
# without duplicating math. Keyframes are assumed sorted by `time` and
# to wrap (the entry at the smallest `time` is also treated as living at
# time+1.0 for the wrap segment).


# Advances `current` by `delta_seconds * rate_per_second`, wrapping into
# [0.0, 1.0). Negative deltas are clamped to 0 — time only moves forward
# in this game.
static func advance(current: float, delta_seconds: float, rate_per_second: float) -> float:
	if delta_seconds < 0.0:
		delta_seconds = 0.0
	var next: float = current + delta_seconds * rate_per_second
	# fposmod handles the [0.0, 1.0) wrap correctly for any positive value.
	return fposmod(next, 1.0)


# Snaps to a specific time (used by the sleep jump). Wraps into [0.0, 1.0).
static func snap_to(target: float) -> float:
	return fposmod(target, 1.0)


# Interpolates Color values across keyframes. Each keyframe is a
# {"time": float, "color": Color} dict. Returns the lerped color at `t`.
# Keyframes are treated as cyclic — interpolating past the last entry
# wraps around to the first at time+1.0. Returns Color.BLACK for empty
# keyframe lists (defensive; UI should never call this with empty).
static func interpolate_color(t: float, keyframes: Array) -> Color:
	if keyframes.is_empty():
		return Color.BLACK
	t = fposmod(t, 1.0)
	var prev: Dictionary = _wrapping_prev(t, keyframes)
	var next: Dictionary = _wrapping_next(t, keyframes)
	var alpha: float = _segment_alpha(t, prev["time"], next["time"])
	return (prev["color"] as Color).lerp(next["color"] as Color, alpha)


# Same as interpolate_color but for a scalar `value` field.
static func interpolate_float(t: float, keyframes: Array) -> float:
	if keyframes.is_empty():
		return 0.0
	t = fposmod(t, 1.0)
	var prev: Dictionary = _wrapping_prev(t, keyframes)
	var next: Dictionary = _wrapping_next(t, keyframes)
	var alpha: float = _segment_alpha(t, prev["time"], next["time"])
	return lerp(float(prev["value"]), float(next["value"]), alpha)


# True when `t` is between dusk (0.75) and dawn (0.25), accounting for the
# midnight wrap. Used to gate lamp activation.
static func is_night(t: float, dusk: float = 0.75, dawn: float = 0.25) -> bool:
	t = fposmod(t, 1.0)
	if dawn < dusk:
		return t >= dusk or t < dawn
	# Inverted thresholds — defensive fallback for tests with reversed args.
	return t >= dusk and t < dawn


# Returns the keyframe with the largest `time` <= `t`. If `t` is before
# the first keyframe, wraps to the last (treating it as living at
# time-1.0). Keyframes must be sorted by time.
static func _wrapping_prev(t: float, keyframes: Array) -> Dictionary:
	var best: Dictionary = keyframes[keyframes.size() - 1]
	for entry in keyframes:
		if float(entry["time"]) <= t:
			best = entry
		else:
			break
	return best


# Returns the keyframe with the smallest `time` > `t`. If `t` is past
# the last keyframe, wraps to the first (treating it as living at
# time+1.0).
static func _wrapping_next(t: float, keyframes: Array) -> Dictionary:
	for entry in keyframes:
		if float(entry["time"]) > t:
			return entry
	return keyframes[0]


# Returns the lerp alpha for `t` between `prev_time` and `next_time`,
# treating next < prev as a wrap segment crossing midnight.
static func _segment_alpha(t: float, prev_time: float, next_time: float) -> float:
	var span: float = next_time - prev_time
	if span <= 0.0:
		# Wrap segment — span goes across midnight.
		span += 1.0
		var distance: float = t - prev_time
		if distance < 0.0:
			distance += 1.0
		return clamp(distance / span, 0.0, 1.0)
	return clamp((t - prev_time) / span, 0.0, 1.0)
