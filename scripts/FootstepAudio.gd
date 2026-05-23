class_name FootstepAudio
extends RefCounted

# Procedurally generates a short footstep "thump" as an AudioStreamWAV at
# startup. No binary audio asset shipped — the entire sound is ~2.6 KB of
# computed PCM data. Tuned for the PS1/N64 vibe: 22.05 kHz mix rate, ~60 ms
# decay, low-passed white noise so it lands as a soft thud rather than a
# bright click.

const SAMPLE_RATE: int = 22050
const DURATION_SEC: float = 0.06
const ENVELOPE_DECAY: float = 40.0
# Single-pole IIR coefficient. Higher = stronger low-pass = bassier thud.
const LOWPASS_ALPHA: float = 0.78
const AMPLITUDE: float = 0.5
const NOISE_SEED: int = 42


static func make_footstep_stream() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false

	var sample_count: int = expected_sample_count()
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)  # 2 bytes per 16-bit sample

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = NOISE_SEED

	var prev: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-t * ENVELOPE_DECAY)
		var noise: float = rng.randf_range(-1.0, 1.0)
		prev = prev * LOWPASS_ALPHA + noise * (1.0 - LOWPASS_ALPHA)
		var sample: float = prev * envelope * AMPLITUDE
		var int_sample: int = int(clamp(sample, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	return stream


static func expected_sample_count() -> int:
	return int(DURATION_SEC * float(SAMPLE_RATE))


static func expected_byte_size() -> int:
	return expected_sample_count() * 2
