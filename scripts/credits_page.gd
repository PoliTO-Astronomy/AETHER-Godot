extends Panel

const AETHER_THEME = preload("res://scripts/aether_theme.gd")
const LICENSES = preload("res://scripts/credits_licenses.gd")

var content: RichTextLabel

var contributor_text := ""
var language := "it"
var section := 0

func _ready() -> void:
	content = $CreditsContent
	contributor_text = content.text
	for index in range($Navigation.get_child_count()):
		$Navigation.get_child(index).pressed.connect(_select_section.bind(index))
	$ButtonIta.pressed.connect(_set_language.bind("it"))
	$ButtonEng.pressed.connect(_set_language.bind("en"))
	content.meta_clicked.connect(func(url: Variant): OS.shell_open(str(url)))
	_set_language("it")

func _set_language(value: String) -> void:
	language = value
	var italian := language == "it"
	$Version.text = ("Versione %s  •  Godot %s" if italian else "Version %s  •  Godot %s") % [ProjectSettings.get_setting("application/config/version", ""), Engine.get_version_info()["string"]]
	$ButtonIta.set_pressed_no_signal(italian)
	$ButtonEng.set_pressed_no_signal(not italian)
	$ButtonIta.disabled = italian
	$ButtonEng.disabled = not italian
	var names := ["Contributori", "Licenza AETHER", "Licenza Godot", "Terze parti"] if italian else ["Contributors", "AETHER License", "Godot License", "Third-party notices"]
	for index in range(names.size()):
		$Navigation.get_child(index).text = names[index]
	_select_section(section)

func _contributor_content() -> String:
	var text := contributor_text.replace("nelle schede sopra", "nelle sezioni a sinistra")
	text += "\n\n[font_size=20][color=#45b8cf]Calendario[/color][/font_size]\nCalendar Button — Ivan P. Skodje\n[url=https://github.com/ivanskodje-godotengine/godot-plugin-calendar-button]Repository originale[/url] • MIT\nAdattato per AETHER e Godot 4. Testo della licenza nella sezione Terze parti.\n"
	if language == "it":
		return text
	var translations := {
		"Strumento per simulare e visualizzare le traiettorie delle polveri emesse dai getti cometari.": "A tool for simulating and visualizing dust trajectories emitted by cometary jets.",
		"Calendario": "Calendar", "Repository originale": "Original repository",
		"Adattato per AETHER e Godot 4. Testo della licenza nella sezione Terze parti.": "Adapted for AETHER and Godot 4. License text in the Third-party notices section.",
		"Supervisione": "Supervision", "Sviluppo AETHER": "AETHER Development",
		"Effemeridi": "Ephemerides", "Motore grafico": "Graphics engine", "Licenze": "Licenses",
		"Il repository AETHER contiene la GNU General Public License, versione 3.": "The AETHER repository includes the GNU General Public License, version 3.",
		"Le licenze di Godot e dei suoi componenti sono disponibili nelle sezioni a sinistra.": "The licenses for Godot and its components are available in the sections on the left."
	}
	for original in translations:
		text = text.replace(original, translations[original])
	return text

func _select_section(index: int) -> void:
	section = index
	for button_index in range($Navigation.get_child_count()):
		$Navigation.get_child(button_index).disabled = button_index == index
	match index:
		0:
			content.bbcode_enabled = true
			content.text = _contributor_content()
		1:
			content.bbcode_enabled = false
			content.text = LICENSES.AETHER
		2:
			content.bbcode_enabled = false
			content.text = Engine.get_license_text()
		3:
			content.bbcode_enabled = false
			var text := "Godot — attribuzioni e copyright dei componenti inclusi\n\n" if language == "it" else "Godot — attribution and copyright of bundled components\n\n"
			var calendar_notice := "Adattato per AETHER e Godot 4. Licenza originale MIT, conservata integralmente.\n\n" if language == "it" else "Adapted for AETHER and Godot 4. Original MIT license reproduced in full.\n\n"
			text = "Calendar Button — Ivan P. Skodje\nhttps://github.com/ivanskodje-godotengine/godot-plugin-calendar-button\n" + calendar_notice + LICENSES.CALENDAR + "\n\n" + text
			for component in Engine.get_copyright_info():
				text += str(component["name"]) + "\n"
				for part in component["parts"]:
					for copyright_line in part["copyright"]:
						text += str(copyright_line) + "\n"
					text += ("Licenza: " if language == "it" else "License: ") + str(part["license"]) + "\n\n"
			text += "TESTI DELLE LICENZE\n\n" if language == "it" else "LICENSE TEXTS\n\n"
			var licenses := Engine.get_license_info()
			for license_name in licenses:
				text += str(license_name) + "\n\n" + str(licenses[license_name]) + "\n\n"
			content.text = text
	content.scroll_to_line(0)
