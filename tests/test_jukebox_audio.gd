extends "res://addons/gut/test.gd"


# JukeboxAudio.make_stream is a procedural audio generator. We assert
# structural properties (mix rate, mono, loop mode, byte count matches
# the expected sample count, all three track indices produce distinct
# streams) without committing to specific waveform values.


func test_stream_is_16bit_mono_at_expected_mix_rate() -> void:
	var stream: AudioStreamWAV = JukeboxAudio.make_stream(0)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(stream.mix_rate, JukeboxAudio.SAMPLE_RATE)
	assert_false(stream.stereo)


func test_stream_loops_forward() -> void:
	var stream: AudioStreamWAV = JukeboxAudio.make_stream(0)
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_gt(stream.loop_end, 0)


func test_byte_count_matches_expected_sample_count() -> void:
	# 16-bit mono => 2 bytes per sample. Pin the relationship so a
	# regression that drops half the samples (or doubles them) fires.
	for track_index in range(JukeboxAudio.track_count()):
		var stream: AudioStreamWAV = JukeboxAudio.make_stream(track_index)
		var expected: int = JukeboxAudio.expected_sample_count(track_index)
		assert_eq(stream.data.size(), expected * 2, "Track %d byte count" % track_index)


func test_three_tracks_produce_distinct_streams() -> void:
	# The three chord progressions differ in chord choice; the rendered
	# PCM bytes should differ as a result. Cheap probe: any two streams
	# should differ in their first 1000 bytes.
	var a: PackedByteArray = JukeboxAudio.make_stream(0).data
	var b: PackedByteArray = JukeboxAudio.make_stream(1).data
	var c: PackedByteArray = JukeboxAudio.make_stream(2).data
	assert_ne(a.slice(0, 1000), b.slice(0, 1000))
	assert_ne(b.slice(0, 1000), c.slice(0, 1000))
	assert_ne(a.slice(0, 1000), c.slice(0, 1000))


func test_track_index_wraps_modulo_track_count() -> void:
	# track_index N + 3 should produce the same stream as N — the helper
	# uses idx % 3. Guards against a future expansion accidentally
	# breaking the placement-hash -> track-index mapping.
	var stream_a: AudioStreamWAV = JukeboxAudio.make_stream(0)
	var stream_d: AudioStreamWAV = JukeboxAudio.make_stream(3)
	assert_eq(stream_a.data, stream_d.data)


func test_track_count_is_three() -> void:
	# Pin the public count so the placement hash modulo math stays
	# consistent with the actual variety we ship.
	assert_eq(JukeboxAudio.track_count(), 3)


func test_amplitude_is_quiet_at_source() -> void:
	# Decoded samples should be well within int16 range — sanity check
	# that the per-voice 1/3 amplitude scaling didn't drift past 1.0
	# anywhere in the rendered stream.
	var data: PackedByteArray = JukeboxAudio.make_stream(0).data
	var sample_count: int = data.size() / 2
	for i in range(0, sample_count, 100):  # sample every 100th value for speed
		var value: int = data.decode_s16(i * 2)
		assert_true(value >= -32000 and value <= 32000, "Sample %d out of range: %d" % [i, value])
