import { getDb } from '@/lib/db';
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ key: string }> }
) {
  try {
    const { key } = await params;
    const body = await request.json();
    const sql = getDb();

    await sql`UPDATE app_settings SET value = ${JSON.stringify(body.value)}::jsonb, updated_at = NOW() WHERE key = ${key}`;

    const rows = await sql`SELECT * FROM app_settings WHERE key = ${key}`;
    return NextResponse.json({ data: rows[0] });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
