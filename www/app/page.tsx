import Image from "next/image";
import { CopyCommand } from "@/components/copy-command";
import { GithubStars } from "@/components/github-stars";
import { JsonLd } from "@/components/json-ld";
import { ThemeToggle } from "@/components/theme-toggle";
import { author, githubUrl } from "@/lib/seo";

const FEATURES: Array<[string, string]> = [
  [
    "live menu bar figure",
    "A small seated figure next to your other icons bends with your head in real time and turns orange while you slouch.",
  ],
  [
    "nudge after 30 seconds",
    "Hold a bad posture past the grace period and you get a notification. Sit back up and it clears with a soft tick.",
  ],
  [
    "guided 3D setup",
    "A wireframe head walks you through six moves and learns which way is forward, back and sideways for your AirPods.",
  ],
  [
    "stats that mean something",
    "Daily score, time slouched, nudges, best upright streak, hour by hour and the week. Plus your neck's range of motion.",
  ],
  [
    "built for agents",
    "Every command takes --json, posture now exits 0 or 1, and posture watch --json streams one event per second.",
  ],
  [
    "local only",
    "No account, no network, no telemetry. Settings and history live in ~/.config/posture on your Mac.",
  ],
];

const COMMANDS: Array<[string, string]> = [
  ["posture", "watch live in the terminal"],
  ["posture now", "one reading, exit 0 upright, 1 slouching"],
  ["posture stats", "score, slouch time, streak, nudges, by hour"],
  ["posture config", "threshold, grace period, range of motion"],
  ["posture doctor", "AirPods, permission, sensor, calibration"],
  ["posture bar", "open the menu bar app"],
];

const FAQ: Array<[string, string]> = [
  [
    "Which AirPods work?",
    "Any model with spatial audio head tracking: AirPods Pro, AirPods 3 or newer, AirPods Max and Beats Fit Pro. Standard AirPods 1 and 2 have no motion sensor.",
  ],
  [
    "How accurate is it?",
    "The AirPods fuse an accelerometer and gyroscope into a gravity direction about 50 times a second, precise to a degree or two and drift free. posture compares it to the way you like to sit and splits the difference into forward, back and sideways.",
  ],
  [
    "Does leaning back count as slouching?",
    "No. After the guided setup only a forward drop, or a sideways tilt past your threshold plus 5 degrees, counts. Turning to look at another screen is ignored.",
  ],
  [
    "What can it not detect?",
    "The sensor measures rotation, not position. Pushing your chin forward with your eyes level, or slumping your back with your head level, is not detected. Most real slouching comes with a head drop.",
  ],
  [
    "Does my data leave my Mac?",
    "No. posture has no network code. Everything stays in ~/.config/posture.",
  ],
];

const faqJsonLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: FAQ.map(([question, answer]) => ({
    "@type": "Question",
    name: question,
    acceptedAnswer: { "@type": "Answer", text: answer },
  })),
};

const label =
  "font-mono text-[10px] uppercase tracking-[0.12em] text-muted-foreground";
const link = "text-foreground underline underline-offset-4";

