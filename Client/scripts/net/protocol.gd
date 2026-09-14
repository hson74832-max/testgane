# Minimal Tibia 10.98 framing helper for later real-server testing.
# Not used by the offline demo loop. Mirrors src/networkmessage.h framing:
# [len u16][checksum u32][encrypted len u16][XTEA payload, multiple of 8].
class_name BlackTekProtocol
extends RefCounted

const HEADER := 2
const CHECKSUM_LEN := 4
const XTEA_MULT := 8

var buf := PackedByteArray()
var pos := 8

static func adler32(data: PackedByteArray) -> int:
	var a := 1
	var b := 0
	for byte in data:
		a = (a + byte) % 65521
		b = (b + a) % 65521
	return (b << 16) | a

func get_u8() -> int:
	var v: int = buf[pos]
	pos += 1
	return v

func get_u16() -> int:
	var v: int = buf.decode_u16(pos)
	pos += 2
	return v

func get_string() -> String:
	var ln := get_u16()
	var s: String = buf.slice(pos, pos + ln).get_string_from_utf8()
	pos += ln
	return s

func add_u8(v: int) -> void:
	buf.append(v & 0xFF)

func add_u16(v: int) -> void:
	var o := buf.size()
	buf.resize(o + 2)
	buf.encode_u16(o, v & 0xFFFF)

func add_string(s: String) -> void:
	var b := s.to_utf8_buffer()
	add_u16(b.size())
	buf.append_array(b)
