extends "res://addons/gut/test.gd"


func test_reward_for_mini() -> void:
	assert_eq(WointsConfig.reward_for_difficulty("MINI"), WointsConfig.REWARD_MINI)


func test_reward_for_midi() -> void:
	assert_eq(WointsConfig.reward_for_difficulty("MIDI"), WointsConfig.REWARD_MIDI)


func test_reward_for_full() -> void:
	assert_eq(WointsConfig.reward_for_difficulty("FULL"), WointsConfig.REWARD_FULL)


func test_reward_is_case_insensitive() -> void:
	assert_eq(WointsConfig.reward_for_difficulty("mini"), WointsConfig.REWARD_MINI)
	assert_eq(WointsConfig.reward_for_difficulty("Midi"), WointsConfig.REWARD_MIDI)


func test_reward_unknown_label_defaults() -> void:
	assert_eq(WointsConfig.reward_for_difficulty("EXPERT"), WointsConfig.REWARD_DEFAULT)
	assert_eq(WointsConfig.reward_for_difficulty(""), WointsConfig.REWARD_DEFAULT)


func test_reward_tiers_scale_with_difficulty() -> void:
	assert_lt(WointsConfig.REWARD_MINI, WointsConfig.REWARD_MIDI)
	assert_lt(WointsConfig.REWARD_MIDI, WointsConfig.REWARD_FULL)


# ---- streak bonus ----


func test_streak_bonus_zero_for_streak_of_one() -> void:
	# Day 1 of a streak earns no bonus — just the base reward.
	assert_eq(WointsConfig.streak_bonus(1), 0)


func test_streak_bonus_for_streak_of_two() -> void:
	assert_eq(WointsConfig.streak_bonus(2), WointsConfig.STREAK_BONUS_PER_DAY)


func test_streak_bonus_scales_linearly() -> void:
	# Bonus = (streak - 1) * STREAK_BONUS_PER_DAY.
	assert_eq(WointsConfig.streak_bonus(5), 4 * WointsConfig.STREAK_BONUS_PER_DAY)


func test_streak_bonus_zero_for_invalid_inputs() -> void:
	assert_eq(WointsConfig.streak_bonus(0), 0)
	assert_eq(WointsConfig.streak_bonus(-3), 0)
