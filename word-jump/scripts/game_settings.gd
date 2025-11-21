extends Node

# Global game settings (autoload singleton)
enum Difficulty { EASY, MEDIUM, HARD }
var selected_difficulty: Difficulty = Difficulty.MEDIUM
