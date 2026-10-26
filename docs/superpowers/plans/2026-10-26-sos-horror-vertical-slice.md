# 街灯のSOS 縦切り試作（序章＋第1章）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 序章と第1章を通して遊べる試作を作り、「点滅に気づく瞬間が怖いか」を確かめられる状態にする。

**Architecture:** Godot 4 のプロジェクトを `game/` に作る。信号（モールス・打ち癖）、進行の記録、エンディング判定、セーブはシーンに依存しない純粋なスクリプトとして作り、GUT で自動テストする。街灯・ラジオ・手帳・会話はその上に乗るシーン部品にする。3D素材は Blender の Python スクリプトで生成し、glTF で取り込む。

**Tech Stack:** Godot 4.3 以上（GDScript）、GUT 9.x（Godot 用テストツール）、Blender 4.x（Python / bpy）、glTF 2.0

**Spec:** `docs/superpowers/specs/2026-10-26-sos-horror-game-design.md`

この計画の範囲は設計書「10. 作る順番」の 1（縦切り試作）だけ。第2章以降、`PhoneFeed`、`Pursuer`、聞き比べ、和文モールスは後続の計画で扱う。

## Global Constraints

- エンジン：Godot 4.3 以上の 4.x。言語は GDScript のみ。
- 画面に出る文字はすべて翻訳キー（`tr()`）経由。コードやシーンに日本語・英語の文字列を直接書かない。翻訳表は `game/i18n/strings.csv`（列：`keys,ja,en`）。
- 信号・会話・演出のトリガーはデータ（JSON）で持ち、コードを変えずに調整できること。
- 戦闘なし。第1章までに追跡する敵は出さない。驚かせる演出は第1章で1〜2回まで。
- 主役の見た目（街灯、島の景観）に AI 生成素材を使わない。
- 性的な描写・直接的な暴力描写を入れない。
- 物語を進める信号は手帳が自動で文字にする。`hidden: true` の信号は自動で訳さない。
- エンディング判定の順序：⑤打ち明け話 → ④次の点滅 → ③ひとりの帰還 → ①真相 → ②名前のない人。遺品は全5個。

## Review Focus

1. **点滅中のセーブと読み込み** — 読み込み後、街灯は点きっぱなし・消えっぱなしにならず、周期の最初から点滅を再開する。（Task 4 にテスト追加）
2. **セーブファイルが壊れている・ない・古い版** — クラッシュせず新規開始し、警告をログに出す。（Task 4 にテスト追加）
3. **フレームレートの低下や一時停止中の信号** — 10fps でも符号の順番は崩れず、一時停止中は信号も止まる。（Task 6 にテスト追加）
4. **遊んでいる途中の言語切り替え** — 手帳の記録は翻訳キーで保存されているので、切り替え後は新しい言語で表示される。（Task 7 にテスト追加）
5. **点滅を最後まで見ずに目をそらす** — 1周期の95%以上見続けないと記録されない。途中で離れたら記録されない。（Task 7 にテスト追加）

---

## ファイル構成

```
game/
  project.godot
  addons/gut/                     # GUT 9.x（Task 1 で導入）
  i18n/strings.csv                # 翻訳表
  data/
    signals.json                  # 信号の定義
    dialogue/ch0.json, ch1.json   # 会話
    scares.json                   # 演出のトリガー
  scripts/
    signal/morse.gd               # 符号化・復号（純粋関数）
    signal/fist.gd                # 打ち癖（Resource）と時刻列の生成
    signal/signal_def.gd          # 信号定義の読み込み
    state/game_state.gd           # 進行の記録（autoload: GameState）
    state/ending_resolver.gd      # エンディング判定（純粋関数）
    state/save_system.gd          # セーブ（autoload: SaveSystem）
    world/signal_source.gd        # 街灯・ラジオ共通の発信元
    world/streetlight.gd
    world/radio.gd
    world/flicker.gd              # 壊れかけの街灯の不規則な点滅
    player/player.gd              # 一人称操作
    player/interactor.gd          # 調べる
    player/signal_observer.gd     # 見ている信号の判定
    ui/notebook.gd, notebook.tscn # 信号手帳
    dialogue/dialogue_runner.gd   # 会話の進行
    ui/dialogue_box.gd, .tscn
    story/scare_director.gd
    story/chapter_flow.gd         # 序章→第1章の目標と自動セーブ
  scenes/
    island_slice.tscn             # 港・通り・家・資料館の簡易マップ
    home_interior.tscn
    museum.tscn
  assets/models/                  # Blender から書き出した .glb
  tools/blender/                  # 素材生成スクリプト
  tests/                          # GUT テスト（test_*.gd）
```

