extends "res://addons/gut/test.gd"


func test_load_default_wordlist_has_three_letter_words() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	assert_gt(list.count_for_length(3), 50, "default wordlist should ship at least 50 three-letter words")


func test_load_default_wordlist_has_five_letter_words() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	assert_gt(list.count_for_length(5), 100, "default wordlist should ship at least 100 five-letter words")


func test_missing_file_returns_empty_wordlist() -> void:
	var list: Wordlist = Wordlist.load_from_path("res://does/not/exist.json")
	assert_eq(list.total_words(), 0)


func test_words_of_unknown_length_returns_empty() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	assert_eq(list.words_of_length(99), [])


func test_matches_pattern_fully_constrained() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	var matches: Array = list.matches_pattern("CAT")
	assert_eq(matches, ["CAT"])


func test_matches_pattern_with_wildcards() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	# 3-letter ?A? words from the bundled list — should include at least CAT, BAT, BAR
	var matches: Array = list.matches_pattern(".A.")
	assert_true(matches.size() > 5, "expected many 3-letter words matching .A.")


func test_matches_pattern_all_wildcards_returns_all_of_length() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	var matches: Array = list.matches_pattern("...")
	assert_eq(matches.size(), list.count_for_length(3))


func test_matches_pattern_no_results() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	# No 3-letter word starts with Q and ends with Z in the curated list.
	var matches: Array = list.matches_pattern("Q.Z")
	assert_eq(matches.size(), 0)


func test_all_lengths_sorted() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	var lengths: Array = list.all_lengths()
	for i in range(1, lengths.size()):
		assert_lt(lengths[i - 1], lengths[i], "lengths should be ascending")


func test_words_are_uppercase() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	for word in list.words_of_length(4):
		assert_eq(word, word.to_upper(), "wordlist entries should already be uppercase")


func test_words_have_correct_length_for_bucket() -> void:
	# Defensive: if the JSON has a typo (5-letter word in the "4" bucket), the
	# loader filters it out. Verify all entries in the 4-bucket are length 4.
	var list: Wordlist = Wordlist.load_from_path()
	for word in list.words_of_length(4):
		assert_eq(word.length(), 4)


func test_total_words_is_positive() -> void:
	var list: Wordlist = Wordlist.load_from_path()
	assert_gt(list.total_words(), 500, "bundled wordlist should ship > 500 words total")
