'use client';

import { useEffect, useState, useCallback } from 'react';
import { type MediaItem } from '@/lib/supabase';

export default function MediaPage() {
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [showUpload, setShowUpload] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadForm, setUploadForm] = useState({
    title: '',
    description: '',
    type: 'image' as 'image' | 'video',
    duration_seconds: 10,
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);

  const fetchMedia = useCallback(async () => {
    try {
      const res = await fetch('/api/media');
      const { data } = await res.json();
      setMedia(data || []);
    } catch (err) {
      console.error('Error fetching media:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMedia();
  }, [fetchMedia]);

  async function handleUpload(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedFile) return;

    setUploading(true);
    setUploadProgress(0);

    try {
      // 1. Upload file to server
      const formData = new FormData();
      formData.append('file', selectedFile);

      setUploadProgress(30);

      const uploadRes = await fetch('/api/upload', { method: 'POST', body: formData });
      const uploadData = await uploadRes.json();
      if (!uploadRes.ok) throw new Error(uploadData.error);

      setUploadProgress(60);

      // 2. Insert media record
      const insertRes = await fetch('/api/media', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: uploadForm.title,
          description: uploadForm.description || null,
          type: uploadForm.type,
          url: uploadData.url,
          bucket_path: uploadData.path,
          duration_seconds: uploadForm.duration_seconds,
          file_size_bytes: selectedFile.size,
          mime_type: selectedFile.type,
          is_active: true,
          display_order: media.length,
        }),
      });
      if (!insertRes.ok) throw new Error('Failed to save media record');

      setUploadProgress(80);

      setUploadProgress(100);

      // Reset form
      setShowUpload(false);
      setSelectedFile(null);
      setUploadForm({
        title: '',
        description: '',
        type: 'image',
        duration_seconds: 10,
      });

      // Refresh media list
      await fetchMedia();
    } catch (err) {
      console.error('Upload error:', err);
      alert('Failed to upload: ' + (err as Error).message);
    } finally {
      setUploading(false);
      setUploadProgress(0);
    }
  }

  async function toggleActive(id: string, currentActive: boolean) {
    try {
      await fetch(`/api/media/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_active: !currentActive }),
      });
      await fetchMedia();
    } catch (err) {
      console.error('Toggle error:', err);
    }
  }

  async function deleteMedia(id: string, _bucketPath: string) {
    if (!confirm('Are you sure you want to delete this media?')) return;

    try {
      await fetch(`/api/media/${id}`, { method: 'DELETE' });
      await fetchMedia();
    } catch (err) {
      console.error('Delete error:', err);
    }
  }

  async function moveOrder(id: string, direction: 'up' | 'down') {
    const index = media.findIndex((m) => m.id === id);
    if (
      (direction === 'up' && index === 0) ||
      (direction === 'down' && index === media.length - 1)
    )
      return;

    const swapIndex = direction === 'up' ? index - 1 : index + 1;

    try {
      await fetch(`/api/media/${media[index].id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ display_order: swapIndex }),
      });
      await fetch(`/api/media/${media[swapIndex].id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ display_order: index }),
      });

      await fetchMedia();
    } catch (err) {
      console.error('Reorder error:', err);
    }
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    setSelectedFile(file);

    // Auto-detect type
    if (file.type.startsWith('video/')) {
      setUploadForm((prev) => ({ ...prev, type: 'video' }));
    } else {
      setUploadForm((prev) => ({ ...prev, type: 'image' }));
    }

    // Auto-fill title from filename
    if (!uploadForm.title) {
      const name = file.name.replace(/\.[^/.]+$/, '').replace(/[-_]/g, ' ');
      setUploadForm((prev) => ({ ...prev, title: name }));
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
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Media Management</h1>
        <button
          onClick={() => setShowUpload(!showUpload)}
          className="px-6 py-3 bg-blue-600 hover:bg-blue-700 rounded-lg font-medium transition-colors"
        >
          {showUpload ? '✕ Cancel' : '+ Upload Media'}
        </button>
      </div>

      {/* Upload Form */}
      {showUpload && (
        <div className="bg-gray-900 rounded-xl border border-gray-800 p-6 mb-8">
          <h2 className="text-xl font-semibold mb-4">Upload New Media</h2>
          <form onSubmit={handleUpload} className="space-y-4">
            {/* File Input */}
            <div
              className="border-2 border-dashed border-gray-700 rounded-lg p-8 text-center cursor-pointer hover:border-blue-500 transition-colors"
              onClick={() => document.getElementById('file-input')?.click()}
            >
              <input
                id="file-input"
                type="file"
                accept="image/*,video/*"
                className="hidden"
                onChange={handleFileSelect}
              />
              {selectedFile ? (
                <div>
                  <p className="text-lg font-medium">{selectedFile.name}</p>
                  <p className="text-sm text-gray-400 mt-1">
                    {(selectedFile.size / 1024 / 1024).toFixed(2)} MB •{' '}
                    {selectedFile.type}
                  </p>
                </div>
              ) : (
                <div>
                  <p className="text-4xl mb-2">📤</p>
                  <p className="text-gray-400">
                    Click to select an image or video file
                  </p>
                  <p className="text-sm text-gray-600 mt-1">
                    Supports: JPG, PNG, GIF, MP4, WebM
                  </p>
                </div>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Title *
                </label>
                <input
                  type="text"
                  required
                  value={uploadForm.title}
                  onChange={(e) =>
                    setUploadForm((prev) => ({ ...prev, title: e.target.value }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                  placeholder="Ad title"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Type
                </label>
                <select
                  value={uploadForm.type}
                  onChange={(e) =>
                    setUploadForm((prev) => ({
                      ...prev,
                      type: e.target.value as 'image' | 'video',
                    }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                >
                  <option value="image">Image</option>
                  <option value="video">Video</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Description
                </label>
                <input
                  type="text"
                  value={uploadForm.description}
                  onChange={(e) =>
                    setUploadForm((prev) => ({
                      ...prev,
                      description: e.target.value,
                    }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                  placeholder="Optional description"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">
                  Display Duration (seconds)
                </label>
                <input
                  type="number"
                  min="3"
                  max="300"
                  value={uploadForm.duration_seconds}
                  onChange={(e) =>
                    setUploadForm((prev) => ({
                      ...prev,
                      duration_seconds: parseInt(e.target.value) || 10,
                    }))
                  }
                  className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:border-blue-500 focus:outline-none"
                />
              </div>
            </div>

            {/* Upload Progress */}
            {uploading && (
              <div className="w-full bg-gray-800 rounded-full h-2">
                <div
                  className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${uploadProgress}%` }}
                />
              </div>
            )}

            <button
              type="submit"
              disabled={!selectedFile || uploading}
              className="w-full py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:cursor-not-allowed rounded-lg font-medium transition-colors"
            >
              {uploading ? `Uploading... ${uploadProgress}%` : 'Upload Media'}
            </button>
          </form>
        </div>
      )}

      {/* Media Table */}
      <div className="bg-gray-900 rounded-xl border border-gray-800 overflow-hidden">
        {media.length === 0 ? (
          <div className="p-12 text-center">
            <p className="text-4xl mb-4">🎬</p>
            <p className="text-xl text-gray-400">No media uploaded yet</p>
            <p className="text-sm text-gray-600 mt-2">
              Click &quot;Upload Media&quot; to add your first ad
            </p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-800">
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Order
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Title
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Type
                </th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-400">
                  Duration
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
              {media.map((item, index) => (
                <tr
                  key={item.id}
                  className="border-b border-gray-800/50 hover:bg-gray-800/30"
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => moveOrder(item.id, 'up')}
                        disabled={index === 0}
                        className="p-1 hover:bg-gray-700 rounded disabled:opacity-30"
                      >
                        ▲
                      </button>
                      <span className="text-gray-500 w-6 text-center">
                        {index + 1}
                      </span>
                      <button
                        onClick={() => moveOrder(item.id, 'down')}
                        disabled={index === media.length - 1}
                        className="p-1 hover:bg-gray-700 rounded disabled:opacity-30"
                      >
                        ▼
                      </button>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div>
                      <p className="font-medium">{item.title}</p>
                      {item.description && (
                        <p className="text-sm text-gray-500">
                          {item.description}
                        </p>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="flex items-center gap-2">
                      {item.type === 'video' ? '🎥' : '🖼️'}{' '}
                      {item.type}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-400">
                    {item.duration_seconds}s
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => toggleActive(item.id, item.is_active)}
                      className={`px-3 py-1 rounded-full text-xs font-medium transition-colors cursor-pointer ${
                        item.is_active
                          ? 'bg-green-900 text-green-300 hover:bg-green-800'
                          : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
                      }`}
                    >
                      {item.is_active ? '● Active' : '○ Inactive'}
                    </button>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <a
                        href={item.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded text-sm transition-colors"
                      >
                        Preview
                      </a>
                      <button
                        onClick={() => deleteMedia(item.id, item.bucket_path)}
                        className="px-3 py-1 bg-red-900/50 hover:bg-red-900 text-red-400 rounded text-sm transition-colors"
                      >
                        Delete
                      </button>
                    </div>
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
