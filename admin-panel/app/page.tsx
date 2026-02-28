'use client';

import { useEffect, useState } from 'react';
import { type MediaItem } from '@/lib/supabase';

export default function DashboardPage() {
  const [mediaCount, setMediaCount] = useState(0);
  const [activeCount, setActiveCount] = useState(0);
  const [videoCount, setVideoCount] = useState(0);
  const [imageCount, setImageCount] = useState(0);
  const [recentMedia, setRecentMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  async function fetchDashboardData() {
    try {
      const res = await fetch('/api/media');
      const { data: media } = await res.json();

      if (media) {
        setMediaCount(media.length);
        setActiveCount(media.filter((m: MediaItem) => m.is_active).length);
        setVideoCount(media.filter((m: MediaItem) => m.type === 'video').length);
        setImageCount(media.filter((m: MediaItem) => m.type === 'image').length);
        setRecentMedia(media.slice(0, 5));
      }
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" />
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Dashboard</h1>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard title="Total Media" value={mediaCount} icon="📁" color="blue" />
        <StatCard title="Active" value={activeCount} icon="✅" color="green" />
        <StatCard title="Videos" value={videoCount} icon="🎥" color="purple" />
        <StatCard title="Images" value={imageCount} icon="🖼️" color="orange" />
      </div>

      {/* Recent Media */}
      <div className="bg-gray-900 rounded-xl border border-gray-800 p-6">
        <h2 className="text-xl font-semibold mb-4">Recent Media</h2>
        {recentMedia.length === 0 ? (
          <p className="text-gray-500 text-center py-8">
            No media uploaded yet. Go to Media to upload your first ad!
          </p>
        ) : (
          <div className="space-y-3">
            {recentMedia.map((item) => (
              <div
                key={item.id}
                className="flex items-center justify-between p-4 bg-gray-800 rounded-lg"
              >
                <div className="flex items-center gap-4">
                  <span className="text-2xl">
                    {item.type === 'video' ? '🎥' : '🖼️'}
                  </span>
                  <div>
                    <p className="font-medium">{item.title}</p>
                    <p className="text-sm text-gray-400">
                      {item.type} • {item.duration_seconds}s
                    </p>
                  </div>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium ${
                    item.is_active
                      ? 'bg-green-900 text-green-300'
                      : 'bg-gray-700 text-gray-400'
                  }`}
                >
                  {item.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  icon,
  color,
}: {
  title: string;
  value: number;
  icon: string;
  color: string;
}) {
  const colorMap: Record<string, string> = {
    blue: 'from-blue-600/20 to-blue-600/5 border-blue-800',
    green: 'from-green-600/20 to-green-600/5 border-green-800',
    purple: 'from-purple-600/20 to-purple-600/5 border-purple-800',
    orange: 'from-orange-600/20 to-orange-600/5 border-orange-800',
  };

  return (
    <div
      className={`bg-gradient-to-br ${colorMap[color]} border rounded-xl p-6`}
    >
      <div className="flex items-center justify-between mb-4">
        <span className="text-3xl">{icon}</span>
      </div>
      <p className="text-3xl font-bold">{value}</p>
      <p className="text-sm text-gray-400 mt-1">{title}</p>
    </div>
  );
}
