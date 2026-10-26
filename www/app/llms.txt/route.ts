import { author, githubUrl, siteUrl } from "@/lib/seo";

export const revalidate = false;

const content = `# posture

> Slouch alerts from your AirPods. A free, open source macOS menu bar app and
> CLI that reads the AirPods head tracking sensor (CoreMotion
> CMHeadphoneMotionManager) and nudges you when your head drops for too long.
> Built by ${author.name} (${author.url}), released with Crafter Station.

Install: \`npm install -g @crafter/posture\` then \`posture bar\` (macOS 15+, Apple Silicon and Intel, MIT, free)
Works with: AirPods Pro, AirPods 3 or newer, AirPods Max, Beats Fit Pro

## Features

- Live menu bar figure that bends with your head and turns orange while slouching
- Notification after 30 seconds of bad posture (configurable), soft tick on recovery
- Guided setup with a 3D head: six moves teach forward, back, sideways and turn axes, each move validated
- Stats: daily score, time slouched, nudges, best upright streak, hour by hour, week, neck range of motion
- Local only: no account, no network, data in ~/.config/posture

## Commands

- \`posture\`: watch live in the terminal
- \`posture now\`: one reading, exit 0 upright, 1 slouching
- \`posture stats [--days 7]\`: per day watched, slouched, streak, nudges, score, by hour
- \`posture config [--threshold deg] [--grace sec]\`: settings and range of motion
- \`posture calibrate\`: reset the upright reference
- \`posture doctor\`: AirPods, permission, sensor, calibration, learned directions
- All commands take \`--json\`; \`posture watch --json\` streams JSONL events: sample (degrees, pitch, roll, direction, slouching, streak), nudge, disconnected, summary

## How it works

1. AirPods report a gravity vector in the earbud frame about 50 times a second
2. Setup stores your upright vector and learns pitch, roll and yaw axes from guided moves
3. Forward drop past 15 degrees, or sideways past 20, counts as slouching; leaning back never counts; turning is ignored
4. Limits: rotation only, so a chin pushed forward with eyes level, or a slumped back with the head level, is not detected

## Links

- [Website](${siteUrl})
- [GitHub](${githubUrl})
- [Author: ${author.name}](${author.url})
`;

export function GET() {
  return new Response(content, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}