テストの実行コマンド（以下「テストコマンド」）：

```bash
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

---

### Task 1: プロジェクトの土台とモールスの符号化・復号

**Files:**
- Create: `game/project.godot`, `game/addons/gut/`（GUT 9.x を配置）, `game/i18n/strings.csv`, `game/scripts/signal/morse.gd`
- Test: `game/tests/signal/test_morse.gd`

**Interfaces:**
- Produces: `Morse.encode(text: String) -> String`（例 `"SOS"` → `"... --- ..."`。文字の区切りは半角スペース1個、単語の区切りは ` / `）、`Morse.decode(code: String) -> String`（逆変換。表にない符号は `"?"`）。`class_name Morse`、静的関数のみ。対応は国際モールスの A–Z と 0–9。小文字は大文字として扱う。

- [ ] **Step 1: Godot プロジェクトを作り、GUT 9.x を `game/addons/gut/` に入れて有効化する。`strings.csv` に `keys,ja,en` の見出しと `ui_title,街灯のSOS,Streetlight SOS` の1行を入れ、Project Settings の翻訳に登録する**
- [ ] **Step 2: 失敗するテストを書く**

```gdscript
extends GutTest
func test_encode_sos(): assert_eq(Morse.encode("SOS"), "... --- ...")
func test_encode_words(): assert_eq(Morse.encode("hi you"), ".... .. / -.-- --- ..-")
func test_decode_roundtrip(): assert_eq(Morse.decode(Morse.encode("HELP 42")), "HELP 42")
func test_decode_unknown(): assert_eq(Morse.decode("...... ..."), "?S")
```

- [ ] **Step 3: テストコマンドを実行し、`Morse` が未定義で失敗することを確認する**
- [ ] **Step 4: `game/scripts/signal/morse.gd` に `Morse` を実装する**
- [ ] **Step 5: テストコマンドを実行し、すべて PASS を確認する**
- [ ] **Step 6: コミット** `git add game && git commit -m "feat: Godot project scaffold and Morse encode/decode"`

---

### Task 2: 打ち癖と時刻列の生成

**Files:**
- Create: `game/scripts/signal/fist.gd`
- Test: `game/tests/signal/test_fist.gd`

**Interfaces:**
- Consumes: `Morse.encode`
- Produces: `class_name Fist extends Resource`。プロパティ：`unit_ms: float`（点の長さ）、`dash_ratio: float`（線÷点）、`char_gap: float`（文字間の消灯、単位数）、`word_gap: float`（語間の消灯、単位数）、`jitter: float`（揺らぎ、標準偏差の割合）。
  - `func timeline(text: String, seed: int) -> PackedInt32Array` — 点灯から始まり、点灯・消灯を交互に並べたミリ秒の列。符号内の間は1単位、各長さに `(1 + jitter * g)` を掛ける（`g` は `RandomNumberGenerator`（`seed` 固定）の `randfn(0,1)` を [-2, 2] に収めた値）。最短 30ms。
  - `func distance(other: Fist) -> float` — `|Δunit_ms|/200 + |Δdash_ratio|/3 + |Δchar_gap|/3 + |Δword_gap|/7 + |Δjitter|/0.1`
  - 静的プリセット：`Fist.daughter_a()`（220, 3.6, 3.4, 7.5, 0.12）、`Fist.captive_b()`（220, 3.3, 3.4, 7.5, 0.10）、`Fist.trap()`（200, 3.0, 3.0, 7.0, 0.0）

- [ ] **Step 1: 失敗するテストを書く**

```gdscript
extends GutTest
func test_trap_sos_exact():
	var t := Fist.trap().timeline("E", 1)
	assert_eq(Array(t), [200])
func test_starts_on_and_alternates():
	var t := Fist.trap().timeline("SOS", 1)
	assert_eq(t.size(), 17)            # 9 点灯 + 8 消灯
	assert_eq(t[0], 200); assert_eq(t[1], 200); assert_eq(t[5], 600)  # 文字間
