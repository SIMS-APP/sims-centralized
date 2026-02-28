'use client';

import { useEffect, useState, useCallback } from 'react';
import { type Schedule, type MediaItem } from '@/lib/supabase';

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export default function SchedulesPage() {
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    media_id: '',
    name: '',
    start_time: '08:00',
    end_time: '18:00',
    days_of_week: [0, 1, 2, 3, 4, 5, 6] as number[],
  });

  const fetchData = useCallback(async () => {
    try {
      const [schedulesRes, mediaRes] = await Promise.all([
        fetch('/api/schedules'),
        fetch('/api/media'),
      ]);

      const schedulesJson = await schedulesRes.json();
      const mediaJson = await mediaRes.json();

      if (schedulesJson.data) setSchedules(schedulesJson.data);
      if (mediaJson.data) setMedia(mediaJson.data);
    } catch (err) {
      console.error('Error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    try {
      const res = await fetch('/api/schedules', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          media_id: form.media_id,
          name: form.name || null,
          start_time: form.start_time,
          end_time: form.end_time,
          days_of_week: form.days_of_week,
          is_active: true,
        }),
      });

      if (!res.ok) throw new Error('Failed to create schedule');

      setShowForm(false);
      setForm({
        media_id: '',
        name: '',
        start_time: '08:00',
        end_time: '18:00',
        days_of_week: [0, 1, 2, 3, 4, 5, 6],
      });
      await fetchData();
    } catch (err) {
      console.error('Create error:', err);
      alert('Failed to create schedule');
    }
  }

  async function toggleSchedule(id: string, isActive: boolean) {
    try {
      await fetch(`/api/schedules/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_active: !isActive }),
      });
      await fetchData();
    } catch (err) {
      console.error('Toggle error:', err);
    }
  }

  async function deleteSchedule(id: string) {
    if (!confirm('Delete this schedule?')) return;
    try {
      await fetch(`/api/schedules/${id}`, { method: 'DELETE' });
      await fetchData();
    } catch (err) {
      console.error('Delete error:', err);
    }
  }

  function toggleDay(day: number) {
    setForm((prev) => ({
      ...prev,
      days_of_week: prev.days_of_week.includes(day)
        ? prev.days_of_week.filter((d) => d !== day)
        : [...prev.days_of_week, day].sort(),
    }));
  }

  function getMediaTitle(mediaId: string) {
    return media.find((m) => m.id === mediaId)?.title || 'Unknown';
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
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Schedules</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          className="px-6 py-3 bg-blue-600 hover:bg-blue-700 rounded-lg font-medium transition-colors"
        >
          {showForm ? '✕ Cancel' : '+ New Schedule'}
        </button>
      </div>

      {/* Create Schedule Form */}
      {showForm && (
        <div className="bg-gray-900 rounded-xl border border-gray-800 p-6 mb-8">
          <h2 className="text-xl font-semibold mb-4">Create Schedule</h2>
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Media *
                </label>
                <select
                  required
                  value={form.media_id}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, media_id: e.target.value }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                >
                  <option value="">Select media...</option>
                  {media.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.title} ({m.type})
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Schedule Name
                </label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, name: e.target.value }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                  placeholder="e.g., Morning Ads"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Start Time
                </label>
                <input
                  type="time"
                  value={form.start_time}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, start_time: e.target.value }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  End Time
                </label>
                <input
                  type="time"
                  value={form.end_time}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, end_time: e.target.value }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                />
              </div>
            </div>

            {/* Days of Week */}
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-2">
                Active Days
              </label>
              <div className="flex gap-2">
                {DAYS.map((day, index) => (
                  <button
                    key={day}
                    type="button"
                    onClick={() => toggleDay(index)}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                      form.days_of_week.includes(index)
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-800 text-gray-500 hover:bg-gray-700'
                    }`}
                  >
                    {day}
                  </button>
                ))}
              </div>
            </div>

            <button
              type="submit"
              className="w-full py-3 bg-blue-600 hover:bg-blue-700 rounded-lg font-medium transition-colors"
            >
              Create Schedule
            </button>
          </form>
        </div>
      )}

      {/* Schedules List */}
      <div className="bg-gray-900 rounded-xl border border-gray-800 overflow-hidden">
        {schedules.length === 0 ? (
          <div className="p-12 text-center">
            <p className="text-4xl mb-4">📅</p>
            <p className="text-xl text-gray-400">No schedules created</p>
            <p className="text-sm text-gray-600 mt-2">
              Create schedules to control when media is displayed
            </p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-800">
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Name
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Media
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Time
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Days
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Status
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {schedules.map((schedule) => (
                <tr
                  key={schedule.id}
                  className="border-b border-gray-800/50 hover:bg-gray-800/30"
                >
                  <td className="px-6 py-4 font-medium">
                    {schedule.name || 'Unnamed'}
                  </td>
                  <td className="px-6 py-4 text-gray-400">
                    {getMediaTitle(schedule.media_id)}
                  </td>
                  <td className="px-6 py-4 text-gray-400">
                    {schedule.start_time.slice(0, 5)} -{' '}
                    {schedule.end_time.slice(0, 5)}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-1">
                      {DAYS.map((day, idx) => (
                        <span
                          key={day}
                          className={`text-xs px-1 ${
                            schedule.days_of_week.includes(idx)
                              ? 'text-blue-400'
                              : 'text-gray-700'
                          }`}
                        >
                          {day.charAt(0)}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() =>
                        toggleSchedule(schedule.id, schedule.is_active)
                      }
                      className={`px-3 py-1 rounded-full text-xs font-medium cursor-pointer ${
                        schedule.is_active
                          ? 'bg-green-900 text-green-300'
                          : 'bg-gray-700 text-gray-400'
                      }`}
                    >
                      {schedule.is_active ? '● Active' : '○ Inactive'}
                    </button>
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => deleteSchedule(schedule.id)}
                      className="px-3 py-1 bg-red-900/50 hover:bg-red-900 text-red-400 rounded text-sm transition-colors"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
