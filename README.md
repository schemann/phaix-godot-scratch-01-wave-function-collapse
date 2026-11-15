# Wave Function Collapse from Scratch

Project files for tutorial 01 of the Godot From Scratch series by Phaix on YouTube (https://www.youtube.com/@Phaix).

Wave Function Collapse from scratch in Godot 4, on a TileMapLayer: tiles and their corner rules, the wave, collapse, propagation, contradictions and a restart, the lowest entropy and weights.

## Steps

Every step of the video is its own folder in `steps/`, the exact state at the end of that
part. Open the project in Godot 4.7, then open `steps/<step>/main.tscn` and press F6 to run
that step. The project's main scene is the final step.

| Folder | Part of the video |
|---|---|
| `steps/step_00_start` | Starting point (the project the video starts from) |
| `steps/step_01_rules` | Step 1 - Tiles and rules |
| `steps/step_02_wave` | Step 2 - The wave |
| `steps/step_03_collapse` | Step 3 - Collapse |
| `steps/step_04_propagate` | Step 4 - Propagate |
| `steps/step_05_contradiction` | Step 5 - Contradictions |
| `steps/step_06_entropy` | Step 6 - Entropy |
| `steps/step_07_weights` | Step 7 - Weights |

## Controls

WASD or arrow keys or the left stick to walk, mouse or right stick to look, Space to jump,
Esc gives the mouse back, a click captures it again. Further keys per tutorial are shown
in the video and in the HUD.

## Tests

```sh
godot --headless --path . -s res://tests/run_tests.gd
```

## Support

Support the channel: https://ko-fi.com/phaix or https://github.com/sponsors/schemann

## License

Code and scenes: MIT (see LICENSE).
The tiles: Tower Defense (Top-Down) by Kenney (www.kenney.nl, https://kenney.nl/assets/tower-defense-top-down), CC0, see tiles/License.txt.
