extends Control
## REALM OF FORTUNE - first native Godot prototype.
## All UI is created at runtime so it can be exported without external artwork.

const SAVE_PATH := "user://realm_save.json"
const TILE_COUNT := 30
const TYPES := ["town", "forest", "battle", "treasure", "camp", "battle", "forest", "boss", "treasure", "battle"]
const LABELS := {"town":"เมือง", "forest":"ป่า", "battle":"ศัตรู", "treasure":"สมบัติ", "camp":"พักแรม", "boss":"บอส"}
const COLORS := {"town":Color("#d7ae6b"), "forest":Color("#70b987"), "battle":Color("#ce716d"), "treasure":Color("#f3d47c"), "camp":Color("#76c6c6"), "boss":Color("#ad83d4")}
const HEROES := [
	{"name":"อัศวิน", "hp":25, "atk":5, "def":3},
	{"name":"นักเวท", "hp":18, "atk":8, "def":1},
	{"name":"นักธนู", "hp":20, "atk":6, "def":2},
	{"name":"นักบวช", "hp":24, "atk":4, "def":3},
	{"name":"นักสำรวจ", "hp":22, "atk":5, "def":2},
	{"name":"พ่อค้า", "hp":21, "atk":4, "def":2}
]
var players: Array = []
var current := 0
var round_no := 1
var phase := "roll"
var choice_steps := 0
var info := "เริ่มการผจญภัย!"
var rng := RandomNumberGenerator.new()
var board: Control
var header: Label
var stats: Label
var message: Label
var primary: Button
var secondary: Button
var utility: Button
var start_layer: PanelContainer
var player_count := 2
var selected_classes: Array = []

func _ready() -> void:
	print("REALM BOOT: Godot main scene initialized")
	rng.randomize()
	var thai_font: Font = preload("res://assets/fonts/Sarabun-Regular.ttf")
	if thai_font:
		var mobile_theme := Theme.new()
		mobile_theme.default_font = thai_font
		mobile_theme.default_font_size = 20
		theme = mobile_theme
	_build_ui()
	if not _load_game():
		_show_setup()
	else:
		_refresh()

