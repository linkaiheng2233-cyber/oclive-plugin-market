import type { SupabaseClient } from '@supabase/supabase-js'

export type ForumThreadStatus = 'published' | 'hidden' | 'locked'
export type ForumPostStatus = 'published' | 'hidden'
export type ForumReportStatus = 'open' | 'handled' | 'rejected'
export type ForumReportReason = 'spam' | 'abuse' | 'illegal' | 'other'
export type ForumReportTargetType = 'thread' | 'post'

export interface ForumCategory {
  id: string
  slug: string
  title: string
  description: string
  sort_order: number
  is_locked: boolean
  created_at: string
  updated_at: string
}

export interface ForumThread {
  id: string
  category_id: string
  author_id: string
  title: string
  status: ForumThreadStatus
  tags: string[]
  reply_count: number
  last_reply_at: string | null
  created_at: string
  updated_at: string
}

export interface ForumPost {
  id: string
  thread_id: string
  author_id: string
  content: string
  floor: number
  status: ForumPostStatus
  created_at: string
  updated_at: string
}

export interface ForumProfileLite {
  id: string
  username: string
  avatar_url: string
  donation_url?: string
  donation_qr_url?: string
}

export interface ForumReport {
  id: string
  target_type: ForumReportTargetType
  target_id: string
  reporter_id: string
  reason_code: ForumReportReason
  reason_text: string
  status: ForumReportStatus
  created_at: string
  updated_at: string
}

export interface ForumModerationAction {
  id: string
  actor_id: string
  action: 'hide_thread' | 'hide_post' | 'lock_thread' | 'ban_user' | 'unban_user' | 'note'
  target_type: string
  target_id: string
  note: string
  created_at: string
}

export async function listForumCategories(supabase: SupabaseClient) {
  return await supabase.from('forum_categories').select('*').order('sort_order', { ascending: true })
}

export async function getForumCategoryBySlug(supabase: SupabaseClient, slug: string) {
  return await supabase.from('forum_categories').select('*').eq('slug', slug).maybeSingle()
}

export async function listThreadsByCategory(supabase: SupabaseClient, categoryId: string, limit = 40) {
  return await supabase
    .from('forum_threads')
    .select('*')
    .eq('category_id', categoryId)
    .order('updated_at', { ascending: false })
    .limit(limit)
}

export async function getThread(supabase: SupabaseClient, threadId: string) {
  return await supabase.from('forum_threads').select('*').eq('id', threadId).maybeSingle()
}

export async function listThreadPosts(supabase: SupabaseClient, threadId: string, limit = 200) {
  return await supabase
    .from('forum_posts')
    .select('*')
    .eq('thread_id', threadId)
    .order('floor', { ascending: true })
    .limit(limit)
}

export async function getProfileLite(supabase: SupabaseClient, userId: string) {
  return await supabase
    .from('profiles')
    .select('id,username,avatar_url,donation_url,donation_qr_url')
    .eq('id', userId)
    .maybeSingle()
}

export async function createThreadWithFirstPost(args: {
  supabase: SupabaseClient
  categoryId: string
  authorId: string
  title: string
  content: string
  tags: string[]
}) {
  const { supabase, categoryId, authorId, title, content, tags } = args
  const { data: thread, error: tErr } = await supabase
    .from('forum_threads')
    .insert({
      category_id: categoryId,
      author_id: authorId,
      title,
      tags,
      status: 'published',
    })
    .select('*')
    .single()
  if (tErr || !thread) return { thread: null as ForumThread | null, error: tErr }

  const { data: post, error: pErr } = await supabase
    .from('forum_posts')
    .insert({
      thread_id: thread.id,
      author_id: authorId,
      content,
      status: 'published',
      floor: 0, // assigned by trigger
    })
    .select('*')
    .single()
  if (pErr || !post) return { thread: thread as ForumThread, post: null as ForumPost | null, error: pErr }

  return { thread: thread as ForumThread, post: post as ForumPost, error: null }
}

export async function createReply(args: { supabase: SupabaseClient; threadId: string; authorId: string; content: string }) {
  const { supabase, threadId, authorId, content } = args
  return await supabase
    .from('forum_posts')
    .insert({ thread_id: threadId, author_id: authorId, content, status: 'published', floor: 0 })
    .select('*')
    .single()
}

export async function createReport(args: {
  supabase: SupabaseClient
  targetType: ForumReportTargetType
  targetId: string
  reporterId: string
  reasonCode: ForumReportReason
  reasonText?: string
}) {
  const { supabase, targetType, targetId, reporterId, reasonCode, reasonText } = args
  return await supabase
    .from('forum_reports')
    .insert({
      target_type: targetType,
      target_id: targetId,
      reporter_id: reporterId,
      reason_code: reasonCode,
      reason_text: (reasonText ?? '').trim(),
      status: 'open',
    })
    .select('id')
    .single()
}

