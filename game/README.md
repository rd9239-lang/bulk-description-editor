# 街灯のSOS（縦切り試作：序章＋第1章）

## 遊び方（Godot 4.3）
1. Godot 4.3 でこのフォルダ（`game/`）を開く
2. F5 で実行

操作：WASD 移動 / マウス 視点 / E 調べる / C しゃがむ / F 手持ちの灯り / N 信号手帳

## テスト
```bash
./run_tests.sh            # 全テスト
./run_tests.sh fist       # ファイル名で絞り込み
```
GUT が導入できない環境のため、`addons/minitest` の小さなテストランナーを使っています（GUT と同じ書き方）。

## 3D素材の再生成（Blender）
```bash
blender -b -P tools/blender/build_streetlight.py -- --out assets/models/streetlight.glb
# または Blender を Python モジュール（pip install bpy）として:
python3 tools/blender/build_streetlight.py --out assets/models/streetlight.glb
```
`build_pole.py`、`build_house_kit.py`、`build_street_props.py`（ブロック塀・側溝のふた・カーブミラー・室外機・ガスメーター・仮の人物）も同様です。

## 画面確認（スクリーンショット）
```bash
xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tools/capture.gd -- <出力先> [ja|en]
```

## 画質
- タイトル画面の「画質：高／低」で切り替え。高はボリュメトリックフォグ・映り込み（SSR）・陰影（SSAO）・影あり（Vulkan 対応の GPU が必要）。
- 古い PC 向けには Godot の Compatibility（OpenGL）でも動く（霧や映り込みなしの軽い見た目）。

## 質感画像（テクスチャ）
- `assets/textures/<名前>/albedo.jpg・normal.jpg・roughness.jpg` は `tools/textures/generate_textures.py` で手続き的に作ったもの。
- Poly Haven などの写真素材に差し替えるときは、同じフォルダの同じ名前で上書きするだけでよい（色＝diff、凹凸＝nor_gl、ツヤ＝rough）。
- どの材質にどの画像を使うか、1枚が何メートルかは `data/materials.json`。
- 色の画像しかない写真素材は `python3 tools/textures/import_photo.py --src <画像> --name <フォルダ名>` で、凹凸とツヤを色の濃淡から作って取り込める（`--normal` で凹凸の強さ、`--rough` でツヤの基準値）。
- 生成のテスト：`python3 tools/textures/test_texgen.py`

## 音
- `assets/audio/*.ogg` は `tools/audio/generate_sounds.py` で合成したもの（環境音のループ、足音4種×4、街灯のうなり・リレー音、汽笛、驚かせる演出の音、手帳の紙の音）。テスト：`python3 tools/audio/test_sounds.py`
- 試聴用のミックス：`python3 tools/audio/make_preview.py --out preview.mp3`
- バス：Outdoor（屋外の音。屋内に入るとこもって小さくなる）、Indoor（部屋の静けさ・ラジオ）、SFX（足音・演出・手帳）
- 足音は床の当たり判定に付けた `surface` メタ情報（asphalt / gravel / wood / tatami）で切り替わる
- 録音素材に差し替えるときは、同じファイル名の OGG で上書きする（ループ音はループ再生の設定がコードで有効になる）

## 調整しやすい場所
- 信号（文字・打ち癖・休み）：`data/signals.json`
- 驚かせる演出：`data/scares.json`
- 会話：`data/dialogue/ch0.json`, `ch1.json`、文言は `i18n/strings.csv`（日本語・英語）
- 街灯や家の配置：`scripts/story/slice_main.gd` の `LAMPS` と `HOUSES`
