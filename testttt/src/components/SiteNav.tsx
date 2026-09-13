"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const LINKS = [
  { href: "/", label: "Bible" },
  { href: "/codex", label: "Codex" },
  { href: "/market", label: "Market" },
  { href: "/world", label: "World" },
];

export default function SiteNav() {
  const path = usePathname();
  if (path?.startsWith("/play")) return null;
  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-[#0b0d12]/85 backdrop-blur-xl">
      <div className="mx-auto flex max-w-6xl items-center gap-3 px-4 py-3">
        <Link href="/" className="flex items-center gap-2">
          <span className="grid h-8 w-8 place-items-center rounded-xl border-2 border-black/60 bg-gradient-to-b from-amber-300 to-amber-600 text-sm font-black text-black">
            R
          </span>
          <span className="text-sm font-black uppercase tracking-[0.25em] text-slate-100">Remnants</span>
        </Link>
        <nav className="ml-auto flex items-center gap-1 overflow-x-auto">
          {LINKS.map((l) => {
            const active = l.href === "/" ? path === "/" : path?.startsWith(l.href);
            return (
              <Link
                key={l.href}
                href={l.href}
                className={`whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-bold uppercase tracking-wider transition ${
                  active ? "bg-white/10 text-amber-300" : "text-slate-400 hover:text-slate-100"
                }`}
              >
                {l.label}
              </Link>
            );
          })}
          <Link
            href="/play"
            className="ml-1 whitespace-nowrap rounded-lg border-b-4 border-amber-700 bg-amber-500 px-3 py-1.5 text-xs font-black uppercase tracking-wider text-black active:translate-y-0.5 active:border-b-2"
          >
            Play
          </Link>
        </nav>
      </div>
    </header>
  );
}
