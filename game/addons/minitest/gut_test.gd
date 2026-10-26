## GUT 互換の最小テスト基底クラス（GUT が導入できない環境向け）。
class_name GutTest
extends Node

var _failures: Array[String] = []
var _current := ""

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func _fail(msg: String) -> void:
	_failures.append("%s: %s" % [_current, msg])

func assert_eq(got, expected, msg := "") -> void:
	if typeof(got) != typeof(expected) or got != expected:
		_fail("expected %s, got %s %s" % [str(expected), str(got), msg])

func assert_ne(got, not_expected, msg := "") -> void:
	if typeof(got) == typeof(not_expected) and got == not_expected:
		_fail("expected not %s %s" % [str(not_expected), msg])

func assert_true(v, msg := "") -> void:
	if v != true:
		_fail("expected true %s" % msg)

func assert_false(v, msg := "") -> void:
	if v != false:
		_fail("expected false %s" % msg)

func assert_between(v, lo, hi, msg := "") -> void:
	if v < lo or v > hi:
		_fail("expected %s in [%s, %s] %s" % [str(v), str(lo), str(hi), msg])

func assert_almost_eq(v, expected, tol, msg := "") -> void:
	if absf(v - expected) > tol:
		_fail("expected %s±%s, got %s %s" % [str(expected), str(tol), str(v), msg])

func assert_has(container, item, msg := "") -> void:
	if not container.has(item):
		_fail("expected %s to contain %s %s" % [str(container), str(item), msg])

func assert_does_not_have(container, item, msg := "") -> void:
	if container.has(item):
		_fail("expected %s not to contain %s %s" % [str(container), str(item), msg])
