import type { ContentItem } from '../types'

export const CONTENT_ITEM_SELECT =
  'id,type,title,description,tags,author_id,status,download_url,version,metadata,download_count,created_at,updated_at,last_published_at,profiles(username)'

export type ContentItemRow = ContentItem & { profiles?: { username?: string } | null }

export function mapContentRow(row: ContentItemRow): ContentItem {
  const { profiles, ...rest } = row
  return {
    ...rest,
    author_name: profiles?.username ?? '',
  }
}
