## Headless test runner. Runs every res://tests/test_*.gd suite.
##   godot --headless --path game --script res://tests/run_tests.gd
## Exit code 0 = all passed. See docs/08_TESTING.md.
extends SceneTree


func _initialize() -> void:
	var passed := 0
	var failed := 0
	var files := DirAccess.get_files_at("res://tests")
	files.sort()
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_case.gd":
			continue
		var suite = load("res://tests/" + f).new()
		suite.before_all()
		for m in suite.get_method_list():
			var name: String = m["name"]
			if name.begins_with("test_"):
				suite.current = name
				suite.call(name)
		print("  %-28s %3d passed, %d failed" % [f, suite.passed, suite.failed])
		passed += suite.passed
		failed += suite.failed
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
