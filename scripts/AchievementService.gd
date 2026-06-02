class_name AchievementService
extends RefCounted

# Owns the live unlock state for the running game session. Holds the catalog
# (loaded once at construction) and the per-player unlocks dict (id -> day).
# Exposes a `notify_*` API that the GameController calls at the appropriate
# gameplay events; each notify method examines the relevant condition and
# unlocks any achievements that fire. Newly-unlocked achievements are
# returned so the caller can route them to a toast or other UI.
#
# Persistence is the caller's responsibility — call save() (or have the
# GameController call AchievementStore.save_to_path) after notify_*
# returns a non-empty array.

const MINI_SPEED_THRESHOLD_MS: int = 60 * 1000
const HOARDER_WOINTS: int = 1000

var catalog: Array  # Read-only copy of AchievementCatalog.load_all()
var unlocks: Dictionary = {}  # id -> day_unlocked (int)


func _init(p_catalog: Array = [], p_unlocks: Dictionary = {}) -> void:
	# Both args optional so tests can pass synthetic catalogs / unlock
	# states. In production GameController loads them from disk and passes
	# them in.
	catalog = p_catalog
	if p_unlocks is Dictionary:
		for id in p_unlocks:
			if id is String:
				unlocks[String(id)] = int(p_unlocks[id])


func is_unlocked(id: String) -> bool:
	return unlocks.has(id)


func unlock(id: String, day: int) -> bool:
	# Internal primitive used by all notify_* helpers. Returns true iff the
	# achievement was newly unlocked this call. Catalog membership is
	# required — silently no-ops on unknown ids so a stray notify can't
	# pollute the unlock state with junk.
	if id == "" or unlocks.has(id):
		return false
	if AchievementCatalog.find_by_id(catalog, id).is_empty():
		return false
	unlocks[id] = max(0, day)
	return true


func recently_unlocked_entry(id: String) -> Dictionary:
	return AchievementCatalog.find_by_id(catalog, id)


func all_with_state() -> Array:
	# Catalog with an `unlocked: bool` (and `unlock_day` if unlocked) merged
	# in. Hidden entries pass through unfiltered — the UI layer decides
	# whether to render them based on `hidden && !unlocked`.
	var out: Array = []
	for entry in catalog:
		var id: String = String(entry.get("id", ""))
		var augmented: Dictionary = entry.duplicate(true)
		augmented["unlocked"] = unlocks.has(id)
		if unlocks.has(id):
			augmented["unlock_day"] = int(unlocks[id])
		out.append(augmented)
	return out


func progress_string() -> String:
	# "5 / 13" — used in the menu header. Counts hidden achievements too;
	# the UI hides their names but they still contribute to the tally.
	return "%d / %d" % [unlocks.size(), catalog.size()]


# --- Notifications -----------------------------------------------------
# Each notify_* method returns the Array of achievement ids newly unlocked
# in this call (possibly empty). The GameController feeds those ids to the
# toast queue.


func notify_puzzle_solved(puzzle_id: String, difficulty: String, day: int, elapsed_ms: int, used_check_letter: bool, profile: Profile) -> Array:
	var fired: Array = []
	if puzzle_id == "":
		return fired
	if unlock("first_solve", day):
		fired.append("first_solve")
	if puzzle_id == "mall_day_one" and unlock("mini_day_one", day):
		fired.append("mini_day_one")
	if puzzle_id == "mall_midi_day_one" and unlock("midi_day_one", day):
		fired.append("midi_day_one")
	if puzzle_id == "mall_full_day_one" and unlock("full_day_one", day):
		fired.append("full_day_one")
	if not used_check_letter and unlock("no_checks", day):
		fired.append("no_checks")
	if difficulty == PuzzleSchedule.DIFFICULTY_MINI and elapsed_ms > 0 and elapsed_ms < MINI_SPEED_THRESHOLD_MS:
		if unlock("speed_mini", day):
			fired.append("speed_mini")
	# Polyglot: solved one in each tier on this day.
	if profile != null and _solved_one_per_tier_on(profile, day):
		if unlock("polyglot", day):
			fired.append("polyglot")
	return fired


func notify_streak(streak: int, day: int) -> Array:
	var fired: Array = []
	if streak >= 7 and unlock("streak_7", day):
		fired.append("streak_7")
	if streak >= 30 and unlock("streak_30", day):
		fired.append("streak_30")
	return fired