func test_deterministic_with_seed():
	assert_eq(Fist.daughter_a().timeline("SOS", 7), Fist.daughter_a().timeline("SOS", 7))
func test_jitter_changes_lengths():
	assert_ne(Fist.daughter_a().timeline("SOS", 7), Fist.daughter_a().timeline("SOS", 8))
func test_min_duration():
	var f := Fist.daughter_a(); f.jitter = 5.0
	for ms in f.timeline("SOS", 3): assert_true(ms >= 30)
func test_a_vs_b_is_subtle():
	var d := Fist.daughter_a().distance(Fist.captive_b())
	assert_between(d, 0.1, 0.5)
func test_a_vs_trap_is_clear():
	assert_true(Fist.daughter_a().distance(Fist.trap()) >= 1.0)
```

- [ ] **Step 2: テストコマンドで失敗を確認する**
- [ ] **Step 3: `fist.gd` を実装する**
- [ ] **Step 4: テストコマンドで PASS を確認する**
- [ ] **Step 5: コミット** `git commit -m "feat: fist parameters and timeline generation"`

---

### Task 3: 信号定義の読み込み

**Files:**
- Create: `game/scripts/signal/signal_def.gd`, `game/data/signals.json`
- Test: `game/tests/signal/test_signal_def.gd`

**Interfaces:**
- Consumes: `Fist`
- Produces: `class_name SignalDef extends RefCounted`。フィールド：`id: StringName`、`text: String`（モールス化する文字列）、`fist: Fist`、`hidden: bool`、`label_key: String`（手帳の見出しの翻訳キー）、`loop_pause_ms: int`（周期の間の休み）。
  - `static func load_all(path: String) -> Dictionary`（`id` → `SignalDef`）。`fist` は `"daughter_a" | "captive_b" | "trap"` のプリセット名か、5つの数値を持つオブジェクト。
  - `func cycle_ms(seed: int) -> int` — `timeline` の合計＋`loop_pause_ms`。
- `signals.json` の縦切り分：`sos_a`（"SOS", daughter_a, hidden=false, loop_pause_ms=4000）、`museum_hi`（"HI", trap, hidden=false, 1500）、`oldman_nigero`（"NIGERO", captive_b, hidden=true, 3000）※第2章で使うが定義の形式確認のため入れる。

- [ ] **Step 1: 失敗するテスト** — `load_all("res://data/signals.json")` で3件読めること、`sos_a.fist.distance(Fist.daughter_a()) == 0.0`、`oldman_nigero.hidden == true`、テスト用 JSON に存在しない fist 名の定義を1件混ぜると、その定義だけスキップされ残りが返ること（スキップ時は `push_warning` を出す）、`cycle_ms` が `timeline` 合計＋休みと一致すること。
- [ ] **Step 2: 失敗を確認**
- [ ] **Step 3: 実装と `signals.json` 作成**
- [ ] **Step 4: PASS を確認**
- [ ] **Step 5: コミット** `git commit -m "feat: data-driven signal definitions"`

---

### Task 4: 進行の記録・エンディング判定・セーブ

**Files:**
- Create: `game/scripts/state/game_state.gd`, `game/scripts/state/ending_resolver.gd`, `game/scripts/state/save_system.gd`
- Test: `game/tests/state/test_ending_resolver.gd`, `game/tests/state/test_save_system.gd`

**Interfaces:**
- Produces:
  - `GameState`（autoload）：`chapter: int`、`told_wife: bool`、`followed_signal: StringName`（`&""`/`&"real"`/`&"trap"`）、`relics: int`、`old_man_alive: bool = true`、`found_daughter: bool`、`flags: Dictionary`（会話用の自由なフラグ）、`notebook: Array[Dictionary]`（`{"signal_id": StringName, "label_key": String, "decoded": bool}`）、`signal_phase: Dictionary`（`signal_id` → 周期内の経過 ms）。`func to_dict() -> Dictionary`、`func from_dict(d: Dictionary) -> void`、`func reset() -> void`。シグナル `changed`。
  - `EndingResolver.resolve(s: GameState) -> StringName` — 戻り値 `&"confession"`(⑤) `&"next_blink"`(④) `&"alone"`(③) `&"truth"`(①) `&"nameless"`(②)。順序は Global Constraints のとおり。①は `found_daughter and relics == 5 and old_man_alive`。
  - `SaveSystem`（autoload）：`func save(slot: int) -> bool`、`func load(slot: int) -> bool`、`func has_save(slot: int) -> bool`。保存先 `user://save_%d.json`、中身は `{"version": 1, "state": GameState.to_dict()}`。

