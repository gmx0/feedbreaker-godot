extends Node2D
## The whole game is local: no social service, accounts, or online feed.

const POSTS := [
	{"by":"LOCAL / 00:00", "title":"A welcome post that won't let go", "copy":"One little tag. It doesn't know enough about you to do damage yet.", "tags":["mute"], "pace":0.0},
	{"by":"AUTOPLAY / 00:17", "title":"Somebody left the television on", "copy":"The same six seconds get louder every time the clip repeats.", "tags":["static","rewind"], "pace":5.5},
	{"by":"RECOMMENDED / 00:36", "title":"Your argument is trending", "copy":"Every reply is a mirror. Each mirror has room for one more reply.", "tags":["echo","rebuttal","sidetrack"], "pace":4.5},
	{"by":"THE ALGORITHM / 00:59", "title":"We found something just for you", "copy":"A recommendation system that knows you want to stop scrolling.", "tags":["predict","retention","unfollow"], "pace":3.8}
]
const BASE := Color("#141827")
const CARD := Color("#20263b")
const EDGE := Color("#3b4764")
const INK := Color("#f2eef8")
const SOFT := Color("#aab7d2")
const ACID := Color("#c9fa91")
const HOT := Color("#ff96ac")
const COOL := Color("#a9bcff")
const PANEL := Rect2(45,152,745,500)
const REACT := Rect2(818,372,237,63)
const RESET := Rect2(818,452,237,51)
const NEXT_DELAY := 0.65
const MAX_FOCUS := 8
var post := 0
var tag := 0
var typed := 0
var focus := MAX_FOCUS
var charges := 2
var pressure_left := 0.0
var frozen := 0.0
var next_left := 0.0
var state := "live"
var in_focus := true
var feedback := ""
var feedback_time := 0.0
var feedback_color := SOFT
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	reset()
	if OS.get_cmdline_user_args().has("--smoke"):
		call_deferred("smoke")

func reset() -> void:
	post = 0
	tag = 0
	typed = 0
	focus = MAX_FOCUS
	charges = 2
	pressure_left = 0.0
	frozen = 0.0
	next_left = 0.0
	state = "live"
	say("Type M to send the first letter.", COOL, 0.0)
	queue_redraw()

func current_word() -> String:
	return str(POSTS[post].tags[tag])

func say(message: String, tint: Color, seconds: float = 1.25) -> void:
	feedback = message
	feedback_color = tint
	feedback_time = seconds

func hurt(message: String) -> void:
	focus -= 1
	say(message, HOT)
	if focus <= 0:
		state = "lost"
		frozen = 0.0

func react() -> void:
	if state != "live" or not in_focus:
		return
	if post == 0:
		say("Save reactions for a hostile post.", COOL)
		return
	if charges == 0:
		say("No reactions left this run.", HOT)
		return
	if frozen > 0:
		say("The feed is already frozen.", COOL)
		return
	charges -= 1
	frozen = 4.0
	say("Freeze reaction: pressure paused for 4 seconds.", COOL)

func type_character(letter: String) -> void:
	var word := current_word()
	if letter != word.substr(typed,1):
		if post == 0:
			say("Wrong letter. Try " + word.substr(typed,1).to_upper() + " next.", HOT)
		else:
			hurt("Wrong letter: −1 focus. The matched letters stay.")
		return
	typed += 1
	say("Hit. Keep typing.", ACID)
	if typed < word.length():
		return
	typed = 0
	if tag + 1 < POSTS[post].tags.size():
		tag += 1
		say("Tag cleared. Next tag selected.", ACID)
		return
	if post == POSTS.size()-1:
		state = "won"
		frozen = 0.0
		say("Every hostile tag is gone.", ACID, 0.0)
	else:
		state = "between"
		frozen = 0.0
		next_left = NEXT_DELAY
		say("Post cleared. Loading the next card…", ACID, 0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		in_focus = false
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		in_focus = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		in_focus = true
		if RESET.has_point(event.position):
			reset()
		elif REACT.has_point(event.position):
			react()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.ctrl_pressed or event.meta_pressed or event.alt_pressed:
		return # No shortcut is a letter, including paste.
	if event.keycode == KEY_F2:
		reset()
		return
	if not in_focus or state != "live":
		return
	if event.keycode == KEY_SPACE:
		react()
	elif (event.unicode >= 65 and event.unicode <= 90) or (event.unicode >= 97 and event.unicode <= 122):
		type_character(String.chr(event.unicode).to_lower())

func _process(delta: float) -> void:
	if in_focus:
		if feedback_time > 0.0:
			feedback_time = maxf(0.0, feedback_time - delta)
		if state == "between":
			next_left -= delta
			if next_left <= 0.0:
				post += 1
				tag = 0
				state = "live"
				pressure_left = POSTS[post].pace
				say("Type the highlighted tag. Space freezes pressure.", COOL, 0.0)
		elif state == "live" and post > 0:
			var frozen_part := minf(delta, frozen)
			frozen -= frozen_part
			pressure_left -= delta - frozen_part
			while pressure_left <= 0.0 and state == "live":
				hurt("The feed got louder: −1 focus.")
				pressure_left += float(POSTS[post].pace)
	queue_redraw()

func label(at: Vector2, line: String, size: int, tint: Color = INK) -> void:
	draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func box(rect: Rect2, fill: Color = CARD, border: Color = EDGE) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 1.0)