func notify_item_purchased(item_id: String, woints_remaining: int, day: int) -> Array:
	var fired: Array = []
	if item_id == "coffee" and unlock("caffeinated", day):
		fired.append("caffeinated")
	if item_id == "pencil" and unlock("bookworm", day):
		fired.append("bookworm")
	if woints_remaining == 0 and unlock("big_spender", day):
		fired.append("big_spender")
	return fired


func notify_woints(total: int, day: int) -> Array:
	var fired: Array = []
	if total >= HOARDER_WOINTS and unlock("hoarder", day):
		fired.append("hoarder")
	return fired


# v1.9.0 Phase 22: rooftop + season-progress hooks. GameController calls
# notify_rooftop_solved after a rooftop puzzle is finished (in addition
# to the standard puzzle_solved notification, which still fires for
# day-1 / first-solve / no-checks / etc.). notify_season_progress runs
# on every solve and the rooftop_unlock_state hook.


func notify_rooftop_solved(puzzle_id: String, day: int, profile: Profile) -> Array:
	# Fires "rooftop_regular" once the player has solved all 4 weekly
	# rooftop puzzles. We count via profile.puzzles_solved keys against
	# the canonical list from PuzzleSchedule.all_rooftop_puzzles(), so
	# the test is "did this player ever solve each of them," not "are
	# they all in the current season."
	var fired: Array = []
	if puzzle_id == "" or profile == null:
		return fired
	var all_rooftop: Array = PuzzleSchedule.all_rooftop_puzzles()
	if all_rooftop.is_empty():
		return fired
	var solved_count: int = 0
	for rid in all_rooftop:
		if profile.is_puzzle_solved(String(rid)):
			solved_count += 1
	if solved_count >= all_rooftop.size() and unlock("rooftop_regular", day):
		fired.append("rooftop_regular")
	return fired


func notify_season_progress(profile: Profile) -> Array:
	# Fires "season_pass" (>= 21 solves in current season) and
	# "perfectionist" (solved every puzzle scheduled in current
	# season). Cheap enough to run on every notify_puzzle_solved.
	var fired: Array = []
	if profile == null:
		return fired
	var day: int = profile.current_day
	var solves: int = SeasonMath.solves_in_current_season(day, profile.puzzles_solved)
	if solves >= SeasonMath.ROOFTOP_UNLOCK_THRESHOLD and unlock("season_pass", day):
		fired.append("season_pass")
	if _season_perfect(profile, day) and unlock("perfectionist", day):
		fired.append("perfectionist")
	return fired


static func _season_perfect(profile: Profile, current_day: int) -> bool:
	# Returns true iff every daily-scheduled puzzle (MINI + MIDI + FULL)
	# whose day falls in the current season is in profile.puzzles_solved.
	# Iterates the schedules rather than the profile so future content
	# expansions auto-update what "perfectionist" requires.
	var season_range: Dictionary = SeasonMath.season_range_for_day(current_day)
	var first_day: int = int(season_range["first"])
	var last_day: int = int(season_range["last"])
	for tier in PuzzleSchedule.all_difficulties():
		for sched_day in PuzzleSchedule.scheduled_days(tier):
			var d: int = int(sched_day)
			if d < first_day or d > last_day:
				continue
			var pid: String = PuzzleSchedule.puzzle_id_for_day(d, tier)
			if pid == "" or not profile.is_puzzle_solved(pid):
				return false
	return true


# --- Helpers -----------------------------------------------------------

func _solved_one_per_tier_on(profile: Profile, day: int) -> bool:
	# Walks the schedule rather than the profile so a new puzzle added in a
	# future patch automatically counts toward Polyglot. Three tiers, ~30
	# day-lookups each in the worst case — negligible cost on the rare
	# event of a solve.
	var tiers: Array = PuzzleSchedule.all_difficulties()
	for tier in tiers:
		if not _any_solve_in_tier_on_day(profile, tier, day):
			return false
	return true


static func _any_solve_in_tier_on_day(profile: Profile, tier: String, day: int) -> bool:
	for sched_day in PuzzleSchedule.scheduled_days(tier):
		var id: String = PuzzleSchedule.puzzle_id_for_day(int(sched_day), tier)
		if id == "":
			continue
		if profile.first_solved_day(id) == day:
			return true
	return false
