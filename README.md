# posture

Slouch alerts from your AirPods. Reads the head-tracking sensor in AirPods Pro, AirPods 3+, AirPods Max or Beats Fit Pro and nudges you when your head drops for too long.

```sh
swift build -c release
ln -sf "$PWD/.build/release/posture" ~/.local/bin/posture
```

## Use

```sh
posture                  # watch (calibrates on first run)
posture calibrate        # sit straight, save that as upright
posture now              # one reading, exit 0 upright, 1 slouching
posture stats --days 7   # daily score, slouch time, nudges
posture config --threshold 12 --grace 30
posture doctor           # AirPods, permission, sensor, calibration
```

Every command takes `--json`. `posture watch --json` streams JSONL (`sample`, `nudge`, `disconnected`, `summary`), so agents and scripts can follow along.

## How it works

The AirPods report gravity in their own frame. Calibration stores your upright gravity vector, and the tilt is the angle between that and the live, smoothed vector. Past `threshold` degrees for `grace` seconds you get a notification and a sound, and a soft tick when you sit back up.

Motion access is granted per process, and a CLI normally inherits its terminal's identity, which has no motion usage string, so macOS kills it. `posture` respawns itself with the terminal's responsibility disclaimed, so the request is made under its own embedded `Info.plist`.

Settings and history live in `~/.config/posture`.
