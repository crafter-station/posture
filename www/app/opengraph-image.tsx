import { ImageResponse } from "next/og";

export const alt = "posture - slouch alerts from your AirPods";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

// Hand-synced with the dark tokens in app/globals.css.
const BG = "#0d0d0d";
const FG = "#fafafa";
const MUTED = "#8f8f8f";
const BORDER = "#242424";

export default function OgImage() {
  return new ImageResponse(
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
        background: BG,
        color: FG,
        padding: 72,
        fontFamily: "monospace",
        border: `24px solid ${BG}`,
      }}
    >
      <div
        style={{
          display: "flex",
          fontSize: 24,
          color: MUTED,
          letterSpacing: 4,
          textTransform: "uppercase",
        }}
      >
        macOS · AirPods · menu bar + CLI · MIT
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
        <div style={{ display: "flex", fontSize: 96, fontWeight: 700 }}>
          posture
        </div>
        <div
          style={{
            display: "flex",
            fontSize: 40,
            color: MUTED,
            maxWidth: 900,
          }}
        >
          Your AirPods already know when you slouch.
        </div>
      </div>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          borderTop: `1px solid ${BORDER}`,
          paddingTop: 32,
          fontSize: 26,
        }}
      >
        <div style={{ display: "flex", color: FG }}>
          by Cristian Correa · cris.fast
        </div>
        <div style={{ display: "flex", color: MUTED }}>posture.crafter.run</div>
      </div>
    </div>,
    size,
  );
}
