extends "res://addons/gut/test.gd"


func test_make_footstep_stream_returns_non_null() -> void:
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	assert_not_null(stream)


func test_footstep_stream_format_is_16_bit() -> void:
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)


func test_footstep_stream_mix_rate_matches_constant() -> void:
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	assert_eq(stream.mix_rate, FootstepAudio.SAMPLE_RATE)


func test_footstep_stream_is_mono() -> void:
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	assert_false(stream.stereo)


func test_footstep_data_length_matches_expected() -> void:
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	assert_eq(stream.data.size(), FootstepAudio.expected_byte_size())


func test_footstep_data_is_not_silent() -> void:
	# Sample partway through the envelope and check we wrote something audible.
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	var data: PackedByteArray = stream.data
	# Look at a sample near the start where the envelope hasn't decayed much.
	var sample_at_offset_5: int = data.decode_s16(10)  # sample index 5 → byte 10
	# Synthesizer uses a fixed seed (42) so this is deterministic; if it's
	# exactly zero something's broken in the noise/envelope pipeline.
	assert_ne(sample_at_offset_5, 0)


func test_footstep_envelope_decays_toward_end() -> void:
	# Last sample should be much smaller in absolute value than an early sample
	# because the exponential envelope decays over 60 ms.
	var stream: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	var data: PackedByteArray = stream.data
	var first_sample: int = absi(data.decode_s16(20))   # ~early-ish
	var last_sample: int = absi(data.decode_s16(data.size() - 2))
	assert_lt(last_sample, first_sample)


func test_expected_sample_count_matches_duration() -> void:
	# DURATION_SEC * SAMPLE_RATE = 0.06 * 22050 = 1323 samples.
	assert_eq(FootstepAudio.expected_sample_count(), 1323)


func test_footstep_stream_is_deterministic() -> void:
	# Same seed -> identical output. Two calls should produce equal PCM data.
	var a: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	var b: AudioStreamWAV = FootstepAudio.make_footstep_stream()
	assert_eq(a.data, b.data)
