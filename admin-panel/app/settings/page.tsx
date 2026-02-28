'use client';

import { useEffect, useState, useCallback } from 'react';
import { type AppSetting } from '@/lib/supabase';

export default function SettingsPage() {
  const [settings, setSettings] = useState<AppSetting[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);
  const [editValues, setEditValues] = useState<Record<string, string>>({});

  const fetchSettings = useCallback(async () => {
    try {
      const res = await fetch('/api/settings');
      const { data } = await res.json();

      if (data) {
        setSettings(data);
        const values: Record<string, string> = {};
        data.forEach((s: AppSetting) => {
          values[s.key] =
            typeof s.value === 'string'
              ? s.value.replace(/^"|"$/g, '')
              : String(s.value);
        });
        setEditValues(values);
      }
    } catch (err) {
      console.error('Error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  async function saveSetting(key: string) {
    setSaving(key);
    try {
      let value: unknown = editValues[key];

      // Try to parse as JSON (for booleans, numbers)
      if (value === 'true') value = true;
      else if (value === 'false') value = false;
      else if (!isNaN(Number(value)) && value !== '') value = `"${value}"`;
      else value = `"${value}"`;

      const res = await fetch(`/api/settings/${key}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ value }),
      });

      if (!res.ok) throw new Error('Failed to save');

      await fetchSettings();
    } catch (err) {
      console.error('Save error:', err);
      alert('Failed to save setting');
    } finally {
      setSaving(null);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" />
      </div>
    );
  }

  const settingLabels: Record<string, { label: string; description: string }> = {
    ad_rotation_interval: {
      label: 'Ad Rotation Interval',
      description: 'Time in seconds between ad transitions (for images)',
    },
    pip_enabled: {
      label: 'PIP Mode Enabled',
      description: 'Allow Picture-in-Picture mode on TV app',
    },
    cliniqtv_package: {
      label: 'CliniqTV Package Name',
      description: 'Android package name of the queue management app',
    },
    display_mode: {
      label: 'Default Display Mode',
      description: 'Default display mode: fullscreen or pip',
    },
    marquee_text: {
      label: 'Marquee Text',
      description: 'Scrolling text displayed at the bottom of the TV screen',
    },
  };

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Settings</h1>

      <div className="space-y-4">
        {settings.map((setting) => {
          const meta = settingLabels[setting.key] || {
            label: setting.key,
            description: setting.description || '',
          };

          return (
            <div
              key={setting.id}
              className="bg-gray-900 rounded-xl border border-gray-800 p-6"
            >
              <div className="flex items-start justify-between gap-8">
                <div className="flex-1">
                  <h3 className="font-semibold text-lg">{meta.label}</h3>
                  <p className="text-sm text-gray-500 mt-1">
                    {meta.description}
                  </p>
                  <p className="text-xs text-gray-600 mt-1">
                    Key: <code className="bg-gray-800 px-2 py-0.5 rounded">{setting.key}</code>
                  </p>
                </div>
                <div className="flex items-center gap-3 min-w-[400px]">
                  {setting.key === 'pip_enabled' ? (
                    <select
                      value={editValues[setting.key] || 'true'}
                      onChange={(e) =>
                        setEditValues((prev) => ({
                          ...prev,
                          [setting.key]: e.target.value,
                        }))
                      }
                      className="flex-1 px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                    >
                      <option value="true">Enabled</option>
                      <option value="false">Disabled</option>
                    </select>
                  ) : setting.key === 'display_mode' ? (
                    <select
                      value={editValues[setting.key] || 'fullscreen'}
                      onChange={(e) =>
                        setEditValues((prev) => ({
                          ...prev,
                          [setting.key]: e.target.value,
                        }))
                      }
                      className="flex-1 px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                    >
                      <option value="fullscreen">Fullscreen</option>
                      <option value="pip">PIP (Picture-in-Picture)</option>
                    </select>
                  ) : (
                    <input
                      type={
                        setting.key === 'ad_rotation_interval' ? 'number' : 'text'
                      }
                      value={editValues[setting.key] || ''}
                      onChange={(e) =>
                        setEditValues((prev) => ({
                          ...prev,
                          [setting.key]: e.target.value,
                        }))
                      }
                      className="flex-1 px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                    />
                  )}
                  <button
                    onClick={() => saveSetting(setting.key)}
                    disabled={saving === setting.key}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 rounded-lg font-medium transition-colors text-sm whitespace-nowrap"
                  >
                    {saving === setting.key ? 'Saving...' : 'Save'}
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Info Box */}
      <div className="mt-8 bg-blue-950/30 border border-blue-900 rounded-xl p-6">
        <h3 className="font-semibold text-blue-400 mb-2">
          ℹ️ How Settings Work
        </h3>
        <ul className="text-sm text-gray-400 space-y-1">
          <li>
            • Changes are synced in real-time to all connected TV devices
          </li>
          <li>• The TV app checks for setting updates automatically</li>
          <li>
            • The marquee text appears at the bottom of the TV display screen
          </li>
          <li>• Ad rotation interval only affects image ads (videos play fully)</li>
        </ul>
      </div>
    </div>
  );
}
