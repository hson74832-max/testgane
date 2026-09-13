import { NextResponse } from "next/server";
import { db } from "@/db";
import { characters, deathLog, marketTrades, remnants, telemetry } from "@/db/schema";
import { desc, eq, sql } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function GET() {
  const [deaths, leaderboard, openRemnants, trades, hotspots, eventCounts] = await Promise.all([
    db.select().from(deathLog).orderBy(desc(deathLog.createdAt)).limit(25),
    db.select().from(characters).orderBy(desc(characters.xp)).limit(12),
    db.select().from(remnants).where(eq(remnants.looted, false)).orderBy(desc(remnants.createdAt)).limit(20),
    db.select().from(marketTrades).orderBy(desc(marketTrades.createdAt)).limit(12),
    db
      .select({
        region: deathLog.region,
        n: sql<number>`count(*)::int`,
        avgLevel: sql<number>`coalesce(round(avg(${deathLog.level}))::int, 0)`,
      })
      .from(deathLog)
      .groupBy(deathLog.region)
      .orderBy(desc(sql`count(*)`)),
    db
      .select({ event: telemetry.event, n: sql<number>`count(*)::int` })
      .from(telemetry)
      .groupBy(telemetry.event)
      .orderBy(desc(sql`count(*)`))
      .limit(10),
  ]);

  return NextResponse.json({ deaths, leaderboard, remnants: openRemnants, trades, hotspots, eventCounts });
}
