# XTEA (Tibia 10.98) GDScript helper for later real-server testing.
# Mirrors src/xtea.h. Offline demo does not call this.
class_name BlackTekXtea
extends RefCounted

const DELTA := 0x9E3779B9
const ROUNDS := 32

static func decrypt_in_place(d: PackedByteArray, k: PackedInt32Array) -> void:
	assert(d.size() % 8 == 0, "XTEA needs 8-byte multiples")
	assert(k.size() == 4, "XTEA key is 4x u32")
	for off in range(0, d.size(), 8):
		var v0: int = d.decode_u32(off)
		var v1: int = d.decode_u32(off + 4)
		# Use 64-bit masking to emulate uint32 wrap-around.
		var s: int = (DELTA * ROUNDS) & 0xFFFFFFFF
		for _i in range(ROUNDS):
			v1 = (v1 - ((((v0 << 4) ^ (v0 >> 5)) + v0) ^ (s + k[(s >> 11) & 3]))) & 0xFFFFFFFF
			s = (s - DELTA) & 0xFFFFFFFF
			v0 = (v0 - ((((v1 << 4) ^ (v1 >> 5)) + v1) ^ (s + k[s & 3]))) & 0xFFFFFFFF
		d.encode_u32(off, v0)
		d.encode_u32(off + 4, v1)
