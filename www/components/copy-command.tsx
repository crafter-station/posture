"use client";

import { useState } from "react";

export function CopyCommand({ command }: { command: string }) {
  const [copied, setCopied] = useState(false);

  return (
    <button
      type="button"
      onClick={() => {
        navigator.clipboard.writeText(command).catch(() => {});
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
      }}
      className="group flex h-10 w-full items-center justify-between gap-3 border bg-card px-3 text-left font-mono text-xs transition-colors hover:bg-accent sm:text-sm"
    >
      <span>
        <span className="select-none text-muted-foreground">$ </span>
        {command}
      </span>
      <span className="shrink-0 font-mono text-[10px] uppercase tracking-[0.1em] text-muted-foreground">
        {copied ? "copied" : "copy"}
      </span>
    </button>
  );
}
