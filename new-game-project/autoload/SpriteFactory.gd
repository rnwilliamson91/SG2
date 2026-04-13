extends Node
## Builds SpriteFrames from Kenney ShoeBox XML atlases next to a shared texture.

const DEFAULT_ATLAS_XML := "res://Assets/kenney_top-down-shooter/Spritesheet/spritesheet_characters.xml"


func get_sprite_frames(character_prefix: String, atlas_xml_path: String = DEFAULT_ATLAS_XML) -> SpriteFrames:
	var normalized_prefix := character_prefix if character_prefix.ends_with("_") else character_prefix + "_"

	var atlas_tex: Texture2D = _load_atlas_texture(atlas_xml_path)
	if atlas_tex == null:
		return SpriteFrames.new()

	var matches: Array[Dictionary] = _parse_matching_subtextures(atlas_xml_path, normalized_prefix)
	if matches.is_empty():
		push_warning("SpriteFactory: no SubTexture entries for prefix '%s' in %s" % [normalized_prefix, atlas_xml_path])
		return SpriteFrames.new()

	var frames := SpriteFrames.new()

	for m in matches:
		var anim_name: String = m["anim"]
		var region: Rect2 = m["region"]

		if not frames.has_animation(anim_name):
			frames.add_animation(anim_name)

		var at := AtlasTexture.new()
		at.atlas = atlas_tex
		at.region = region
		frames.add_frame(anim_name, at)

	return frames


func _load_atlas_texture(xml_path: String) -> Texture2D:
	var image_path_attr := _read_texture_atlas_image_path(xml_path)
	var resolved := _resolve_atlas_png_path(xml_path, image_path_attr)

	if not ResourceLoader.exists(resolved):
		push_error("SpriteFactory: atlas texture not found: %s" % resolved)
		return null

	var tex: Texture2D = load(resolved)
	return tex


func _read_texture_atlas_image_path(xml_path: String) -> String:
	var parser := XMLParser.new()
	if parser.open(xml_path) != OK:
		push_error("SpriteFactory: could not open XML: %s" % xml_path)
		return ""

	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if String(parser.get_node_name()) != "TextureAtlas":
			continue
		for i in range(parser.get_attribute_count()):
			if String(parser.get_attribute_name(i)) == "imagePath":
				return String(parser.get_attribute_value(i))
	return ""


func _resolve_atlas_png_path(xml_path: String, image_path_from_xml: String) -> String:
	var base_dir := xml_path.get_base_dir()
	if not image_path_from_xml.is_empty():
		var candidate := base_dir.path_join(image_path_from_xml.get_file())
		if ResourceLoader.exists(candidate):
			return candidate
	var stem_png := xml_path.get_file().get_basename() + ".png"
	return base_dir.path_join(stem_png)


func _parse_matching_subtextures(xml_path: String, normalized_prefix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var parser := XMLParser.new()
	if parser.open(xml_path) != OK:
		push_error("SpriteFactory: could not open XML: %s" % xml_path)
		return out

	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if String(parser.get_node_name()) != "SubTexture":
			continue

		var raw_name := ""
		var x := 0
		var y := 0
		var w := 0
		var h := 0
		for i in range(parser.get_attribute_count()):
			var an := String(parser.get_attribute_name(i))
			var av := String(parser.get_attribute_value(i))
			match an:
				"name":
					raw_name = av
				"x":
					x = int(av)
				"y":
					y = int(av)
				"width":
					w = int(av)
				"height":
					h = int(av)

		if raw_name.is_empty():
			continue
		var base_stem := raw_name.get_basename()
		if not base_stem.begins_with(normalized_prefix):
			continue

		var anim_name := base_stem.trim_prefix(normalized_prefix)
		if anim_name.is_empty():
			continue

		out.append({
			"anim": anim_name,
			"region": Rect2(float(x), float(y), float(w), float(h)),
		})

	return out
