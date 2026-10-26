## 国際モールス（A–Z, 0–9）の符号化・復号。
## 文字の区切りは半角スペース1個、単語の区切りは " / "。
class_name Morse

const TABLE := {
	"A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.", "G": "--.",
	"H": "....", "I": "..", "J": ".---", "K": "-.-", "L": ".-..", "M": "--", "N": "-.",
	"O": "---", "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-", "U": "..-",
	"V": "...-", "W": ".--", "X": "-..-", "Y": "-.--", "Z": "--..",
	"0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
	"5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
}

static func encode(text: String) -> String:
	var words: Array[String] = []
	for word in text.to_upper().split(" ", false):
		var codes: Array[String] = []
		for ch in word:
			if TABLE.has(ch):
				codes.append(TABLE[ch])
		words.append(" ".join(codes))
	return " / ".join(words)

static func decode(code: String) -> String:
	var reverse := {}
	for k in TABLE:
		reverse[TABLE[k]] = k
	var words: Array[String] = []
	for word in code.split(" / ", false):
		var out := ""
		for sym in word.split(" ", false):
			out += reverse.get(sym, "?")
		words.append(out)
	return " ".join(words)
