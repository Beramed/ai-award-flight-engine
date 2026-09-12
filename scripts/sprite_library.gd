extends Node

var cache: Dictionary = {}


func tex(path: String) -> Texture2D:
	if cache.has(path):
		return cache[path]
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
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


func frames(folder: String, anim: String, count: int = 32) -> Array[Texture2D]:
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
	return _smooth(out)


func _smooth(texs: Array[Texture2D]) -> Array[Texture2D]:
	var n := texs.size()
	if n <= 1 or n >= 10:
		return texs
	var target := mini(n * 2 - 1, 12)
	if n >= target:
		return texs
	var out: Array[Texture2D] = []
	for i in n - 1:
		out.append(texs[i])
		var mid := _lerp_tex(texs[i], texs[i + 1], 0.5)
		if mid:
			out.append(mid)
	out.append(texs[n - 1])
	return out


func _lerp_tex(a: Texture2D, b: Texture2D, t: float) -> Texture2D:
	if a == null or b == null:
		return a
	var ia := a.get_image()
	var ib := b.get_image()
	if ia == null or ib == null:
		return a
	if ia.is_compressed():
		ia.decompress()
	if ib.is_compressed():
		ib.decompress()
	ia.convert(Image.FORMAT_RGBA8)
	ib.convert(Image.FORMAT_RGBA8)
	var w := mini(ia.get_width(), ib.get_width())
	var h := mini(ia.get_height(), ib.get_height())
	if w <= 0 or h <= 0:
		return a
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var ca := ia.get_pixel(x, y)
			var cb := ib.get_pixel(x, y)
			var col := cb if t >= 0.5 else ca
			col.a = lerpf(ca.a, cb.a, t)
			if col.a < 0.18:
				col.a = 0.0
			elif col.a > 0.82:
				col.a = 1.0
			out.set_pixel(x, y, col)
	return ImageTexture.create_from_image(out)


func make_sprite_frames(folder: String, mapping: Dictionary, speed := 10.0) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim in mapping.keys():
		sf.add_animation(anim)
		sf.set_animation_speed(anim, mapping[anim].get("speed", speed))
		sf.set_animation_loop(anim, mapping[anim].get("loop", true))
		var count: int = mapping[anim].get("count", 32)
		var texs := frames(folder, anim, count)
		if texs.is_empty() and mapping[anim].has("fallback"):
			texs = frames(folder, mapping[anim]["fallback"], count)
		for t in texs:
			sf.add_frame(anim, t)
		if texs.is_empty():
			sf.add_frame(anim, _pixel(Color(0.8, 0.2, 0.2)))
	_alias(sf, "shoot_horizontal", "shoot")
	_alias(sf, "shoot_diagonal_up", "shoot_diag")
	_alias(sf, "shoot_diagonal_down", "shoot_diag_down")
	_alias(sf, "interact", "idle")
	return sf


func _alias(sf: SpriteFrames, name: String, source: String) -> void:
	if sf.has_animation(name) and sf.get_frame_count(name) > 1:
		return
	if not sf.has_animation(source):
		return
	if not sf.has_animation(name):
		sf.add_animation(name)
	sf.set_animation_speed(name, sf.get_animation_speed(source))
	sf.set_animation_loop(name, sf.get_animation_loop(source))
	# Replace placeholder/red pixel with the source strip.
	while sf.get_frame_count(name) > 0:
		sf.remove_frame(name, 0)
	for i in sf.get_frame_count(source):
		sf.add_frame(name, sf.get_frame_texture(source, i))


func kiko_frames() -> SpriteFrames:
	return make_sprite_frames("kiko", {
		"idle": {"count": 32, "speed": 5.0},
		"walk": {"count": 32, "speed": 11.0},
		"run": {"count": 32, "speed": 14.0, "fallback": "walk"},
		"jump": {"count": 32, "speed": 10.0},
		"jump_start": {"count": 32, "speed": 12.0, "loop": false},
		"jump_up": {"count": 32, "speed": 10.0},
		"jump_fall": {"count": 32, "speed": 10.0},
		"landing": {"count": 32, "speed": 12.0, "loop": false},
		"jump_shoot": {"count": 32, "speed": 14.0},
		"jump_shoot_fuzil": {"count": 32, "speed": 16.0},
		"crouch": {"count": 32, "speed": 4.0},
		"crouch_walk": {"count": 32, "speed": 9.0},
		"stand_to_crouch": {"count": 32, "speed": 14.0, "loop": false},
		"crouch_to_stand": {"count": 32, "speed": 14.0, "loop": false},
		"crouch_shoot": {"count": 32, "speed": 10.0},
		"shoot": {"count": 32, "speed": 10.0},
		"shoot_horizontal": {"count": 32, "speed": 10.0, "fallback": "shoot"},
		"shoot_up": {"count": 32, "speed": 12.0},
		"shoot_diag": {"count": 32, "speed": 12.0},
		"shoot_diag_down": {"count": 32, "speed": 12.0},
		"shoot_down": {"count": 32, "speed": 14.0},
		"shoot_recoil": {"count": 6, "speed": 16.0, "loop": false},
		"shoot_down_crouch_start": {"count": 2, "speed": 1.0, "loop": false},
		"shoot_down_aim": {"count": 2, "speed": 1.0, "loop": false},
		"shoot_down_fire": {"count": 2, "speed": 1.0, "loop": false},
		"shoot_down_recoil": {"count": 2, "speed": 1.0, "loop": false},
		"shoot_down_recovery": {"count": 2, "speed": 1.0, "loop": false},
		"shoot_pistola": {"count": 10, "speed": 8.0},
		"shoot_fuzil": {"count": 10, "speed": 16.0},
		"shoot_doze": {"count": 12, "speed": 10.0, "loop": false},
		"throw_grenade": {"count": 8, "speed": 14.0, "loop": false},
		"melee": {"count": 8, "speed": 12.0, "loop": false},
		"melee_fuzil": {"count": 8, "speed": 12.0, "loop": false},
		"melee_pistola": {"count": 6, "speed": 10.0, "loop": false},
		"melee_doze": {"count": 6, "speed": 10.0, "loop": false},
		"rage": {"count": 10, "speed": 10.0},
		"hurt": {"count": 32, "loop": false, "speed": 8.0},
		"hit": {"count": 32, "loop": false, "speed": 8.0, "fallback": "hurt"},
		"death": {"count": 32, "loop": false, "speed": 4.0},
		"climb": {"count": 32, "loop": true, "speed": 8.0},
		"victory": {"count": 32, "loop": true, "speed": 2.0},
		"interact": {"count": 32, "loop": true, "speed": 2.0, "fallback": "idle"},
	})


