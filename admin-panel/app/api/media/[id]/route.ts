import { getDb } from '@/lib/db';
import { NextResponse } from 'next/server';
import { unlink } from 'fs/promises';
import { join } from 'path';

export const dynamic = 'force-dynamic';

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const sql = getDb();

    const setClauses: string[] = [];
    const values: Record<string, unknown> = {};

    // Build dynamic update
    if ('is_active' in body) values.is_active = body.is_active;
    if ('display_order' in body) values.display_order = body.display_order;
    if ('title' in body) values.title = body.title;
    if ('description' in body) values.description = body.description;
    if ('duration_seconds' in body) values.duration_seconds = body.duration_seconds;

    // Simple approach: update each field individually
    if ('is_active' in body) {
      await sql`UPDATE media SET is_active = ${body.is_active}, updated_at = NOW() WHERE id = ${id}::uuid`;
    }
    if ('display_order' in body) {
      await sql`UPDATE media SET display_order = ${body.display_order}, updated_at = NOW() WHERE id = ${id}::uuid`;
    }
    if ('title' in body) {
      await sql`UPDATE media SET title = ${body.title}, updated_at = NOW() WHERE id = ${id}::uuid`;
    }

    const rows = await sql`SELECT * FROM media WHERE id = ${id}::uuid`;
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

    // Get file path before deleting
    const rows = await sql`SELECT bucket_path FROM media WHERE id = ${id}::uuid`;
    if (rows[0]?.bucket_path) {
      try {
        const filePath = join(process.cwd(), 'public', rows[0].bucket_path);
        await unlink(filePath);
      } catch { /* file may not exist */ }
    }

    await sql`DELETE FROM media WHERE id = ${id}::uuid`;
    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
