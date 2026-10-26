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
`build_pole.py`、`build_house_kit.py` も同様です。

## 画面確認（スクリーンショット）
```bash
xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tools/capture.gd -- <出力先> [ja|en]
```

## 調整しやすい場所
- 信号（文字・打ち癖・休み）：`data/signals.json`
- 驚かせる演出：`data/scares.json`
- 会話：`data/dialogue/ch0.json`, `ch1.json`、文言は `i18n/strings.csv`（日本語・英語）
- 街灯や家の配置：`scripts/story/slice_main.gd` の `LAMPS` と `HOUSES`
