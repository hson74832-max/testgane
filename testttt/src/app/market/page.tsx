import type { Metadata } from "next";
import MarketClient from "./MarketClient";

export const metadata: Metadata = {
  title: "Remnants — Sanctuary Exchange",
  description: "The live, player-driven market for Remnants.",
};

export const dynamic = "force-dynamic";

export default function MarketPage() {
  return <MarketClient />;
}
