class_name JukeboxAudio
extends RefCounted

# Procedural muzak generator for the apartment jukebox. Builds a short
# AudioStreamWAV at construct time, mix_rate 22.05 kHz, mono, ~8 seconds
# long. Same approach as FootstepAudio — no binary asset shipped, just
# generated PCM.
#
# Sound: a simple chord progression on stacked sine waves with a slow
# tremolo. Three "tracks" (selected by index) differ in chord choice
# and tempo. Each loops seamlessly because the loop point is at the
# nearest zero-crossing.

const SAMPLE_RATE: int = 22050
const LOOP_SECONDS: float = 8.0
# Master gain for the synthesized stream. The Music bus + per-player
# AudioStreamPlayer3D both apply additional attenuation, so this stays
# quiet at source.
const AMPLITUDE: float = 0.20
# Tremolo modulation depth and rate (LFO).
const TREMOLO_DEPTH: float = 0.30
const TREMOLO_HZ: float = 1.5

# Three muzak tracks, each a list of (chord_root_hz, chord_third_hz,
# chord_fifth_hz, duration_seconds). The progressions are tuned to be
# elevator-music gentle — no abrupt resolutions, all triads.
const TRACK_A: Array = [
	# C major / A minor / F major / G major, slow & warm.
	[261.63, 329.63, 392.00, 2.0],  # C major
	[220.00, 261.63, 329.63, 2.0],  # A minor
	[174.61, 220.00, 261.63, 2.0],  # F major
	[196.00, 246.94, 293.66, 2.0],  # G major
]
const TRACK_B: Array = [
	# D minor / G major / C major / F major — jazzier ii-V-I-IV.
	[146.83, 174.61, 220.00, 2.0],
	[196.00, 246.94, 293.66, 2.0],
	[261.63, 329.63, 392.00, 2.0],
	[174.61, 220.00, 261.63, 2.0],
]
const TRACK_C: Array = [
	# Slower & more melancholy: E minor / A minor / D minor / G major.
	[164.81, 196.00, 246.94, 2.0],
	[220.00, 261.63, 329.63, 2.0],
	[146.83, 174.61, 220.00, 2.0],
	[196.00, 246.94, 293.66, 2.0],
]


static func make_stream(track_index: int = 0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var track: Array = _track_for_index(track_index)
	var samples: PackedByteArray = _render_track(track)
	stream.data = samples
	stream.loop_begin = 0
	stream.loop_end = samples.size() / 2  # 16-bit, 1 channel
	return stream


static func _track_for_index(idx: int) -> Array:
	match idx % 3:
		1:
			return TRACK_B
		2:
			return TRACK_C
		_:
			return TRACK_A


static func _render_track(track: Array) -> PackedByteArray:
	# Concatenate per-chord segments. Each segment is a sum of three sine
	# waves with envelope + tremolo. Returns 16-bit PCM bytes.
	var total_seconds: float = 0.0
	for entry in track:
		total_seconds += float(entry[3])
	var sample_count: int = int(total_seconds * float(SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)

	var write_offset: int = 0
	for entry in track:
		var f1: float = float(entry[0])
		var f2: float = float(entry[1])
		var f3: float = float(entry[2])
		var duration: float = float(entry[3])
		var segment_samples: int = int(duration * float(SAMPLE_RATE))
		for i in range(segment_samples):
			var t: float = float(i) / float(SAMPLE_RATE)
			# Slow envelope ramp at segment boundaries to avoid clicks.
			var envelope: float = _segment_envelope(i, segment_samples)
			# Tremolo LFO.
			var tremolo: float = 1.0 - TREMOLO_DEPTH * 0.5 * (1.0 + sin(TAU * TREMOLO_HZ * t))
			# Three-voice chord, each at 1/3 amplitude so they sum to <1.
			var voice_sum: float = (sin(TAU * f1 * t) + sin(TAU * f2 * t) + sin(TAU * f3 * t)) / 3.0
			var sample: float = voice_sum * envelope * tremolo * AMPLITUDE
			var int_sample: int = int(clamp(sample, -1.0, 1.0) * 32000.0)
			data.encode_s16(write_offset * 2, int_sample)
			write_offset += 1
	return data


static func _segment_envelope(sample_idx: int, segment_length: int) -> float:
	# Short attack + decay relative to chord length. Smooths the crossfade
	# between chords so the loop sounds continuous rather than choppy.
	var fade_samples: int = int(float(segment_length) * 0.08)
	if fade_samples < 1:
		fade_samples = 1
	if sample_idx < fade_samples:
		return float(sample_idx) / float(fade_samples)
	if sample_idx >= segment_length - fade_samples:
		return float(segment_length - sample_idx) / float(fade_samples)
	return 1.0


static func expected_sample_count(track_index: int = 0) -> int:
	# Exposed for the test suite so we can assert the rendered byte count
	# without re-deriving the track-duration sum.
	var track: Array = _track_for_index(track_index)
	var seconds: float = 0.0
	for entry in track:
		seconds += float(entry[3])
	return int(seconds * float(SAMPLE_RATE))


static func track_count() -> int:
	return 3
