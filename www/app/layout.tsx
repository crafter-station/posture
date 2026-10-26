import { Analytics } from "@vercel/analytics/next";
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { JsonLd } from "@/components/json-ld";
import { ThemeProvider } from "@/components/theme-provider";
import {
  author,
  githubUrl,
  siteDescription,
  siteTitle,
  siteUrl,
} from "@/lib/seo";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: siteTitle,
  description: siteDescription,
  keywords: [
    "airpods posture",
    "posture app mac",
    "slouch detector",
    "airpods head tracking",
    "bad posture reminder macos",
    "menu bar posture app",
    "CMHeadphoneMotionManager",
    "posture cli",
  ],
  authors: [{ name: author.name, url: author.url }],
  creator: author.name,
  publisher: "Crafter Station",
  alternates: { canonical: "/" },
  openGraph: {
    title: siteTitle,
    description: siteDescription,
    url: siteUrl,
    siteName: "posture",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: siteTitle,
    description: siteDescription,
  },
};

const person = {
  "@type": "Person",
  "@id": author.id,
  name: author.name,
  alternateName: author.alternateName,
  url: author.url,
  jobTitle: author.jobTitle,
  sameAs: [author.github, author.linkedin, author.x],
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      name: "posture",
      operatingSystem: "macOS 15+",
      applicationCategory: "HealthApplication",
      description: siteDescription,
      url: siteUrl,
      downloadUrl: githubUrl,
      installUrl: githubUrl,
      codeRepository: githubUrl,
      sameAs: [githubUrl],
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      license: "https://opensource.org/licenses/MIT",
      author: { "@id": author.id },
      creator: { "@id": author.id },
      publisher: {
        "@type": "Organization",
        name: "Crafter Station",
        url: "https://crafterstation.com",
      },
    },
    person,
    {
      "@type": "WebSite",
      name: "posture",
      url: siteUrl,
      author: { "@id": author.id },
    },
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
        <JsonLd data={jsonLd} />
        <Analytics />
      </body>
    </html>
  );
}
