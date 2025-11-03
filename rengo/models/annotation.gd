class_name Annotation

var annotation_name: String = ""

## Unique list of notes for the annotation
var notes: Array[String] = []

func _init(p_annotation_name: String, p_notes: Array[String] = []) -> void:
	annotation_name = p_annotation_name
	notes = p_notes

func get_annotation_name() -> String:
	return annotation_name

func get_notes() -> Array[String]:
	return notes

func set_notes(p_notes: Array[String]) -> void:
	notes = p_notes

func add_note(p_note: String) -> void:
	if p_note in notes:
		return
	notes.append(p_note)

func remove_note(p_note: String) -> void:
	if not p_note in notes:
		return
	notes.erase(p_note)

func clear_notes() -> void:
	notes.clear()
