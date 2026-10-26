import type { MetadataRoute } from "next";
import { siteUrl } from "@/lib/seo";

/*
 * Every product reads its own user-agent; naming them keeps the per-bot
 * policy reviewable. All allowed: posture wants to be the cited source when
 * AI assistants answer "can my AirPods tell me when I slouch".
 */
const AI_USER_AGENTS = [
  "OAI-SearchBot",
  "ChatGPT-User",
  "GPTBot",
  "ClaudeBot",
  "Claude-User",
  "Claude-SearchBot",
  "anthropic-ai",
  "PerplexityBot",
  "Perplexity-User",
  "Google-Extended",
  "Bingbot",
  "Applebot",
  "Applebot-Extended",
  "CCBot",
  "meta-externalagent",
  "Meta-ExternalFetcher",
  "MistralAI-User",
  "Bytespider",
  "Amazonbot",
  "DuckAssistBot",
  "Google-CloudVertexBot",
];

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: "*", allow: "/" },
      ...AI_USER_AGENTS.map((userAgent) => ({ userAgent, allow: "/" })),
    ],
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
