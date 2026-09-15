# Binary min-heap priority queue (tiles keyed by float cost).
# Used by Dijkstra click-routing: replaces the O(n) open-list scan, giving
# O(log n) push/pop. Stale entries are skipped by the caller via its closed
# set, so no decrease-key is needed — just push the better cost.
class_name BlackTekHeap
extends RefCounted

var _h: Array = [] # each [cost: float, tile: Vector2i]

func empty() -> bool:
	return _h.is_empty()

func size() -> int:
	return _h.size()

func push(cost: float, tile: Vector2i) -> void:
	_h.append([cost, tile])
	var i := _h.size() - 1
	while i > 0:
		var parent := (i - 1) >> 1
		if float(_h[parent][0]) <= float(_h[i][0]):
			break
		var tmp: Array = _h[parent]
		_h[parent] = _h[i]
		_h[i] = tmp
		i = parent

# Pops the minimum entry. Caller must check empty() first; stale entries
# (worse cost than the caller's best-known) are the caller's to skip.
func pop() -> Vector2i:
	var top: Vector2i = _h[0][1]
	var last: Array = _h.pop_back()
	if not _h.is_empty():
		_h[0] = last
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < _h.size() and float(_h[l][0]) < float(_h[m][0]):
				m = l
			if r < _h.size() and float(_h[r][0]) < float(_h[m][0]):
				m = r
			if m == i:
				break
			var tmp2: Array = _h[m]
			_h[m] = _h[i]
			_h[i] = tmp2
			i = m
	return top
