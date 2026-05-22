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
