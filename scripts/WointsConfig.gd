class_name WointsConfig
extends RefCounted

# Per-difficulty Woints rewards. Phase 5 only wires MINI (paying 50). MIDI
# and FULL values are declared so the rates are committed once and the
# Phase 7 puzzle pack drops in without revisiting balance.

const REWARD_MINI: int = 50
const REWARD_MIDI: int = 120
const REWARD_FULL: int = 300
const REWARD_DEFAULT: int = 25

# Streak bonus = (streak - 1) * STREAK_BONUS_PER_DAY. Day 1 of a streak earns
# nothing extra; day 2 = +5; day 3 = +10; ...
const STREAK_BONUS_PER_DAY: int = 5


static func reward_for_difficulty(label: String) -> int:
	match label.to_upper():
		"MINI":
			return REWARD_MINI
		"MIDI":
			return REWARD_MIDI
		"FULL":
			return REWARD_FULL
		_:
			return REWARD_DEFAULT


static func streak_bonus(streak: int) -> int:
	# Streak is the *new* streak length after the solve. Returns the extra
	# Woints granted on top of the base reward.
	return max(0, (streak - 1)) * STREAK_BONUS_PER_DAY