func javali_frames() -> SpriteFrames:
	return make_sprite_frames("javali", {
		"idle": {"count": 8, "speed": 5.0},
		"walk": {"count": 16, "speed": 9.0},
		"run": {"count": 32, "speed": 12.0},
		"charge": {"count": 32, "speed": 14.0, "fallback": "run"},
		"throw": {"count": 16, "speed": 10.0},
		"attack": {"count": 16, "speed": 10.0, "fallback": "throw"},
		"jump": {"count": 8, "speed": 8.0},
		"hit": {"count": 6, "loop": false, "speed": 10.0},
		"die": {"count": 16, "loop": false, "speed": 10.0},
		"die_forward": {"count": 16, "loop": false, "speed": 12.0, "fallback": "die"},
		"die_flip": {"count": 16, "loop": false, "speed": 12.0, "fallback": "die"},
		"death": {"count": 16, "loop": false, "speed": 10.0, "fallback": "die"},
		"blindado": {"count": 8, "speed": 8.0},
		"boss_idle": {"count": 4, "speed": 4.0},
		"boss_charge": {"count": 8, "speed": 10.0},
		"boss_jump": {"count": 4, "speed": 8.0},
	})


func passaro_frames() -> SpriteFrames:
	return make_sprite_frames("passaro", {
		"idle": {"count": 8, "speed": 6.0},
		"walk": {"count": 32, "speed": 12.0, "fallback": "fly"},
		"run": {"count": 32, "speed": 16.0, "fallback": "fly"},
		"fly": {"count": 32, "speed": 12.0},
		"drop": {"count": 20, "speed": 12.0, "loop": false},
		"attack": {"count": 20, "speed": 12.0, "loop": false, "fallback": "drop"},
		"hit": {"count": 6, "loop": false, "speed": 10.0},
		"die": {"count": 8, "loop": false, "speed": 8.0},
		"death": {"count": 8, "loop": false, "speed": 8.0, "fallback": "die"},
	})


func drone_frames() -> SpriteFrames:
	return make_sprite_frames("drone", {
		"idle": {"count": 8, "speed": 8.0},
		"walk": {"count": 16, "speed": 10.0, "fallback": "fly"},
		"run": {"count": 16, "speed": 12.0, "fallback": "fly"},
		"fly": {"count": 16, "speed": 10.0},
		"drop": {"count": 12, "speed": 10.0, "loop": false},
		"attack": {"count": 12, "speed": 10.0, "loop": false, "fallback": "drop"},
		"hit": {"count": 6, "loop": false, "speed": 10.0},
		"die": {"count": 8, "loop": false, "speed": 8.0},
		"death": {"count": 8, "loop": false, "speed": 8.0, "fallback": "die"},
	})


func fx(name: String) -> Texture2D:
	return tex("res://assets/frames/fx/%s.png" % name)


func tile(name: String) -> Texture2D:
	var path := "res://assets/tiles/%s.png" % name
	if cache.has(path):
		return cache[path]
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.get_width() <= 0:
		img = Image.new()
		if img.load(path) != OK or img.get_width() <= 0:
			return tex(path)
	var created := ImageTexture.create_from_image(img)
	cache[path] = created
	return created


func ui(name: String) -> Texture2D:
	var path := "res://assets/ui/%s.png" % name
	if cache.has(path):
		return cache[path]
	# Load the PNG itself so a replaced portrait is not stuck on a stale .ctex.
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.get_width() <= 0:
		img = Image.new()
		if img.load(path) != OK or img.get_width() <= 0:
			return tex(path)
	var created := ImageTexture.create_from_image(img)
	cache[path] = created
	return created


func sheet(name: String) -> Texture2D:
	var jpg := tex("res://assets/sprites/%s.jpg" % name)
	if jpg:
		return jpg
	return tex("res://assets/sprites/%s.png" % name)


func _pixel(color: Color) -> Texture2D:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