- [ ] **Step 1: エンディング判定の失敗するテストを書く** — 5種それぞれの条件、および優先順の衝突ケース（`told_wife=true` かつ ①条件 → `confession`、`followed_signal=trap` かつ `found_daughter=true` → `next_blink`、`relics=4` で他が①条件 → `nameless`、`old_man_alive=false` で他が①条件 → `nameless`）。
- [ ] **Step 2: セーブの失敗するテストを書く** — 保存→`reset()`→読み込みで全フィールドが戻ること。**Review Focus 1**：`signal_phase` は保存されるが、読み込み後は全信号の位相が 0（周期の最初）になること。**Review Focus 2**：壊れた JSON、ファイルなし、`version: 0` のそれぞれで `load()` が `false` を返し、`GameState` が初期値のままで、警告（`push_warning`）が出ること。
- [ ] **Step 3: テストコマンドで失敗を確認**
- [ ] **Step 4: 3ファイルを実装し、`project.godot` に autoload（`GameState`, `SaveSystem`）を登録する**
- [ ] **Step 5: PASS を確認**
- [ ] **Step 6: コミット** `git commit -m "feat: game state, ending resolver and save system"`

---

### Task 5: Blender で街灯・電柱・家の素材を作る

**Files:**
- Create: `game/tools/blender/build_streetlight.py`, `game/tools/blender/build_pole.py`, `game/tools/blender/build_house_kit.py`, `game/tools/blender/common.py`
- Output: `game/assets/models/streetlight.glb`, `pole.glb`, `house_kit.glb`
- Test: `game/tests/assets/test_models.gd`

**Interfaces:**
- Produces（ノード名の約束。後続タスクがこの名前で探す）：
  - `streetlight.glb`：ルート直下に `Pole`（メッシュ）、`LampHead`（メッシュ、マテリアル名 `lamp_emit`）、空ノード `LightAnchor`（光源を置く位置、地面から 4.5m）。
  - `pole.glb`：`Pole`、`CrossArm`、`WireAnchor_L`、`WireAnchor_R`。
  - `house_kit.glb`：`Wall_2m`、`Wall_Window_2m`、`Door_Frame`、`Floor_2m`、`Roof_Tile_2m`（2m グリッドで組める部品）。
- 実行方法：`blender -b -P game/tools/blender/build_streetlight.py -- --out game/assets/models/streetlight.glb`（ほかも同じ形）。

- [ ] **Step 1: 失敗するテストを書く** — 3つの `.glb` を `load()` してインスタンス化し、上記ノード名がすべて存在すること、`LightAnchor` の高さが 4.5±0.05m であること、`LampHead` のマテリアル名が `lamp_emit` であること。
- [ ] **Step 2: テストコマンドで失敗を確認（ファイルなし）**
- [ ] **Step 3: `common.py` に共通処理（シーン初期化、引数 `--out` の解析、glTF 書き出し `export_format='GLB'`、+Y up）を書き、3つの生成スクリプトを実装する。昭和の炭鉱町らしく、街灯はコンクリート柱に笠付きの灯具、家は板張りの外壁とトタン屋根**
- [ ] **Step 4: 3つのスクリプトを実行して `.glb` を書き出し、Godot で一度開いて取り込み（`.import`）を作る**
- [ ] **Step 5: テストコマンドで PASS を確認**
- [ ] **Step 6: コミット** `git commit -m "feat: Blender-generated streetlight, pole and house kit"`

---

### Task 6: 信号の発信元（街灯・壊れた街灯・ラジオ）

**Files:**
- Create: `game/scripts/world/signal_source.gd`, `streetlight.gd`, `flicker.gd`, `radio.gd`, `game/scenes/parts/streetlight.tscn`, `radio.tscn`
- Test: `game/tests/world/test_signal_source.gd`, `test_flicker.gd`

