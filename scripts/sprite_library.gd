extends Node

var cache: Dictionary = {}


func tex(path: String) -> Texture2D:
	if cache.has(path):
		return cache[path]
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			cache[path] = loaded
			return loaded
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img:
			var created := ImageTexture.create_from_image(img)
			cache[path] = created
			return created
	cache[path] = null
	return null


func frames(folder: String, anim: String, count: int = 8) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for i in count:
		var p := "res://assets/frames/%s/%s_%02d.png" % [folder, anim, i]
		var t := tex(p)
		if t == null:
			break
		out.append(t)
	if out.is_empty():
		var single := tex("res://assets/frames/%s/%s_00.png" % [folder, anim])
		if single:
			out.append(single)
	return out


func make_sprite_frames(folder: String, mapping: Dictionary, speed := 10.0) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim in mapping.keys():
		sf.add_animation(anim)
		sf.set_animation_speed(anim, mapping[anim].get("speed", speed))
		sf.set_animation_loop(anim, mapping[anim].get("loop", true))
		var count: int = mapping[anim].get("count", 8)
		var texs := frames(folder, anim, count)
		if texs.is_empty() and mapping[anim].has("fallback"):
			texs = frames(folder, mapping[anim]["fallback"], 4)
		for t in texs:
			sf.add_frame(anim, t)
		if texs.is_empty():
			sf.add_frame(anim, _pixel(Color(0.8, 0.2, 0.2)))
	return sf


func kiko_frames() -> SpriteFrames:
	return make_sprite_frames("kiko", {
		"idle": {"count": 4, "speed": 5.0},
		"walk": {"count": 6, "speed": 10.0},
		"jump": {"count": 6, "speed": 10.0},
		"jump_shoot": {"count": 12, "speed": 14.0},
		"jump_shoot_fuzil": {"count": 6, "speed": 16.0},
		"crouch": {"count": 2, "speed": 4.0},
		"shoot": {"count": 4, "speed": 10.0},
		"shoot_up": {"count": 3, "speed": 12.0},
		"shoot_diag": {"count": 3, "speed": 12.0},
		"shoot_pistola": {"count": 6, "speed": 8.0},
		"shoot_fuzil": {"count": 6, "speed": 16.0},
		"shoot_doze": {"count": 7, "speed": 10.0, "loop": false},
		"throw_grenade": {"count": 6, "speed": 14.0, "loop": false},
		"melee": {"count": 3, "speed": 12.0, "loop": false},
		"melee_fuzil": {"count": 3, "speed": 12.0, "loop": false},
		"melee_pistola": {"count": 2, "speed": 10.0, "loop": false},
		"melee_doze": {"count": 2, "speed": 10.0, "loop": false},
		"rage": {"count": 4, "speed": 10.0},
		"hurt": {"count": 2, "loop": false, "speed": 6.0},
		"death": {"count": 2, "loop": false, "speed": 3.0},
		"climb": {"count": 1, "loop": true, "speed": 6.0},
		"victory": {"count": 1, "loop": true, "speed": 1.0},
	})


func javali_frames() -> SpriteFrames:
	return make_sprite_frames("javali", {
		"run": {"count": 4, "speed": 10.0},
		"charge": {"count": 3, "speed": 12.0},
		"jump": {"count": 2, "speed": 8.0},
		"die": {"count": 1, "loop": false},
		"blindado": {"count": 3, "speed": 8.0},
		"boss_idle": {"count": 2, "speed": 4.0},
		"boss_charge": {"count": 3, "speed": 10.0},
		"boss_jump": {"count": 2, "speed": 8.0},
	})


func fx(name: String) -> Texture2D:
	return tex("res://assets/frames/fx/%s.png" % name)


func tile(name: String) -> Texture2D:
	return tex("res://assets/tiles/%s.png" % name)


func ui(name: String) -> Texture2D:
	return tex("res://assets/ui/%s.png" % name)


func sheet(name: String) -> Texture2D:
	var jpg := tex("res://assets/sprites/%s.jpg" % name)
	if jpg:
		return jpg
	return tex("res://assets/sprites/%s.png" % name)


func _pixel(color: Color) -> Texture2D:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
