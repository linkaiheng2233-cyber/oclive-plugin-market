/** 侧车插件（Remote），面向使用者的列表项 */
export interface PluginListing {
  id: string
  name: string
  description: string
  repo_url: string
  min_oclive_version: string
  tags: string[]
  author: string
}

/** 角色包详情子页：场景 / 人设 / 身份 / 世界观 */
export interface CharacterPackSections {
  scene: string
  persona: string
  identity: string
  world: string
}

export type PackBranchKind = keyof CharacterPackSections

/** 角色包单独分支素材（可用于自由组合） */
export interface PackBranch {
  id: string
  name: string
  kind: PackBranchKind
  intro: string
  content: string
  preview_image: string
  link: string
  author: string
}

/** 角色包（图集入口，点进看详情） */
export interface CharacterPack {
  id: string
  name: string
  intro: string
  preview_image: string
  link: string
  author: string
  sections: CharacterPackSections
}

/** 可替换软件模块（记忆、情感等） */
export interface SoftwareModule {
  id: string
  name: string
  intro: string
  preview_image: string
  link: string
  author: string
  kind: string
  tags: string[]
}

export interface SiteData {
  character_packs: CharacterPack[]
  plugins: PluginListing[]
  modules: SoftwareModule[]
  pack_branches: PackBranch[]
}

export type ContentType = 'character' | 'plugin' | 'module' | 'branch'
export type ContentStatus = 'published' | 'hidden'

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
