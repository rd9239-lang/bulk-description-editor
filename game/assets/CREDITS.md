# 素材の出典

## 3Dモデル（Poly Haven、CC0）
すべて Poly Haven（https://polyhaven.com）の CC0 素材。4K 版を `tools/blender/convert_polyhaven.py` でテクスチャ 1024px に縮小して GLB に変換。

| ファイル | 元素材 |
|---|---|
| `models/props/wooden_table_02.glb` | Wooden Table 02 — https://polyhaven.com/a/wooden_table_02 |
| `models/props/classic_laptop.glb` | Classic Laptop — https://polyhaven.com/a/classic_laptop |
| `models/props/vintage_wooden_drawer_01.glb` | Vintage Wooden Drawer 01 — https://polyhaven.com/a/vintage_wooden_drawer_01 |
| `models/props/plastic_crate_02.glb` | Plastic Crate 02 — https://polyhaven.com/a/plastic_crate_02 |
| `models/props/long_life_food.glb` | Long Life Food — https://polyhaven.com/a/long_life_food |

## 写真の質感画像（ユーザー提供、2026-10-26）
色の画像（diff）を受け取り、`tools/textures/import_photo.py` で凹凸（normal）とツヤ（roughness）を色の濃淡から近似して作成。
**入手元の素材名とライセンスは未記入。Poly Haven などの CC0 素材であれば、素材名とURLをここに追記すること。**

| フォルダ | 内容 | 使い道（data/materials.json） |
|---|---|---|
| `textures/photo_rock` | 割れた岩肌 | rock（岸の護岸） |
| `textures/photo_wood_floor` | 縦張りの板床 | wood_floor（桟橋） |
| `textures/photo_pine_planks` | 節のある松の板 | plank / plank_dark（家の板壁、杭など） |
| `textures/photo_concrete` | 灰色のコンクリート | concrete（電柱、基礎、笠木） |
| `textures/photo_ground` | ひびの入った土色の地面 | gravel（地面） |

## 自作
- `models/streetlight.glb`, `models/pole.glb`, `models/house_kit.glb`, `models/street_props.glb`：`tools/blender/build_*.py` で生成
- `textures/*`（アスファルト、コンクリート、ブロック、古い板、トタン、塗装の鉄、漆喰、砂利、板床、畳、「止まれ」）：`tools/textures/generate_textures.py` で手続き的に生成
