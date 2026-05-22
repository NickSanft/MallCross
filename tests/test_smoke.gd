extends "res://addons/gut/test.gd"


func test_gut_pipeline_runs() -> void:
	assert_true(true, "GUT runner reached this assertion — Phase 0 CI is alive.")


func test_project_name_is_mallcross() -> void:
	var project_name: String = ProjectSettings.get_setting("application/config/name")
	assert_eq(project_name, "MallCross", "project.godot should declare config/name=MallCross")
