class_name ProfileStore
extends RefCounted

# Disk I/O for the player profile. JSON at user://profile.json by default;
# tests pass a temp path. All failure modes (missing file, malformed JSON,
# I/O error) fall through to a fresh default Profile so the game always
# boots into a playable state.

const DEFAULT_PATH: String = "user://profile.json"


static func load_from_path(path: String = DEFAULT_PATH) -> Profile:
	if not FileAccess.file_exists(path):
		return Profile.new()
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		return Profile.new()
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Profile at %s was not a JSON object; starting fresh." % path)
		return Profile.new()
	return Profile.from_dict(parsed)


static func save_to_path(profile: Profile, path: String = DEFAULT_PATH) -> bool:
	if profile == null:
		return false
	var content: String = JSON.stringify(profile.to_dict(), "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ProfileStore: failed to open %s for writing (%d)." % [path, FileAccess.get_open_error()])
		return false
	file.store_string(content)
	file.close()
	return true


static func delete_at_path(path: String = DEFAULT_PATH) -> bool:
	# Convenience for tests + a future "Reset Save" menu option.
	if not FileAccess.file_exists(path):
		return false
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	return dir.remove(path.get_file()) == OK
