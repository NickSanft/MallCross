class_name Wordlist
extends RefCounted

# Loads a JSON wordlist organized by word length:
#   {"3": ["CAT", "DOG", ...], "4": [...], ...}
# Provides length-indexed access for the puzzle generator + pattern matching.

const DEFAULT_PATH: String = "res://data/wordlists/common_words.json"

var _by_length: Dictionary = {}  # int -> Array[String] (uppercase)
var _word_set: Dictionary = {}  # word -> true, for O(1) membership tests
# Inverted letter index: for each length, for each (position, letter) pair,
# the set of words that have that letter at that position (as a Dictionary
# acting as a set: word -> true). Used by matches_pattern / has_match to
# narrow candidates massively when several positions are constrained —
# essential for the PuzzleGenerator's forward-check pass. Built once at
# load time; ~O(N × L) memory where N is total words and L is max length.
var _letter_index: Dictionary = {}  # length -> "{pos}_{letter}" -> Dictionary[String, bool]


static func load_from_path(path: String = DEFAULT_PATH) -> Wordlist:
	var list: Wordlist = Wordlist.new()
	if not FileAccess.file_exists(path):
		return list
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		return list
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return list
	for key in parsed:
		var length: int = int(String(key))
		if length <= 0:
			continue
		var raw: Variant = parsed[key]
		if not (raw is Array):
			continue
		var words: Array = []
		var per_length_index: Dictionary = {}
		for word_variant in raw:
			var word: String = String(word_variant).to_upper()
			if word.length() == length and _is_alpha(word):
				words.append(word)
				list._word_set[word] = true
				for pos in range(length):
					var idx_key: String = str(pos) + "_" + word[pos]
					if not per_length_index.has(idx_key):
						per_length_index[idx_key] = {}
					per_length_index[idx_key][word] = true
		list._by_length[length] = words
		list._letter_index[length] = per_length_index
	return list


func contains(word: String) -> bool:
	return _word_set.has(word)


static func _is_alpha(word: String) -> bool:
	for i in range(word.length()):
		var c: int = word.unicode_at(i)
		if c < 65 or c > 90:
			return false
	return true


func words_of_length(length: int) -> Array:
	return _by_length.get(length, [])


func count_for_length(length: int) -> int:
	return words_of_length(length).size()


func matches_pattern(pattern: String) -> Array:
	# Pattern uses "." for unknown letters. Returns all words of pattern.length()
	# whose known letters match. Uses the letter index to start from the
	# *smallest* known-letter bucket, then filters — turns an O(N) scan into
	# O(smallest_bucket × known_positions) which is often 10-100× faster.
	if not pattern.contains("."):
		# Fully constrained: O(1) membership lookup, return [pattern] iff it's a real word.
		return [pattern] if _word_set.has(pattern) else []
	var seed_words: Dictionary = _smallest_letter_bucket(pattern)
	if seed_words.is_empty():
		# Either no known letters (return all words of this length) OR the
		# smallest bucket is empty (no candidates).
		if _has_any_known_letter(pattern):
			return []
		return words_of_length(pattern.length()).duplicate()
	var out: Array = []
	for word in seed_words.keys():
		if _pattern_matches(word, pattern):
			out.append(word)
	return out


func has_match(pattern: String) -> bool:
	# Short-circuit version of matches_pattern. Returns true on the first
	# word that matches. The letter index makes this near-instant for
	# typical patterns the generator emits.
	if not pattern.contains("."):
		return _word_set.has(pattern)
	var seed_words: Dictionary = _smallest_letter_bucket(pattern)
	if seed_words.is_empty():
		if _has_any_known_letter(pattern):
			return false
		# All-wildcard pattern: any word of this length counts.
		return not words_of_length(pattern.length()).is_empty()
	for word in seed_words.keys():
		if _pattern_matches(word, pattern):
			return true
	return false


func _smallest_letter_bucket(pattern: String) -> Dictionary:
	# For each known (non-".") letter in `pattern`, look up its set via the
	# letter index. Return the smallest set, or {} if `pattern` has no known
	# letters. Callers must distinguish "smallest bucket has zero words"
	# (some position has no candidates → no match) from "no known letters at
	# all" (all-wildcard pattern) — the helper _has_any_known_letter does that.
	var idx: Dictionary = _letter_index.get(pattern.length(), {})
	var best: Dictionary = {}
	var best_set: Dictionary = {}
	var seen_any: bool = false
	for pos in range(pattern.length()):
		var ch: String = pattern[pos]
		if ch == ".":
			continue
		seen_any = true
		var key: String = str(pos) + "_" + ch
		var bucket: Variant = idx.get(key, null)
		if bucket == null:
			# This (position, letter) has no words → smallest is empty.
			return {}
		if best.is_empty() or (bucket as Dictionary).size() < best_set.size():
			best_set = bucket
			best = bucket
	if not seen_any:
		return {}
	return best


static func _has_any_known_letter(pattern: String) -> bool:
	for i in range(pattern.length()):
		if pattern[i] != ".":
			return true
	return false


static func _pattern_matches(word: String, pattern: String) -> bool:
	if word.length() != pattern.length():
		return false
	for i in range(pattern.length()):
		var pc: String = pattern[i]
		if pc == ".":
			continue
		if pc != word[i]:
			return false
	return true


func all_lengths() -> Array:
	var lengths: Array = _by_length.keys()
	lengths.sort()
	return lengths


func total_words() -> int:
	var total: int = 0
	for length in _by_length:
		total += _by_length[length].size()
	return total
