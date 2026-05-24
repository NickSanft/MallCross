class_name Wordlist
extends RefCounted

# Loads a JSON wordlist organized by word length:
#   {"3": ["CAT", "DOG", ...], "4": [...], ...}
# Provides length-indexed access for the puzzle generator + pattern matching.

const DEFAULT_PATH: String = "res://data/wordlists/common_words.json"

var _by_length: Dictionary = {}  # int -> Array[String] (uppercase)
var _word_set: Dictionary = {}  # word -> true, for O(1) membership tests


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
		for word_variant in raw:
			var word: String = String(word_variant).to_upper()
			if word.length() == length and _is_alpha(word):
				words.append(word)
				list._word_set[word] = true
		list._by_length[length] = words
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
	# whose known letters match.
	var candidates: Array = words_of_length(pattern.length())
	var out: Array = []
	for word in candidates:
		if _pattern_matches(word, pattern):
			out.append(word)
	return out


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