func illustration() -> void:
	var r := Rect2(68,270,699,111)
	var themes := [Color("#292846"),Color("#252f51"),Color("#492b49"),Color("#32284d")]
	draw_rect(r, themes[post])
	for i in 30:
		var x := 73.0 + i * 23.5
		var wave := sin(i * (0.58 + post * 0.13)) * (13.0 + post * 2.0)
		var a := Vector2(x,326+wave)
		draw_line(a-Vector2(0,18),a+Vector2(0,18),COOL.darkened(0.42),2.0,true)
		if i % 3 == 0: draw_circle(a,5.0,ACID if post == 0 else HOT)
	for i in 3:
		draw_line(Vector2(68,285+i*41),Vector2(767,285+i*41),Color(0.9,0.86,1,0.09),1)
	draw_rect(r, EDGE, false, 1.0)
	label(Vector2(82,366), "SIGNAL / %02d" % (post+1), 14, INK)

func _draw() -> void:
	draw_rect(Rect2(0,0,1100,700), BASE)
	label(Vector2(45,36), "DEAD AIR NETWORK  /  OFFLINE SIMULATION", 16, ACID)
	label(Vector2(45,96), "Feedbreaker: Doomscrolling", 47)
	label(Vector2(45,127), "Type your way out of a feed that wants you to stay.", 19, SOFT)
	box(PANEL)
	var card: Dictionary = POSTS[post]
	label(Vector2(68,185), card.by, 15, COOL)
	label(Vector2(68,226), card.title, 30)
	label(Vector2(68,254), card.copy, 17, SOFT)
	illustration()
	label(Vector2(68,416), "HOSTILE TAGS", 14, SOFT)
	for i in card.tags.size():
		var rect := Rect2(68+i*231,430,217,39)
		var active: bool = i == tag and state == "live"
		var done: bool = i < tag or state in ["between","won"]
		box(rect, Color("#2e3c39") if active else BASE, ACID if active else EDGE)
		label(rect.position+Vector2(10,26), ("✓ " if done else "#") + str(card.tags[i]), 18, ACID if active or done else SOFT)
	label(Vector2(68,501), "COMMENT / EACH LETTER FIRES", 14, SOFT)
	if state == "live":
		var word := current_word()
		for i in word.length():
			var r := Rect2(69+i*48,514,42,49)
			var color := ACID if i < typed else COOL if i == typed else SOFT
			box(r, Color("#37504a") if i < typed else BASE, color if i <= typed else EDGE)
			label(r.position+Vector2(11,34), word.substr(i,1).to_upper(), 26, color)
	elif state == "between":
		label(Vector2(68,555), "POST CLEARED", 32, ACID)
	else:
		label(Vector2(68,555), "YOU BROKE THE FEED" if state == "won" else "THE FEED WON", 32, ACID if state == "won" else HOT)
	var visible_message := feedback_time > 0.0 or state != "live" or typed == 0
	var line := feedback if visible_message else "Keep typing the lit-up letter."
	var tint := feedback_color if visible_message else SOFT
	if not in_focus:
		line = "Paused. Click the game to resume typing."
		tint = COOL
	elif state == "lost":
		line = "Out of focus. Press F2 or click Restart run."
		tint = HOT
	label(Vector2(68,608), line, 19, tint)

	box(Rect2(818,152,237,189))
	label(Vector2(833,182), "POST %d / %d" % [post+1, POSTS.size()], 16, COOL)
	label(Vector2(833,225), "FOCUS   %d / %d" % [focus,MAX_FOCUS], 20, INK)
	for i in MAX_FOCUS:
		draw_rect(Rect2(833+i*26,239,20,12), ACID if i<focus else EDGE)
	var meter := "Practice: no pressure" if post == 0 else "Next drain: %.1fs" % maxf(0.0,pressure_left)
	if frozen > 0: meter = "Frozen: %.1fs" % frozen
	if state in ["between","won","lost"]: meter = "Feed paused"
	label(Vector2(833,294), meter, 17, HOT if post > 0 and frozen == 0 and state == "live" else SOFT)
	var ratio := pressure_left / maxf(1.0,float(card.pace))
	draw_rect(Rect2(833,308,207,5), EDGE)
	if state == "live" and post > 0:
		draw_rect(Rect2(833,308,207*clampf(ratio,0.0,1.0),5), COOL if frozen > 0 else HOT)

	box(REACT, Color("#303b60"), COOL)
	label(Vector2(833,399), "Freeze reaction  ·  %d" % charges, 19)
	label(Vector2(833,421), "SPACE or click", 14, COOL)
	box(RESET, CARD)
	label(Vector2(833,485), "Restart run  ·  F2", 18, SOFT)
	label(Vector2(818,553), "How to escape", 19, ACID)
	label(Vector2(818,584), "Clear all four posts before", 16, SOFT)
	label(Vector2(818,608), "your focus runs out.", 16, SOFT)
	label(Vector2(45,681), "Keyboard required for comments  •  Repeated keys and paste do not fire", 15, SOFT)

