"use client";

import { useCallback, useRef, useState } from "react";

type Props = {
  onDir: (dir: { x: number; y: number } | null) => void;
  dim: boolean;
};

/** Thumb-anchored 8-way stick. Grid movement, so output is quantised to 8 dirs. */
export default function Joystick({ onDir, dim }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  const [knob, setKnob] = useState({ x: 0, y: 0 });
  const [active, setActive] = useState(false);
  const originRef = useRef({ x: 0, y: 0 });

  const compute = useCallback(
    (cx: number, cy: number) => {
      const dx = cx - originRef.current.x;
      const dy = cy - originRef.current.y;
      const len = Math.hypot(dx, dy);
      const max = 52;
      const clamped = Math.min(len, max);
      const nx = len > 0 ? (dx / len) * clamped : 0;
      const ny = len > 0 ? (dy / len) * clamped : 0;
      setKnob({ x: nx, y: ny });
      if (len < 16) {
        onDir(null);
        return;
      }
      const ang = Math.atan2(dy, dx);
      const oct = Math.round(ang / (Math.PI / 4));
      const table: Record<number, { x: number; y: number }> = {
        [-4]: { x: -1, y: 0 },
        [-3]: { x: -1, y: -1 },
        [-2]: { x: 0, y: -1 },
        [-1]: { x: 1, y: -1 },
        [0]: { x: 1, y: 0 },
        [1]: { x: 1, y: 1 },
        [2]: { x: 0, y: 1 },
        [3]: { x: -1, y: 1 },
        [4]: { x: -1, y: 0 },
      };
      onDir(table[oct] ?? null);
    },
    [onDir],
  );

  return (
    <div
      ref={ref}
      className="pointer-events-auto touch-none select-none"
      style={{ opacity: dim && !active ? 0.4 : 1, transition: "opacity .45s ease" }}
      onPointerDown={(e) => {
        (e.target as HTMLElement).setPointerCapture(e.pointerId);
        const r = ref.current!.getBoundingClientRect();
        originRef.current = { x: r.left + r.width / 2, y: r.top + r.height / 2 };
        setActive(true);
        compute(e.clientX, e.clientY);
      }}
      onPointerMove={(e) => {
        if (!active) return;
        compute(e.clientX, e.clientY);
      }}
      onPointerUp={() => {
        setActive(false);
        setKnob({ x: 0, y: 0 });
        onDir(null);
      }}
      onPointerCancel={() => {
        setActive(false);
        setKnob({ x: 0, y: 0 });
        onDir(null);
      }}
    >
      <div className="relative grid h-36 w-36 place-items-center rounded-full border-2 border-white/15 bg-black/35 backdrop-blur-sm">
        <div className="absolute inset-5 rounded-full border border-white/10" />
        <div
          className="h-16 w-16 rounded-full border-4 border-black/50 bg-gradient-to-b from-slate-100 to-slate-400 shadow-[0_6px_0_rgba(0,0,0,0.45)]"
          style={{ transform: `translate(${knob.x}px, ${knob.y}px)`, transition: active ? "none" : "transform .18s ease" }}
        />
      </div>
    </div>
  );
}
