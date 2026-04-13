/** 侧车插件（Remote），历史类型保留供文档引用 */
export interface PluginListing {
  id: string
  name: string
  description: string
  repo_url: string
  min_oclive_version: string
  tags: string[]
  author: string
}

export type ContentType = 'character' | 'plugin' | 'module' | 'branch' | 'announcement'
export type ContentStatus = 'published' | 'hidden'

/** 浏览页展示的资源类型（不含公告） */
export const RESOURCE_TYPES: ContentType[] = ['character', 'plugin', 'module', 'branch']

export const CONTENT_TYPE_LABELS: Record<ContentType, string> = {
  character: '角色包',
  plugin: '插件',
  module: '模块',
  branch: '分支',
  announcement: '公告',
}

export interface ContentItem {
  id: string
  type: ContentType
  title: string
  description: string
  tags: string[]
  author_id: string
  author_name?: string
  status: ContentStatus
  download_url: string
  version: string
  metadata: Record<string, unknown>
  download_count: number
  created_at: string
  updated_at: string
  last_published_at?: string
}

export interface Profile {
  id: string
  username: string
  avatar_url: string
  is_admin: boolean
  created_at: string
  updated_at: string
}
