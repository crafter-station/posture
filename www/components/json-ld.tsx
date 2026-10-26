export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      // JSON.stringify does not escape "<" - replace to prevent script
      // injection through structured data.
      // biome-ignore lint: intentional dangerouslySetInnerHTML for JSON-LD
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(data).replace(/</g, "\\u003c"),
      }}
    />
  );
}
