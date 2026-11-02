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
	header = _label("REALM OF FORTUNE   •   FANTASY TABLETOP", 23, Color("#f8dda5"))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(header)
	board = Control.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 280)
	board.draw.connect(_draw_board)
	root.add_child(board)
	var hud := PanelContainer.new()
	root.add_child(hud)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	hud.add_child(column)
	stats = _label("", 17, Color("#f7e7c6"))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(stats)
	message = _label("", 15, Color("#d6e4e6"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	primary = _button("🎲 ทอยเต๋า", buttons, _primary_action)
	secondary = _button("🧭 ทางเลือก", buttons, _secondary_action)
	utility = _button("🧪 ใช้ยา", buttons, _use_potion)
	var footer := _label("REALM OF FORTUNE • GODOT MOBILE PROTOTYPE", 11, Color("#91b0b3"))
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
	button.custom_minimum_size = Vector2(0, 54)
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
	column.add_child(_label("ผู้เล่นแต่ละคนเลือกอาชีพในขั้นตอนถัดไป", 15, Color("#d6e4e6")))
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
		var hero: Dictionary = HEROES[selected_classes[i]]
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
	stats.text = "%s (%s)   ❤️ %d/%d   ⚔️ %d   🛡️ %d   🪙 %d   🏆 %d/3" % [p.name, HEROES[p["class"]].name, p.hp, p.max_hp, p.atk, p.def, p.gold, p.relics]
	message.text = info
	primary.text = "🎲 ทอยเต๋า" if phase == "roll" else ("➡️ เดินทางรอบนอก" if phase == "choice" else "⏭️ จบเทิร์น")
	secondary.text = "🧭 ทางลัด" if phase == "choice" else "📜 เป้าหมาย"
	utility.text = "🧪 ยา (%d)" % p.potions
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
	var kind: String = TYPES[p.pos % TYPES.size()]
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
			var attack := rng.randi_range(1, 6) + p.atk
			if attack >= monster:
				p.gold += 10 if boss else 4
				if boss:
					p.relics += 1
				result = "ชนะ%s! โจมตี %d ต่อ %d" % ["บอส" if boss else "ศัตรู", attack, monster]
			else:
				var damage := maxi(1, monster - p.def - 2)
				p.hp = maxi(0, p.hp - damage)
				result = "พ่ายแพ้ เสีย %d HP" % damage
	if p.hp <= 0:
		p.hp = p.max_hp
		p.gold = maxi(0, p.gold - 5)
		p.pos = 0
		result += " • กลับจุดเริ่มต้น"
	if p.relics >= 3:
		phase = "won"
		info = "%s ชนะเกม! 🏆" % p.name
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
	var w := board.size.x
	var h := board.size.y
	var center := Vector2(w * 0.5, h * 0.52)
	var rx := maxf(100, w * 0.39)
	var ry := maxf(90, h * 0.39)
	# A lightweight layered diorama illustration drawn by the engine.
	board.draw_rect(Rect2(Vector2.ZERO, board.size), Color("#183e4a"))
	board.draw_circle(center, minf(rx, ry) * 0.92, Color("#356f63"))
	board.draw_circle(center + Vector2(-rx * 0.52, -ry * 0.3), minf(rx, ry) * 0.43, Color("#527c5e"))
	board.draw_circle(center + Vector2(rx * 0.54, ry * 0.15), minf(rx, ry) * 0.34, Color("#b89b63"))
	board.draw_circle(center + Vector2(rx * 0.3, -ry * 0.4), minf(rx, ry) * 0.27, Color("#8e9eb3"))
	var points: Array[Vector2] = []
	for i in range(TILE_COUNT):
		var angle := -PI / 2.0 + TAU * float(i) / TILE_COUNT
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	for i in range(TILE_COUNT):
		board.draw_line(points[i], points[(i + 1) % TILE_COUNT], Color("#d7b97c"), 12, true)
		board.draw_line(points[i], points[(i + 1) % TILE_COUNT], Color("#75573b"), 3, true)
	for i in range(TILE_COUNT):
		var kind: String = TYPES[i % TYPES.size()]
		board.draw_circle(points[i] + Vector2(2, 4), 14, Color("#14252d"))
		board.draw_circle(points[i], 13, COLORS[kind])
		board.draw_arc(points[i], 13, 0, TAU, 20, Color("#f7e8bc"), 2, true)
	for i in range(players.size()):
		var p: Dictionary = players[i]
		var point := points[p.pos] + Vector2((i % 3 - 1) * 11, -21 - int(i / 3) * 11)
		board.draw_circle(point + Vector2(2, 3), 10, Color("#10232a"))
		board.draw_circle(point, 9, Color.from_hsv(float(i) / maxf(2, players.size()), 0.6, 1.0))
		if i == current:
			board.draw_arc(point, 12, 0, TAU, 24, Color("#fff2b7"), 3, true)

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