func _build_ui() -> void:
	print("REALM BOOT: building UI")
	var background := ColorRect.new()
	background.color = Color("#10222d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	header = _label("REALM OF FORTUNE", 23, Color("#f8dda5"))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(header)
	board = Control.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 330)
	board.draw.connect(_draw_board)
	root.add_child(board)
	var hud := PanelContainer.new()
	root.add_child(hud)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	hud.add_child(column)
	stats = _label("", 17, Color("#f7e7c6"))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	message = _label("", 15, Color("#d6e4e6"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	primary = _button("ทอยเต๋า", buttons, _primary_action)
	secondary = _button("เลือกเส้นทาง", buttons, _secondary_action)
	utility = _button("ใช้ยา", buttons, _use_potion)
	var footer := _label("REALM OF FORTUNE • MOBILE", 12, Color("#91b0b3"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, parent: Node, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 17)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_setup() -> void:
	print("REALM BOOT: setup screen")
	if is_instance_valid(start_layer):
		start_layer.queue_free()
	start_layer = PanelContainer.new()
	start_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_layer.custom_minimum_size = Vector2.ZERO
	start_layer.position = Vector2.ZERO
	add_child(start_layer)
	var column := VBoxContainer.new()
	start_layer.add_child(column)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_label("เริ่มเกมใหม่ • เลือกจำนวนผู้เล่น", 21, Color("#f8dda5")))
	var count := OptionButton.new()
	for i in range(2, 7):
		count.add_item("%d ผู้เล่น" % i, i)
	count.select(player_count - 2)
	count.item_selected.connect(func(index: int) -> void: player_count = index + 2)
	column.add_child(count)
	column.add_child(_label("เลือกอาชีพให้ผู้เล่นทีละคน", 17, Color("#d6e4e6")))
	var go := _button("เริ่มเลือกตัวละคร", column, _choose_next)
	go.custom_minimum_size.y = 65

func _choose_next() -> void:
	if not is_instance_valid(start_layer):
		return
	for child in start_layer.get_children():
		child.queue_free()
	var column := VBoxContainer.new()
	start_layer.add_child(column)
	column.add_child(_label("ผู้เล่น %d เลือกอาชีพ" % (selected_classes.size() + 1), 21, Color("#f8dda5")))
	for i in range(HEROES.size()):
		var class_index := i
		_button(HEROES[i].name, column, func() -> void:
			selected_classes.append(class_index)
			if selected_classes.size() == player_count:
				_new_game()
			else:
				_choose_next()
		)

func _new_game() -> void:
	players.clear()
	for i in range(player_count):
		var hero: Dictionary = HEROES[int(selected_classes[i])]
		players.append({"name":"ผู้เล่น %d" % (i + 1), "class":selected_classes[i], "hp":hero.hp, "max_hp":hero.hp, "atk":hero.atk, "def":hero.def, "pos":0, "gold":6, "potions":2, "relics":0})
	current = 0
	round_no = 1
	phase = "roll"
	info = "ผู้เล่น 1 เริ่มทอยลูกเต๋า"
	if is_instance_valid(start_layer):
		start_layer.queue_free()
	_save_game()
	_refresh()

func _refresh() -> void:
	if players.is_empty():
		return
	var p: Dictionary = players[current]
	header.text = "REALM OF FORTUNE     •     รอบ %d" % round_no
	stats.text = "%s (%s)  |  HP %d/%d  |  ATK %d  DEF %d\nทอง %d  |  โบราณวัตถุ %d/3" % [p.name, HEROES[p["class"]].name, p.hp, p.max_hp, p.atk, p.def, p.gold, p.relics]
	message.text = info
	primary.text = "ทอยเต๋า" if phase == "roll" else ("เดินทางรอบนอก" if phase == "choice" else "จบเทิร์น")
	secondary.text = "ทางลัด" if phase == "choice" else "เป้าหมาย"
	utility.text = "ยา (%d)" % p.potions
	utility.disabled = p.potions <= 0 or p.hp >= p.max_hp
	board.queue_redraw()

func _primary_action() -> void:
	if players.is_empty():
		return
	match phase:
		"roll":
			choice_steps = rng.randi_range(1, 6)
			phase = "choice"
			info = "ทอยได้ %d แต้ม • เลือกเส้นทาง" % choice_steps
		"choice":
			_move(false)
		"done":
			_next_turn()
	_refresh()

func _secondary_action() -> void:
	if players.is_empty():
		return
	if phase == "choice":
		_move(true)
	else:
		info = "สะสมโบราณวัตถุ 3 ชิ้นเพื่อชนะ • ชนะบอสหรือค้นพบในหีบ"
	_refresh()

func _move(shortcut: bool) -> void:
	var p: Dictionary = players[current]
	var move_by := choice_steps
	if shortcut:
		move_by += 2
	p.pos = (p.pos + move_by) % TILE_COUNT
	var kind: String = TYPES[int(p.pos) % TYPES.size()]
	var result := ""
	match kind:
		"town":
			p.gold += 5
			result = "เข้าเมือง ได้รับ 5 เหรียญ"
		"camp":
			p.hp = mini(p.max_hp, p.hp + 7)
			result = "พักแรม ฟื้นฟู 7 HP"
		"forest":
			if rng.randi_range(1, 6) >= 3:
				p.potions += 1
				result = "สำรวจป่า พบยาฟื้นพลัง"
			else:
				result = "สำรวจป่า ไม่พบอะไร"
		"treasure":
			var found := rng.randi_range(1, 6)
			p.gold += 5 + found
			if found >= 5:
				p.relics += 1
			result = "เปิดหีบ! ได้ทอง %d%s" % [5 + found, " และโบราณวัตถุ!" if found >= 5 else ""]
		"battle", "boss":
			var boss := kind == "boss"
			var monster := rng.randi_range(3, 9) + (5 if boss else 0)
			var attack: int = rng.randi_range(1, 6) + int(p.atk)
			if attack >= monster:
				p.gold += 10 if boss else 4
				if boss:
					p.relics += 1
				result = "ชนะ%s! โจมตี %d ต่อ %d" % ["บอส" if boss else "ศัตรู", attack, monster]
			else:
				var damage: int = maxi(1, monster - int(p.def) - 2)
				p.hp = maxi(0, p.hp - damage)
				result = "พ่ายแพ้ เสีย %d HP" % damage
	if p.hp <= 0:
		p.hp = p.max_hp
		p.gold = maxi(0, p.gold - 5)
		p.pos = 0
		result += " • กลับจุดเริ่มต้น"
	if p.relics >= 3:
		phase = "won"
		info = "%s ชนะเกม!" % p.name
	else:
		phase = "done"
		info = "ช่อง %d • %s • %s" % [p.pos + 1, LABELS[kind], result]
	_save_game()

func _next_turn() -> void:
	if phase == "won":
		return
	current = (current + 1) % players.size()
	if current == 0:
		round_no += 1
	phase = "roll"
	info = "%s เตรียมทอยลูกเต๋า" % players[current].name
	_save_game()

func _use_potion() -> void:
	if players.is_empty():
		return
	var p: Dictionary = players[current]
	if p.potions > 0 and p.hp < p.max_hp:
		p.potions -= 1
		p.hp = mini(p.max_hp, p.hp + 8)
		info = "ใช้ยา ฟื้นฟู 8 HP"
		_save_game()
	_refresh()

func _draw_board() -> void:
	if players.is_empty():
		return
	var w: float = board.size.x
	var h: float = board.size.y
	var center := Vector2(w * 0.5, h * 0.50)
	var rx: float = maxf(100.0, w * 0.40)
	var ry: float = maxf(100.0, h * 0.41)
	board.draw_rect(Rect2(Vector2.ZERO, board.size), Color("#10252f"))
	# A layered fantasy island: water, shoreline, hills, forest and ruins.
	board.draw_circle(center + Vector2(0, 16), minf(rx, ry) * 1.03, Color("#0c1b25"))
	board.draw_circle(center, minf(rx, ry) * 0.96, Color("#a98e60"))
	board.draw_circle(center, minf(rx, ry) * 0.91, Color("#3d725e"))
	board.draw_circle(center + Vector2(-rx * 0.34, -ry * 0.20), minf(rx, ry) * 0.38, Color("#567f56"))
	board.draw_circle(center + Vector2(rx * 0.35, ry * 0.24), minf(rx, ry) * 0.29, Color("#c3a46d"))
	board.draw_circle(center + Vector2(rx * 0.30, -ry * 0.34), minf(rx, ry) * 0.26, Color("#7e93a1"))
	board.draw_circle(center + Vector2(rx * 0.30, -ry * 0.39), minf(rx, ry) * 0.19, Color("#b9c4c6"))
	# Decorative forest clusters, drawn as individual trees rather than flat patches.
	for i in range(32):
		var a: float = float(i) * 2.39996
		var rad: float = 0.16 + float(i % 6) * 0.11
		var tree := center + Vector2(cos(a) * rx * rad, sin(a) * ry * rad)
		if tree.distance_to(center + Vector2(rx * 0.3, -ry * 0.34)) < rx * 0.27:
			continue
		board.draw_circle(tree + Vector2(1, 4), 7, Color("#213d35"))
		board.draw_circle(tree, 7, Color("#2a6048"))
		board.draw_circle(tree + Vector2(-2, -2), 4, Color("#6c9a68"))
	# Central stone citadel with a warm roof.
	var castle := center + Vector2(-rx * 0.08, ry * 0.04)
	board.draw_rect(Rect2(castle + Vector2(-20, -8), Vector2(40, 31)), Color("#263e47"))
	board.draw_rect(Rect2(castle + Vector2(-16, -13), Vector2(32, 30)), Color("#c3b59b"))
	board.draw_colored_polygon(PackedVector2Array([castle + Vector2(-24, -13), castle + Vector2(0, -31), castle + Vector2(24, -13)]), Color("#9e614c"))
	board.draw_rect(Rect2(castle + Vector2(-5, 0), Vector2(10, 17)), Color("#5a493b"))
	for side in [-1, 1]:
		var tower := castle + Vector2(float(side) * 25, -5)
		board.draw_rect(Rect2(tower + Vector2(-7, -17), Vector2(14, 31)), Color("#a8a79b"))
		board.draw_colored_polygon(PackedVector2Array([tower + Vector2(-10, -17), tower + Vector2(0, -31), tower + Vector2(10, -17)]), Color("#874d48"))
	# Carved tabletop path with a dark outline and brass rim.
	var points: Array[Vector2] = []
	for i in range(TILE_COUNT):
		var angle: float = -PI / 2.0 + TAU * float(i) / float(TILE_COUNT)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	for i in range(TILE_COUNT):
		var next: int = (i + 1) % TILE_COUNT
		board.draw_line(points[i], points[next], Color("#152b32"), 20, true)
		board.draw_line(points[i], points[next], Color("#c7a46d"), 14, true)
		board.draw_line(points[i], points[next], Color("#f4d99c"), 4, true)
	for i in range(TILE_COUNT):
		var kind: String = TYPES[i % TYPES.size()]
		var pos: Vector2 = points[i]
		board.draw_circle(pos + Vector2(2, 4), 17, Color("#0a1b22"))
		board.draw_circle(pos, 16, Color("#f5dca6"))
		board.draw_circle(pos, 12, COLORS[kind])
		board.draw_circle(pos + Vector2(-3, -4), 4, Color(1, 1, 1, 0.22))
		if kind == "boss":
			board.draw_arc(pos, 17, 0, TAU, 24, Color("#e5b6f3"), 3, true)
	for i in range(players.size()):
		var p: Dictionary = players[i]
		var pos: Vector2 = points[int(p.pos)] + Vector2(float(i % 3 - 1) * 12, -24 - float(int(i / 3)) * 12)
		board.draw_circle(pos + Vector2(2, 5), 11, Color("#101e27"))
		board.draw_circle(pos, 10, Color.from_hsv(float(i) / maxf(2.0, float(players.size())), 0.64, 0.95))
		board.draw_circle(pos + Vector2(-3, -3), 3, Color("#fff0d2"))
		if i == current:
			board.draw_arc(pos, 14, 0, TAU, 24, Color("#fff1a8"), 3, true)

func _save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"players":players, "current":current, "round":round_no, "phase":phase, "info":info}))

func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or not data.has("players"):
		return false
	players = data.players
	if players.is_empty():
		return false
	current = clampi(int(data.get("current", 0)), 0, players.size() - 1)
	round_no = int(data.get("round", 1))
	phase = str(data.get("phase", "roll"))
	info = str(data.get("info", "กลับสู่เกม"))
	return true
