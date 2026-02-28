import { getDb } from '@/lib/db';
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const sql = getDb();
    const rows = await sql`SELECT * FROM schedules ORDER BY created_at DESC`;
    return NextResponse.json({ data: rows });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const sql = getDb();
    const rows = await sql`
      INSERT INTO schedules (media_id, name, start_time, end_time, days_of_week, is_active)
      VALUES (${body.media_id}::uuid, ${body.name || null}, ${body.start_time}, ${body.end_time}, ${body.days_of_week || [0,1,2,3,4,5,6]}, ${body.is_active ?? true})
      RETURNING *
    `;
    return NextResponse.json({ data: rows[0] });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
