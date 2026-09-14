# Tibia.spr 10.98 decoder — layout per OTClient SpriteManager::getSpriteImage:
# u32 signature, u32 count, count×u32 offsets (sprite id -> table[id-1], 0 = empty).
# Sprite data: 3B color key, u16 pixelDataSize, chunks [u16 transparent][u16 colored][3B RGB]*.
# 32x32 RGBA output, remainder padded transparent. No alpha channel in 10.98.
class_name BlackTekSpr
extends RefCounted

const SPRITE_PX := 32
const SPRITE_BYTES := 32 * 32 * 4
const CACHE_CAP := 1024

var signature := 0
var count := 0
var offsets := PackedInt32Array()
var tex_cache: Dictionary = {} # sprite_id -> ImageTexture
var _cache_order: Array = []
var _f: FileAccess = null
var _path := ""

func load(path: String) -> bool:
	_path = path
	_f = FileAccess.open(path, FileAccess.READ)
	if _f == null:
		push_error("BlackTekSpr: cannot open %s" % path)
		return false
	signature = _f.get_32()
	count = _f.get_32()
	print("BlackTekSpr: sig=%d count=%d" % [signature, count])
	if count <= 0 or count > 1000000:
		push_error("BlackTekSpr: bad count")
		return false
	offsets.resize(count)
	for i in range(count):
		offsets[i] = _f.get_32()
		if i % 50000 == 0:
			print("BlackTekSpr: table %d/%d" % [i, count])
	print("BlackTekSpr: table done")
	return true

func close() -> void:
	_f = null

func open_pixels(path: String) -> bool:
	_path = path
	_f = FileAccess.open(path, FileAccess.READ)
	return _f != null

# Cache: magic BTS1, u32 count, count×u32 offsets. Pixel data stays in Tibia.spr.
func load_cache(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_32() != 0x31535442: # "BTS1" LE
		return false
	count = f.get_32()
	if count <= 0 or count > 1000000:
		return false
	offsets.resize(count)
	for i in range(count):
		offsets[i] = f.get_32()
	f.close()
	print("BlackTekSpr: cache hit count=%d" % count)
	return true

func save_cache(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_32(0x31535442)
	f.store_32(count)
	for i in range(count):
		f.store_32(offsets[i])
	f.close()
	return true

func is_empty_id(sprite_id: int) -> bool:
	return sprite_id <= 0 or sprite_id > count or offsets[sprite_id - 1] == 0

func get_image(sprite_id: int) -> Image:
	var img := Image.create(SPRITE_PX, SPRITE_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if is_empty_id(sprite_id) or _f == null:
		return img
	_f.seek(offsets[sprite_id - 1])
	_f.get_8(); _f.get_8(); _f.get_8() # color key
	var data_size := _f.get_16()
	var px := PackedByteArray()
	px.resize(SPRITE_BYTES)
	var w := 0
	var read := 0
	while read < data_size and w < SPRITE_BYTES:
		var transparent := _f.get_16()
		var colored := _f.get_16()
		read += 4
		for _i in range(transparent):
			if w >= SPRITE_BYTES:
				break
			px[w + 3] = 0
			w += 4
		for _i in range(colored):
			if w >= SPRITE_BYTES or read + 3 > data_size:
				break
			px[w] = _f.get_8()
			px[w + 1] = _f.get_8()
			px[w + 2] = _f.get_8()
			px[w + 3] = 255
			w += 4
			read += 3
	img.set_data(SPRITE_PX, SPRITE_PX, false, Image.FORMAT_RGBA8, px)
	return img

func get_texture(sprite_id: int) -> Texture2D:
	if is_empty_id(sprite_id):
		return null
	if tex_cache.has(sprite_id):
		return tex_cache[sprite_id]
	var tex := ImageTexture.create_from_image(get_image(sprite_id))
	tex_cache[sprite_id] = tex
	_cache_order.append(sprite_id)
	if _cache_order.size() > CACHE_CAP:
		var drop: int = _cache_order.pop_front()
		tex_cache.erase(drop)
	return tex

func opaque_pixel_count(sprite_id: int) -> int:
	var img := get_image(sprite_id)
	var n := 0
	for y in range(SPRITE_PX):
		for x in range(SPRITE_PX):
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return n
