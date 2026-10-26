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

## 自作
- `models/streetlight.glb`, `models/pole.glb`, `models/house_kit.glb`, `models/street_props.glb`：`tools/blender/build_*.py` で生成
- `textures/*`（アスファルト、コンクリート、ブロック、古い板、トタン、塗装の鉄、漆喰、砂利、板床、畳、「止まれ」）：`tools/textures/generate_textures.py` で手続き的に生成
