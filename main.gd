extends Node2D

const W := 720.0
const H := 1280.0
const FLOOR_Y := 1010.0
const GRAVITY := 2300.0
const JUMP_V := -870.0
const SAVE_PATH := "user://altin_avi.save"

var player := Vector2(145, FLOOR_Y - 48)
var player_vy := 0.0
var grounded := true
var game_started := false
var game_over := false
var score := 0
var coins := 0
var best := 0
var speed := 430.0
var spawn_timer := 0.0
var coin_timer := 0.0
var world_offset := 0.0
var obstacles: Array[Rect2] = []
var pickups: Array[Vector2] = []
var particles: Array[Dictionary] = []
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	load_save()
	get_viewport().size_changed.connect(queue_redraw)
	set_process(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if game_over:
			start_game()
		elif not game_started:
			game_started = true
			jump()
		else:
			jump()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_UP:
			if game_over:
				start_game()
			elif not game_started:
				game_started = true
				jump()
			else:
				jump()
		elif event.keycode == KEY_DOWN:
			player_vy = 1150.0
	elif event is InputEventMouseButton and event.pressed:
		if game_over:
			start_game()
		elif not game_started:
			game_started = true
			jump()
		else:
			jump()

func start_game() -> void:
	player = Vector2(145, FLOOR_Y - 48)
	player_vy = 0
	grounded = true
	game_started = true
	game_over = false
	score = 0
	coins = 0
	speed = 430
	spawn_timer = 0.7
	coin_timer = 1.1
	obstacles.clear()
	pickups.clear()
	particles.clear()
	world_offset = 0
	queue_redraw()

func jump() -> void:
	if grounded and game_started and not game_over:
		player_vy = JUMP_V
		grounded = false
		for i in range(7):
			particles.append({"p": player + Vector2(0, 28), "v": Vector2(randf_range(-100, 80), randf_range(40, 180)), "life": 0.45, "max": 0.45, "color": Color("#b9d7ff")})

func _process(delta: float) -> void:
	if game_started and not game_over:
		speed = minf(760.0, speed + delta * 4.0)
		score += int(delta * 12)
		world_offset = fmod(world_offset + speed * delta, 180.0)
		player_vy += GRAVITY * delta
		player.y += player_vy * delta
		if player.y >= FLOOR_Y - 48:
			player.y = FLOOR_Y - 48
			player_vy = 0
			grounded = true
		spawn_timer -= delta
		if spawn_timer <= 0:
			var tall := randf() < 0.42
			var oh := randf_range(68, 108) if tall else randf_range(44, 68)
			var ow := randf_range(42, 66)
			obstacles.append(Rect2(W + 60, FLOOR_Y - oh, ow, oh))
			spawn_timer = randf_range(1.05, 1.65) * (430.0 / speed)
		coin_timer -= delta
		if coin_timer <= 0:
			var base_y := randf_range(FLOOR_Y - 300, FLOOR_Y - 125)
			for i in range(4):
				pickups.append(Vector2(W + 80 + i * 48, base_y + sin(i * 0.9) * 22))
			coin_timer = randf_range(1.3, 2.0)
		for i in range(obstacles.size() - 1, -1, -1):
			obstacles[i].position.x -= speed * delta
			if obstacles[i].end.x < -20:
				obstacles.remove_at(i)
		for i in range(pickups.size() - 1, -1, -1):
			pickups[i].x -= speed * delta
			if pickups[i].x < -30:
				pickups.remove_at(i)
			elif pickups[i].distance_to(player + Vector2(0, -8)) < 65:
				coins += 1
				for j in range(5):
					particles.append({"p": pickups[i], "v": Vector2(randf_range(-90,90),randf_range(-150,50)), "life":0.35,"max":0.35,"color":Color("#ffd65a")})
				pickups.remove_at(i)
		var hitbox := Rect2(player.x - 23, player.y - 35, 46, 64)
		for ob in obstacles:
			if hitbox.intersects(ob):
				end_game()
				break
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= delta
		particles[i].p += particles[i].v * delta
		particles[i].v.y += 340 * delta
		if particles[i].life <= 0:
			particles.remove_at(i)
	queue_redraw()

func end_game() -> void:
	game_over = true
	game_started = false
	best = maxi(best, score)
	save_game()

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var({"best": best, "coins": coins})

func load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var data = f.get_var()
			if data is Dictionary:
				best = int(data.get("best", 0))

func _draw() -> void:
	var sx := get_viewport_rect().size.x / W
	var sy := get_viewport_rect().size.y / H
	draw_set_transform(Vector2.ZERO, 0, Vector2(sx, sy))
	draw_rect(Rect2(0, 0, W, H), Color("#101b3a"))
	draw_circle(Vector2(565, 180), 68, Color("#ffdb85"))
	draw_circle(Vector2(565, 180), 88, Color(1, 0.82, 0.48, 0.10))
	for i in range(8):
		var x := fposmod(i * 145.0 - world_offset * 0.22, W + 160.0) - 80
		draw_colored_polygon(PackedVector2Array([Vector2(x-100, FLOOR_Y), Vector2(x+15, 440 + (i%3)*75), Vector2(x+150, FLOOR_Y)]), Color("#23385f"))
		draw_colored_polygon(PackedVector2Array([Vector2(x+15, 440 + (i%3)*75), Vector2(x+62, 590 + (i%3)*75), Vector2(x+35, 565 + (i%3)*75)]), Color("#9cb6d6", 0.7))
	draw_rect(Rect2(0, FLOOR_Y - 8, W, 8), Color("#56e0c0"))
	draw_rect(Rect2(0, FLOOR_Y, W, H - FLOOR_Y), Color("#182b45"))
	for i in range(7):
		var x := fposmod(i * 180.0 - world_offset, W + 180.0) - 80
		draw_line(Vector2(x, FLOOR_Y + 55), Vector2(x - 95, H), Color("#263d5c"), 4)
		draw_line(Vector2(x + 55, FLOOR_Y + 55), Vector2(x + 150, H), Color("#263d5c"), 4)
	for i in range(14):
		var bx := fposmod(i * 77.0 - world_offset * 0.45, W + 90.0) - 45
		var bh := 55 + (i * 37 % 100)
		draw_rect(Rect2(bx, FLOOR_Y - bh, 44, bh), Color("#1c3151"))
		for wy in range(int((bh - 12) / 22)):
			draw_rect(Rect2(bx + 10, FLOOR_Y - bh + 12 + wy*22, 5, 7), Color("#ffdb85", 0.55))
			draw_rect(Rect2(bx + 27, FLOOR_Y - bh + 12 + wy*22, 5, 7), Color("#7ce9d0", 0.45))
	for c in pickups:
		draw_circle(c, 19, Color(1, 0.79, 0.25, 0.18))
		draw_circle(c, 13, Color("#ffd24f"))
		draw_circle(c + Vector2(-3, -3), 5, Color("#fff2a7"))
		draw_arc(c, 18, 0, TAU, 32, Color("#ffed9a"), 3)
	for ob in obstacles:
		draw_rect(ob.grow(7), Color(1, 0.23, 0.37, 0.15), true, 12)
		draw_rect(ob, Color("#f05a70"), true, 10)
		draw_rect(Rect2(ob.position.x + 7, ob.position.y + 7, ob.size.x - 14, 8), Color("#ffb1b9"), true, 4)
		draw_line(ob.position + Vector2(8, ob.size.y - 12), ob.position + Vector2(ob.size.x - 8, ob.size.y - 12), Color("#9e314e"), 4)
	draw_ellipse(Vector2(player.x, FLOOR_Y - 4), Vector2(42, 10), Color(0, 0, 0, 0.28))
	draw_circle(player + Vector2(0, 3), 32, Color("#ff9b50"))
	draw_circle(player + Vector2(0, -22), 28, Color("#ffb86b"))
	draw_colored_polygon(PackedVector2Array([player+Vector2(-24,-39),player+Vector2(-27,-70),player+Vector2(-5,-51)]), Color("#ffb86b"))
	draw_colored_polygon(PackedVector2Array([player+Vector2(9,-51),player+Vector2(29,-73),player+Vector2(25,-35)]), Color("#ffb86b"))
	draw_colored_polygon(PackedVector2Array([player+Vector2(-21,-49),player+Vector2(-22,-62),player+Vector2(-11,-52)]), Color("#f47763"))
	draw_colored_polygon(PackedVector2Array([player+Vector2(13,-51),player+Vector2(24,-63),player+Vector2(22,-45)]), Color("#f47763"))
	draw_ellipse(player + Vector2(1,-12), Vector2(20,14), Color("#fff0d8"))
	draw_circle(player + Vector2(9,-27), 4.5, Color("#18233f"))
	draw_circle(player + Vector2(10,-28), 1.4, Color.WHITE)
	draw_circle(player + Vector2(25,-12), 4, Color("#7b3541"))
	draw_line(player+Vector2(-14,25),player+Vector2(-20,39),Color("#ffd2a2"),7)
	draw_line(player+Vector2(12,25),player+Vector2(19,38),Color("#ffd2a2"),7)
	for p in particles:
		draw_circle(p.p, 4 * p.life / p.max, p.color)
	draw_round_rect(Rect2(26, 30, 668, 106), Color(0.06,0.10,0.20,0.76), 26)
	draw_string(font, Vector2(52, 70), "ALTIN AVI", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#80f0d0"))
	draw_string(font, Vector2(52, 109), "MESAFE  %05d m" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
	draw_round_rect(Rect2(492, 48, 175, 60), Color("#273c5b"), 20)
	draw_circle(Vector2(521, 78), 13, Color("#ffd24f"))
	draw_string(font, Vector2(546, 86), str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#ffe8a0"))
	if not game_started and not game_over:
		draw_round_rect(Rect2(55, 475, 610, 235), Color(0.04,0.08,0.17,0.88), 32)
		draw_string(font, Vector2(360, 535), "MACERAYA HAZIR MISIN?", HORIZONTAL_ALIGNMENT_CENTER, -1, 29, Color("#ffffff"))
		draw_string(font, Vector2(360, 588), "Zıpla, engelleri aş, altınları topla!", HORIZONTAL_ALIGNMENT_CENTER, -1, 19, Color("#c8d8f2"))
		draw_round_rect(Rect2(175, 625, 370, 62), Color("#42d9b1"), 22)
		draw_string(font, Vector2(360, 665), "BAŞLAMAK İÇİN DOKUN", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color("#10253b"))
	if game_over:
		draw_rect(Rect2(0, 0, W, H), Color(0.02,0.04,0.10,0.68))
		draw_round_rect(Rect2(55, 405, 610, 410), Color("#182b49"), 34)
		draw_string(font, Vector2(360, 475), "TUR BİTTİ!", HORIZONTAL_ALIGNMENT_CENTER, -1, 42, Color("#ff9b91"))
		draw_string(font, Vector2(360, 540), "Mesafe: %d m" % score, HORIZONTAL_ALIGNMENT_CENTER, -1, 27, Color.WHITE)
		draw_string(font, Vector2(360, 586), "Toplanan altın: %d" % coins, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color("#ffdf75"))
		draw_string(font, Vector2(360, 625), "En iyi: %d m" % best, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color("#9fefd9"))
		draw_round_rect(Rect2(160, 680, 400, 74), Color("#42d9b1"), 24)
		draw_string(font, Vector2(360, 727), "TEKRAR OYNA", HORIZONTAL_ALIGNMENT_CENTER, -1, 25, Color("#10253b"))

func draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	draw_rect(rect, color, true)
	draw_rect(rect, color.lightened(0.13), false, 2)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radius.x, sin(a)*radius.y))
	draw_colored_polygon(points, color)