**Interfaces:**
- Consumes: `SignalDef`, `GameState.signal_phase`, `streetlight.glb` のノード名
- Produces:
  - `class_name SignalSource extends Node3D`：`@export var signal_id: StringName`、`@export var seed: int`、`var is_on: bool`、`func advance(delta_ms: int) -> void`（経過時間を進め `is_on` を更新。1回の呼び出しで複数の区間をまたいでも正しく進める）、シグナル `cycle_completed(signal_id: StringName)`、`func cycle_length_ms() -> int`。`_process` は `advance(int(delta * 1000))` を呼ぶだけ。一時停止中（`get_tree().paused`）は進まない（`process_mode = PAUSABLE`）。
  - `Streetlight extends SignalSource`：`is_on` に合わせて `OmniLight3D`（`LightAnchor` の位置）と `lamp_emit` の発光を切り替える。`signal_id` が空なら常時点灯。
  - `Flicker extends Node`：同じ街灯に付けると `SignalSource` の代わりに不規則に点滅させる。`func pattern(seed: int, length_ms: int) -> PackedInt32Array`。
  - `Radio extends SignalSource`：`var tuned_freq: float`（76.0〜95.0）、`@export var station_freq: float = 81.7`、`func reception() -> float`（`station_freq` から ±0.3 で 1.0、±1.5 で 0.0、間は直線）。点灯の代わりに 600Hz のビープ（`AudioStreamGenerator`）を `reception()` の音量で鳴らし、雑音を `1 - reception()` で重ねる。

- [ ] **Step 1: 失敗するテストを書く**
  - `advance` を区間の境目ちょうど・またぎで呼び、`is_on` の列が `timeline` と一致すること。
  - 1周で `cycle_completed` が1回だけ出ること。
  - **Review Focus 3**：`delta` を 100ms（10fps 相当）刻みで進めても、状態が切り替わった順序を記録した列が、`timeline` を 100ms 単位で見た列と一致し、点灯の回数が欠けないこと（`timeline` の最短区間は 100ms 以上のプリセットで確認）。一時停止中は `_process` で進まないこと。
  - `Flicker.pattern` が `seed` ごとに決まった列を返し、`Morse.decode` しても `"SOS"` を含まないこと（seed 0〜99 で確認）。
  - `Radio.reception()` が 81.7→1.0、82.0→1.0、83.2→0.0、82.6→0.5（±0.01）であること。
- [ ] **Step 2: 失敗を確認**
- [ ] **Step 3: 実装（`Flicker.pattern` から `Morse.decode` するには、区間を 200ms 単位で点・線に見立てて文字列化するテスト用のヘルパーをテスト側に置く）**
- [ ] **Step 4: PASS を確認**
- [ ] **Step 5: コミット** `git commit -m "feat: signal sources for streetlight, flicker and radio"`

---

### Task 7: 信号の観察と信号手帳

**Files:**
- Create: `game/scripts/player/signal_observer.gd`, `game/scripts/ui/notebook.gd`, `game/scripts/ui/notebook.tscn`
- Modify: `game/i18n/strings.csv`（手帳の見出し・UI 文言のキーを追加）
- Test: `game/tests/ui/test_notebook.gd`, `game/tests/player/test_signal_observer.gd`

**Interfaces:**
- Consumes: `SignalSource.cycle_completed`, `SignalDef`, `GameState.notebook`
- Produces:
  - `SignalObserver extends Node`（プレイヤーの子）：`@export var max_distance: float = 40.0`、`@export var view_angle_deg: float = 25.0`。毎フレーム、視界内（画面中心から `view_angle_deg` 以内、`max_distance` 以内、遮蔽物なし）にある `SignalSource` ごとに見ていた時間を数える。`cycle_completed` のとき、その周期の **95% 以上**見ていれば `Notebook.record(signal_id)` を呼ぶ。ラジオは `reception() >= 0.8` の時間を「見ていた」として数える。
  - `Notebook`（autoload でなく UI シーン。状態は `GameState.notebook` に置く）：`func record(signal_id: StringName) -> bool`（同じ id は1回だけ。`hidden` なら `decoded=false`、それ以外は `true`）、`func entry_text(entry: Dictionary) -> String`（`decoded` なら `tr(label_key) + "：" + def.text`、未解読なら `tr(label_key) + "：" + Morse.encode(def.text)` と自力入力欄）、`func try_manual_decode(signal_id: StringName, guess: String) -> bool`（大文字小文字・空白を無視して一致すれば `decoded=true`）。
  - 手帳を開くキー：`N`（入力マップ `open_notebook`）。

