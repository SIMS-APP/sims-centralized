import { getDb } from '@/lib/db';
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const sql = getDb();

    if ('is_active' in body) {
      await sql`UPDATE schedules SET is_active = ${body.is_active}, updated_at = NOW() WHERE id = ${id}::uuid`;
    }

    const rows = await sql`SELECT * FROM schedules WHERE id = ${id}::uuid`;
    return NextResponse.json({ data: rows[0] });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const sql = getDb();
    await sql`DELETE FROM schedules WHERE id = ${id}::uuid`;
    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
