import { getDb } from '@/lib/db';
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const sql = getDb();
    const rows = await sql`SELECT * FROM media ORDER BY display_order ASC`;
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
      INSERT INTO media (title, description, type, url, bucket_path, duration_seconds, file_size_bytes, mime_type, is_active, display_order)
      VALUES (${body.title}, ${body.description || null}, ${body.type}, ${body.url}, ${body.bucket_path || ''}, ${body.duration_seconds || 10}, ${body.file_size_bytes || null}, ${body.mime_type || null}, ${body.is_active ?? true}, ${body.display_order || 0})
      RETURNING *
    `;
    return NextResponse.json({ data: rows[0] });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