- [ ] **Step 1: 失敗するテストを書く**
  - `record` が一度だけ記録し、`hidden` の信号は `decoded=false` になること。`try_manual_decode(&"oldman_nigero", "ni gero")` で `true`、`"NIGERU"` で `false`。
  - **Review Focus 5**：周期の 94% だけ見たときは記録されず、95% 以上なら記録されること。周期の途中で視界から外れて戻った場合、見ていた時間の合計で判定すること。
  - **Review Focus 4**：`TranslationServer.set_locale("ja")` で記録→`"en"` に切り替え→`entry_text` が英語の見出しになること（`GameState.notebook` には翻訳後の文字列ではなくキーが入っていること）。
- [ ] **Step 2: 失敗を確認**
- [ ] **Step 3: 実装と、手帳 UI（記録の一覧、各記録の波形表示＝`timeline` を横棒で描く、未解読なら入力欄）を作る**
- [ ] **Step 4: PASS を確認**
- [ ] **Step 5: コミット** `git commit -m "feat: signal observation and notebook"`

---

### Task 8: 一人称操作・調べる・会話

**Files:**
- Create: `game/scripts/player/player.gd`, `interactor.gd`, `game/scenes/parts/player.tscn`, `game/scripts/dialogue/dialogue_runner.gd`, `game/scripts/ui/dialogue_box.gd`, `dialogue_box.tscn`
- Test: `game/tests/dialogue/test_dialogue_runner.gd`

**Interfaces:**
- Consumes: `GameState.flags`, `GameState.told_wife`
- Produces:
  - `Player extends CharacterBody3D`：歩き 2.2m/s、しゃがみ 1.0m/s（`crouch` キー、目線 1.6m→1.0m）、手持ちの灯り（`toggle_light`、`SpotLight3D`）。走りはなし。
  - `Interactor`：画面中心から 2.0m のレイで `interactable` グループのノードを探し、`interact`（E キー）で `func interact(player: Player) -> void` を呼ぶ。
  - 会話データ形式（`data/dialogue/*.json`）：`{"<node_id>": {"speaker_key": "...", "text_key": "...", "next": "<node_id>" | null, "choices": [{"text_key": "...", "next": "...", "set": {"told_wife": true}}], "require": {"flag名": 値}}}`。`set` は `GameState` のフィールドまたは `flags` に書く。
  - `DialogueRunner`：`func start(file: String, node_id: String) -> void`、`func choose(index: int) -> void`、`func current() -> Dictionary`、シグナル `ended(last_node_id: String)`。

- [ ] **Step 1: 失敗するテストを書く** — テスト用の会話 JSON で、`next` をたどれること、選択肢で `GameState.told_wife` が `true` になること、`set` に `flags` のキー（例 `"asked_neighbor": true`）を書けること、`require` を満たさない選択肢が `current()["choices"]` から除外されること、`next: null` で `ended` が出ること。
- [ ] **Step 2: 失敗を確認**
- [ ] **Step 3: 実装（Player / Interactor は手動確認、DialogueRunner はテスト対象）**
- [ ] **Step 4: PASS を確認し、テスト用の小部屋シーンで歩く・しゃがむ・灯り・調べる・会話を手動で確認する**
- [ ] **Step 5: コミット** `git commit -m "feat: first-person player, interaction and dialogue runner"`

---

### Task 9: 島の簡易マップと、序章・第1章の流れ

**Files:**
- Create: `game/scenes/island_slice.tscn`, `home_interior.tscn`, `museum.tscn`, `game/scripts/story/chapter_flow.gd`, `game/scripts/story/scare_director.gd`, `game/data/dialogue/ch0.json`, `ch1.json`, `game/data/scares.json`
- Modify: `game/i18n/strings.csv`（会話・目標・UI の全キー）
- Test: `game/tests/story/test_chapter_flow.gd`