func event_key(code: Key, unicode_value: int = 0, echo := false, ctrl := false) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.keycode = code
	e.unicode = unicode_value
	e.echo = echo
	e.ctrl_pressed = ctrl
	get_viewport().push_input(e, true)

func click(at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	get_viewport().push_input(e, true)

func send_word(word: String) -> void:
	for c in word:
		event_key(KEY_NONE, c.unicode_at(0))

var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		push_error("FEEDBREAKER TEST: " + message)

func smoke() -> void:
	event_key(KEY_X, 120)
	check(typed == 0 and focus == 8 and feedback_color == HOT, "practice mistake is visible but free")
	event_key(KEY_M, 109, true)
	event_key(KEY_M, 109, false, true)
	check(typed == 0, "echo or Ctrl shortcut counted")
	_notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	event_key(KEY_M, 109)
	_process(20)
	check(typed == 0 and focus == 8, "defocus should not accept letters or time")
	click(Vector2(500,305))
	event_key(KEY_M, 77)
	check(typed == 1 and feedback_color == ACID, "first letter after refocus must work exactly once")
	send_word("ute")
	event_key(KEY_X, 120)
	click(REACT.get_center())
	check(state == "between" and charges == 2 and post == 0, "transition accepted combat input")
	event_key(KEY_F2)
	_process(NEXT_DELAY+0.1)
	check(post == 0 and state == "live" and tag == 0 and typed == 0 and charges == 2, "old transition survived restart")
	send_word("mute")
	_process(NEXT_DELAY+0.1)
	_process(0.1)
	check(post == 1 and tag == 0 and state == "live", "post advanced incorrectly")
	event_key(KEY_X, 120)
	check(focus == 7 and typed == 0, "actual mistake did not cost focus")
	event_key(KEY_SPACE)
	var pressure := pressure_left
	_process(3)
	click(REACT.get_center())
	check(is_equal_approx(pressure, pressure_left) and charges == 1 and frozen > 0, "freeze did not pause tick or spent twice")
	click(RESET.get_center())
	_process(8)
	check(frozen == 0.0 and focus == 8 and charges == 2 and post == 0, "click restart left freeze or damage")
	send_word("mute"); _process(1)
	_notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_process(100)
	check(focus == 8, "defocused hostile post dealt damage")
	_notification(NOTIFICATION_WM_WINDOW_FOCUS_IN)
	_process(60)
	check(state == "lost" and focus == 0, "timeout did not lose")
	send_word("static")
	check(tag == 0 and typed == 0, "loss still accepted a shot")
	event_key(KEY_F2)
	for p in POSTS.size():
		if p > 0: _process(1)
		for word in POSTS[p].tags: send_word(word)
	check(state == "won" and post == POSTS.size()-1 and focus == 8, "full playthrough did not win")
	_process(60)
	check(state == "won" and focus == 8, "won session still took damage")
	if fails == 0: print("FEEDBREAKER PASS: opening feedback, focus return, repeat and modifiers, transition, freeze, loss, restart and full win")
	get_tree().quit(0 if fails == 0 else 1)