export default function HomePage() {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-3xl flex-col border-x">
      <header className="flex items-center justify-between gap-3 border-b px-4 py-3">
        <div>
          <h1 className="font-mono text-sm font-semibold tracking-tight">
            posture
            <span className="text-muted-foreground">.crafter.run</span>
          </h1>
          <p className="mt-0.5 hidden font-mono text-[10px] uppercase tracking-[0.1em] text-muted-foreground sm:block">
            AirPods · head tracking · menu bar
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="hidden sm:block">
            <GithubStars />
          </div>
          <ThemeToggle />
        </div>
      </header>

      <main className="flex-1">
        <section className="border-b px-4 py-12 sm:py-16">
          <p className={label}>macOS 15+ · free · MIT</p>
          <h2 className="mt-3 max-w-xl text-2xl font-semibold tracking-tight sm:text-3xl">
            Your AirPods already know when you slouch.
          </h2>
          <p className="mt-3 max-w-xl text-sm text-muted-foreground sm:text-base">
            posture reads the head tracking sensor in your AirPods and nudges
            you when your head drops for too long. A menu bar app with a live
            figure and stats, and a CLI built for scripts and AI agents. No
            account, nothing leaves your Mac.
          </p>
          <div className="mt-6 max-w-xl space-y-2">
            <CopyCommand command="git clone https://github.com/crafter-station/posture" />
            <CopyCommand command="cd posture && scripts/install.sh" />
          </div>
          <p className="mt-3 text-xs text-muted-foreground">
            Needs Xcode command line tools. Builds the app into
            ~/Applications and links the CLI.
          </p>
        </section>

        <section className="border-b">
          <Image
            src="/menu-bar-figure.png"
            alt="The posture menu bar figure upright, then bending forward and turning orange as the head drops"
            width={900}
            height={140}
            className="w-full bg-[#121214]"
            priority
          />
        </section>

        <section className="border-b">
          <div className="grid sm:grid-cols-2">
            {FEATURES.map(([title, body], i) => (
              <div
                key={title}
                className={[
                  "p-4",
                  i % 2 === 0 ? "sm:border-r" : "",
                  i < FEATURES.length - 2 ? "border-b" : "",
                  i === FEATURES.length - 2 ? "border-b sm:border-b-0" : "",
                ]
                  .filter(Boolean)
                  .join(" ")}
              >
                <h3 className="font-mono text-[10px] uppercase tracking-[0.12em]">
                  {title}
                </h3>
                <p className="mt-2 text-sm text-muted-foreground">{body}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="border-b px-4 py-8">
          <p className={label}>guided setup</p>
          <p className="mt-3 max-w-xl text-sm text-muted-foreground">
            Look down, look up, ear to each shoulder, turn each way. A ring
            fills as you follow the head, and each move is checked: nod during
            a side tilt and it asks you to redo it. Then you sit the way you
            like to work, and that becomes your reference. At the end the head
            mirrors you live.
          </p>
          <Image
            src="/setup-moves.png"
            alt="The 3D setup head in seven poses: center, look down, look up, tilt right, tilt left, turn right, turn left"
            width={2864}
            height={546}
            className="mt-5 w-full border bg-[#121214]"
          />
        </section>

        <section className="border-b px-4 py-8">
          <p className={label}>in the terminal</p>
          <pre className="mt-3 overflow-x-auto border bg-card p-4 font-mono text-xs leading-relaxed">
            <code>
              <span className="text-muted-foreground">$ </span>posture now
              {"\n"}
              {"██████··············"} 9° forward · 2° left{"  "}upright
              {"\n\n"}
              <span className="text-muted-foreground">$ </span>posture watch
              --json{"\n"}
              <span className="text-muted-foreground">
                {
                  '{"event":"sample","degrees":17,"direction":"forward","pitch":17,"roll":-2,"slouching":true}'
                }
              </span>
            </code>
          </pre>
          <div className="mt-4 border">
            {COMMANDS.map(([cmd, desc], i) => (
              <div
                key={cmd}
                className={`flex flex-col gap-1 p-3 sm:flex-row sm:items-baseline sm:gap-4 ${i > 0 ? "border-t" : ""}`}
              >
                <code className="shrink-0 font-mono text-xs sm:w-40">
                  {cmd}
                </code>
                <span className="text-xs text-muted-foreground">{desc}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="border-b px-4 py-8">
          <p className={label}>questions</p>
          <dl className="mt-3 max-w-xl space-y-5">
            {FAQ.map(([question, answer]) => (
              <div key={question}>
                <dt className="text-sm font-medium">{question}</dt>
                <dd className="mt-1 text-sm text-muted-foreground">{answer}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section className="border-b px-4 py-8">
          <p className={label}>made by</p>
          <p className="mt-3 max-w-xl text-sm text-muted-foreground">
            posture is built by{" "}
            <a href={author.url} rel="author" className={link}>
              {author.name}
            </a>
            , Founder of Croma, and released as open source with{" "}
            <a
              href="https://crafterstation.com"
              target="_blank"
              rel="noopener noreferrer"
              className={link}
            >
              Crafter Station
            </a>
            . More of his work at{" "}
            <a href={author.url} rel="author" className={link}>
              cris.fast
            </a>
            .
          </p>
          <div className="mt-4 flex flex-wrap gap-4 font-mono text-[10px] uppercase tracking-[0.1em] text-muted-foreground">
            {[
              ["cris.fast", author.url],
              ["GitHub", author.github],
              ["LinkedIn", author.linkedin],
              ["X", author.x],
            ].map(([name, href]) => (
              <a
                key={name}
                href={href}
                target="_blank"
                rel="me noopener noreferrer"
                className="transition-colors hover:text-foreground"
              >
                {name}
              </a>
            ))}
          </div>
        </section>
      </main>

      <footer className="flex items-center justify-between gap-3 px-4 py-4">
        <a
          href={author.url}
          rel="author"
          className="font-mono text-[10px] uppercase tracking-widest text-muted-foreground/60 transition-colors hover:text-muted-foreground"
        >
          by {author.name}
        </a>
        <div className="flex items-center gap-4 font-mono text-[10px] uppercase tracking-[0.1em] text-muted-foreground">
          <a
            href={githubUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-foreground"
          >
            GitHub
          </a>
          <a
            href="https://crafterstation.com"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-foreground"
          >
            Crafter Station
          </a>
          <span>MIT</span>
        </div>
      </footer>
      <JsonLd data={faqJsonLd} />
    </div>
  );
}