**Interfaces:**
- Consumes: Task 3〜8 のすべて
- Produces:
  - `ChapterFlow`（シーンに1つ）：目標の列を持ち、`func complete(goal_id: StringName) -> void` で次へ進む。章の切り替わりと、家・資料館への出入りで `SaveSystem.save(0)` を呼ぶ。`GameState.told_wife` が `true` になった時点で `EndingResolver.resolve` を呼び、`confession` なら⑤の演出（暗転して「じゃあ、一緒に確かめに行こう」→ タイトルへ）。
  - 目標の列（`goal_id`）：序章 `arrive_pier` → `greet_mother` → `visit_museum`（`museum_hi` を手帳に記録すると完了）→ `go_home` → `first_night`（窓から点滅を見る）／第1章 `ask_neighbor` → `talk_wife`（選択肢「SOSのことを話す／話さない」）→ `find_regular_lamp`（`sos_a` を記録すると完了）→ `radio_night`（ラジオで `sos_a` を記録）→ `slice_end`（「第1章 完」を表示）。
  - `ScareDirector`：`scares.json` の `{"id", "trigger": "goal_completed:<goal_id>", "kind": "figure_under_lamp", "lamp_path": "..."}` を読み、条件で演出を1回だけ再生する。第1章は `figure_under_lamp`（`find_regular_lamp` 完了時。街灯の下の人影が点滅に合わせて消えたり現れたりし、3周期で消える）の1件。

マップの中身（グレーボックス＋Task 5 の素材）：
- 港の桟橋（開始地点）、通り1本（街灯 8 本：うち `sos_a` 1本、`Flicker` 5本、常時点灯 1本、**消えたままの 1本**）、妻の実家、自宅（窓から `sos_a` の街灯が見える）、炭鉱資料館（モールス展示で `museum_hi` を点滅させる）。
- 設計書の伏線のうち、この範囲に入るもの：島民（妻の母・近所の人）は戸を島のリズムで叩き、妻は普通に叩く（ノック音は `Knock` の効果音を2種用意）／妻の母があだ名で呼ぶと妻の返事が一拍遅れる／移住支援のパンフ（調べると「ご夫婦での移住歓迎。ご親族の少ない方も安心のサポート」）／自宅の洗面台の使いかけの男物の整髪料／消えたままの街灯。
- 会話で必ず入れるセリフ：妻「古い街灯だから」、⑤「じゃあ、一緒に確かめに行こう」。そのほかのセリフは、上の目標を進めるのに必要な分だけ書き、すべて日本語と英語の両方を `strings.csv` に入れる。

- [ ] **Step 1: 失敗するテストを書く** — `ChapterFlow` の目標が順番どおりにしか進まないこと、`museum_hi` の記録で `visit_museum` が完了すること、`told_wife=true` で `confession` の演出が呼ばれること（演出呼び出しはシグナル `ending_triggered(id)` で確認）、章の切り替わりでセーブファイルが作られること、`ScareDirector` が同じ演出を2回再生しないこと。
- [ ] **Step 2: 失敗を確認**
- [ ] **Step 3: マップ・会話・演出データを作り、`ChapterFlow` と `ScareDirector` を実装する**
- [ ] **Step 4: PASS を確認**
- [ ] **Step 5: 手動で通しプレイする** — 序章開始から「第1章 完」まで、日本語と英語の両方で最後まで進めること。⑤の分岐（話す）でタイトルに戻ること。窓から見た `sos_a` の街灯が、壊れた街灯の中で規則的に見えること。
- [ ] **Step 6: コミット** `git commit -m "feat: island slice with prologue and chapter 1 flow"`

---

### Task 10: 縦切りの仕上げと、怖さの確認

**Files:**
- Create: `docs/superpowers/plans/2026-10-26-vertical-slice-playtest.md`（確認結果の記録）
- Modify: 必要に応じて `game/data/*.json`（数値の調整のみ）

- [ ] **Step 1: テストコマンドで全テスト PASS を確認する**
- [ ] **Step 2: Windows 向けに書き出し（Export）、書き出した実行ファイルで序章〜第1章を通しで遊べることを確認する**
- [ ] **Step 3: 次の項目を確認し、記録ファイルに結果を書く** — ①通りに出て点滅に気づくまでの時間（目安 30 秒以内） ②規則的な街灯を見分けられたか ③人影の演出で驚いたか ④手帳の操作に迷わなかったか ⑤日本語・英語の表示崩れがないか。可能なら自分以外の1〜3人にも遊んでもらう。
- [ ] **Step 4: 確認結果で必要になった調整を `signals.json`・`scares.json` の数値だけで行い、テストを再実行して PASS を確認する**
- [ ] **Step 5: コミット** `git commit -m "chore: vertical slice playtest and tuning"`
