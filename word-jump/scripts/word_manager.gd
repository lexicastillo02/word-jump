extends Node

# Word database organized by difficulty
var words_by_length: Dictionary = {
	3: ["cat", "dog", "run", "jump", "fly", "top", "win", "sky", "box", "key"],
	4: ["jump", "word", "type", "fast", "game", "play", "code", "fire", "wave", "star"],
	5: ["climb", "tower", "speed", "score", "combo", "power", "pixel", "quest", "ninja", "cyber"],
	6: ["typing", "arcade", "button", "escape", "rocket", "bounce", "switch", "glitch", "turbo", "blazer"],
	7: ["jumping", "platform", "keyboard", "spelling", "climbing", "falling", "upgrade", "shields", "booster", "special"],
	8: ["skyscraper", "challenge", "adventure", "powerful", "obstacle", "vertical", "momentum", "accuracy", "champion", "ultimate"],
	9: ["precision", "ascending", "calculate", "dangerous", "excellent", "fantastic", "keyboards", "legendary", "motivated", "platforms"],
	10: ["incredible", "skyscraper", "adrenaline", "consistent", "determined", "everything", "fearlessly", "heightened", "impossible", "juggernaut"],
}

var current_word: String = ""
var typed_so_far: String = ""
var word_start_time: float = 0.0
var used_words: Array = []  # Track words currently in use to prevent duplicates

signal word_completed(word: String, time_taken: float, perfect: bool)
signal word_failed(word: String)
signal character_typed(char: String, correct: bool, position: int)
signal new_word_set(word: String)

func _ready():
	pass

func get_word_for_floor(floor_num: int) -> String:
	var min_length: int
	var max_length: int

	# Determine word length based on floor (difficulty scaling)
	if floor_num <= 10:
		min_length = 3
		max_length = 5
	elif floor_num <= 25:
		min_length = 4
		max_length = 7
	elif floor_num <= 50:
		min_length = 5
		max_length = 9
	elif floor_num <= 75:
		min_length = 6
		max_length = 10
	else:
		min_length = 7
		max_length = 10

	# Try to find a unique word
	var attempts = 0
	var max_attempts = 50

	while attempts < max_attempts:
		# Pick a random length within range
		var length = randi_range(min_length, max_length)
		length = clamp(length, 3, 10)

		# Get random word of that length
		if words_by_length.has(length):
			var word_list = words_by_length[length]
			var word = word_list[randi() % word_list.size()]

			# Check if word is not already in use
			if word not in used_words:
				used_words.append(word)
				return word

		attempts += 1

	# Fallback - generate a unique word by adding a number
	var base = "jump"
	var counter = 1
	while base + str(counter) in used_words:
		counter += 1
	var unique_word = base + str(counter)
	used_words.append(unique_word)
	return unique_word

func release_word(word: String):
	# Called when a platform is cleared/destroyed to free up the word
	used_words.erase(word)

func clear_all_words():
	# Reset for new game
	used_words.clear()

func set_new_word(floor_num: int):
	current_word = get_word_for_floor(floor_num)
	typed_so_far = ""
	word_start_time = Time.get_ticks_msec() / 1000.0
	emit_signal("new_word_set", current_word)

func set_current_word(word: String):
	# Set a specific word (used when platform already has a word)
	current_word = word
	typed_so_far = ""
	word_start_time = Time.get_ticks_msec() / 1000.0
	emit_signal("new_word_set", current_word)

func handle_key_input(event: InputEventKey):
	if event.pressed and current_word.length() > 0:
		var typed_char = char(event.unicode).to_lower()

		# Ignore non-letter characters
		if not typed_char.is_valid_identifier() or typed_char == "":
			return

		var expected_char = current_word[typed_so_far.length()].to_lower()
		var position = typed_so_far.length()

		if typed_char == expected_char:
			# Correct character
			typed_so_far += typed_char
			emit_signal("character_typed", typed_char, true, position)

			# Check if word is complete
			if typed_so_far.length() == current_word.length():
				var time_taken = (Time.get_ticks_msec() / 1000.0) - word_start_time
				emit_signal("word_completed", current_word, time_taken, true)
		else:
			# Wrong character
			emit_signal("character_typed", typed_char, false, position)
			emit_signal("word_failed", current_word)

func get_current_word() -> String:
	return current_word

func get_typed_progress() -> String:
	return typed_so_far

func get_remaining_chars() -> String:
	return current_word.substr(typed_so_far.length())

# Word Challenge Modes
enum ChallengeType { NORMAL, SCRAMBLED, BACKWARDS, MISSING_VOWELS }

func apply_challenge(word: String, challenge: ChallengeType) -> String:
	match challenge:
		ChallengeType.SCRAMBLED:
			return scramble_word(word)
		ChallengeType.BACKWARDS:
			return reverse_word(word)
		ChallengeType.MISSING_VOWELS:
			return remove_vowels(word)
		_:
			return word

func scramble_word(word: String) -> String:
	# Scramble middle characters, keep first and last
	if word.length() <= 3:
		return word

	var chars = Array(word.split(""))
	var middle = Array(chars.slice(1, chars.size() - 1))
	middle.shuffle()

	var result = chars[0]
	for c in middle:
		result += c
	result += chars[chars.size() - 1]
	return result

func reverse_word(word: String) -> String:
	var reversed = ""
	for i in range(word.length() - 1, -1, -1):
		reversed += word[i]
	return reversed

func remove_vowels(word: String) -> String:
	var vowels = ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]
	var result = ""
	for c in word:
		if c not in vowels:
			result += c
		else:
			result += "_"
	return result

func get_random_challenge(difficulty: int, floor_num: int) -> ChallengeType:
	# Easy: no challenges
	# Medium: occasional challenges after floor 10
	# Hard: frequent challenges after floor 5

	if difficulty == 0:  # Easy
		return ChallengeType.NORMAL
	elif difficulty == 1:  # Medium
		if floor_num < 10:
			return ChallengeType.NORMAL
		elif randf() < 0.3:  # 30% chance
			var challenges = [ChallengeType.SCRAMBLED, ChallengeType.BACKWARDS]
			return challenges[randi() % challenges.size()]
		else:
			return ChallengeType.NORMAL
	else:  # Hard
		if floor_num < 5:
			return ChallengeType.NORMAL
		elif randf() < 0.5:  # 50% chance
			var challenges = [ChallengeType.SCRAMBLED, ChallengeType.BACKWARDS, ChallengeType.MISSING_VOWELS]
			return challenges[randi() % challenges.size()]
		else:
			return ChallengeType.NORMAL
