import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import SiteNav from "@/components/SiteNav";
import "./globals.css";

export const metadata: Metadata = {
  title: "Remnants — Design Bible & Vertical Slice",
  description:
    "A tile-based, persistent-world mobile MMORPG. Tibia's stakes, Brawl Stars' clarity.",
};

export const viewport: Viewport = {
  themeColor: "#0b0d12",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-dvh bg-[#0b0d12] text-slate-200 antialiased">
        <SiteNav />
        {children}
      </body>
    </html>
  );
}
