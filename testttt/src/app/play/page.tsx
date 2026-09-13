import type { Metadata } from "next";
import GamePlay from "@/components/game/GamePlay";

export const metadata: Metadata = {
  title: "Remnants — Vertical Slice",
  description: "Playable tile-based combat prototype for Remnants.",
};

export default function PlayPage() {
  return <GamePlay initialName="Wanderer" />;
}
