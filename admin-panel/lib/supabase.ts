// Types only - database queries go through API routes (/api/*)

export type MediaItem = {
  id: string;
  title: string;
  description: string | null;
  type: 'image' | 'video';
  url: string;
  bucket_path: string;
  thumbnail_url: string | null;
  duration_seconds: number;
  file_size_bytes: number | null;
  mime_type: string | null;
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
};

export type Schedule = {
  id: string;
  media_id: string;
  name: string | null;
  start_time: string;
  end_time: string;
  days_of_week: number[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type AppSetting = {
  id: string;
  key: string;
  value: unknown;
  description: string | null;
  updated_at: string;
};
