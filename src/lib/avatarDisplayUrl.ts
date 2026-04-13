import type { SupabaseClient } from '@supabase/supabase-js'

/** 从「公开 URL」里取出 Storage 内路径，例如 .../public/avatars/<uuid>/avatar.jpg → <uuid>/avatar.jpg */
export function extractPublicAvatarsPath(storedUrl: string): string | null {
  const t = storedUrl.trim()
  if (!t) return null
  const m = t.match(/\/object\/public\/avatars\/([^?#]+)/)
  if (!m?.[1]) return null
  try {
    return decodeURIComponent(m[1])
  } catch {
    return m[1]
  }
}

/**
 * 优先用短时 signed URL 展示头像，避免仅依赖 public URL 时因桶策略/Referer 等导致不显示。
 */
export async function resolveAvatarForDisplay(
  supabase: SupabaseClient | null,
  storedUrl: string
): Promise<string> {
  const t = storedUrl.trim()
  if (!t) return ''
  if (!supabase) return t
  const path = extractPublicAvatarsPath(t)
  if (!path) return t
  const { data, error } = await supabase.storage.from('avatars').createSignedUrl(path, 3600)
  if (error || !data?.signedUrl) return t
  return data.signedUrl
}
