<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { getSupabaseClient } from '../lib/supabase'
import { CONTENT_ITEM_SELECT, mapContentRow, type ContentItemRow } from '../lib/contentItems'
import type { ContentItem } from '../types'

const supabase = getSupabaseClient()

const latestAnnouncement = ref<ContentItem | null>(null)
const loadingAnn = ref(false)

onMounted(async () => {
  if (!supabase) return
  loadingAnn.value = true
  const { data, error } = await supabase
    .from('content_items')
    .select(CONTENT_ITEM_SELECT)
    .eq('status', 'published')
    .eq('type', 'announcement')
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  loadingAnn.value = false
  if (error || !data) {
    latestAnnouncement.value = null
    return
  }
  latestAnnouncement.value = mapContentRow(data as ContentItemRow)
})

const hub = [
  { to: '/browse', title: '浏览资源', desc: '查看社区已发布的角色包、插件、模块与分支', primary: true },
  { to: '/submit', title: '发布资源', desc: '登录后提交下载链接与说明', primary: true },
  { to: '/announcements', title: '公告', desc: '维护通知与社区公告', primary: false },
  { to: '/versions', title: '版本与下载', desc: '启动器、应用与文档链接', primary: false },
  { to: '/me', title: '个人设置', desc: '登录与资料', primary: false },
  { to: '/manage', title: '我的上传', desc: '管理你已提交的内容', primary: false },
]
</script>

<template>
  <div class="home">
    <section v-if="loadingAnn" class="ann ann--loading" aria-live="polite">加载公告…</section>
    <section v-else-if="latestAnnouncement" class="ann">
      <span class="ann-label">最新公告</span>
      <RouterLink class="ann-link" :to="{ name: 'item-detail', params: { id: latestAnnouncement.id } }">
        {{ latestAnnouncement.title }}
      </RouterLink>
    </section>

    <header class="hero">
      <p class="eyebrow">Oclive 插件市场 · 社区站</p>
      <h1>资源发现与发布</h1>
      <p class="lead">浏览他人作品、提交你的下载链接；后续将接入更多社区能力。</p>
    </header>

    <section class="tiles" aria-label="功能入口">
      <RouterLink v-for="t in hub" :key="t.to" :to="t.to" class="tile" :class="{ 'tile--primary': t.primary }">
        <span class="tile-k">{{ t.title }}</span>
        <span class="tile-d">{{ t.desc }}</span>
      </RouterLink>
      <div class="tile tile--disabled" aria-disabled="true">
        <span class="tile-k">论坛</span>
        <span class="tile-d">即将开放</span>
      </div>
    </section>

    <p v-if="!supabase" class="warn">未配置 Supabase 环境变量时，浏览与发布不可用。请参阅 README。</p>
  </div>
</template>

<style scoped>
.home {
  padding-bottom: 24px;
}
.ann {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 8px 14px;
  padding: 12px 14px;
  margin-bottom: 20px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--accent) 8%, var(--surface));
}
.ann--loading {
  color: var(--fg-muted);
  font-size: 0.9rem;
}
.ann-label {
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--accent);
}
.ann-link {
  font-weight: 600;
  color: var(--fg);
  text-decoration: none;
}
.ann-link:hover {
  text-decoration: underline;
  color: var(--accent);
}
.hero {
  margin-bottom: 24px;
}
.eyebrow {
  margin: 0 0 8px;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--accent);
}
h1 {
  margin: 0 0 12px;
  font-size: clamp(1.45rem, 3.5vw, 1.85rem);
  letter-spacing: -0.03em;
}
.lead {
  margin: 0;
  max-width: 54ch;
  color: var(--fg-muted);
  line-height: 1.6;
  font-size: 1.02rem;
}
.tiles {
  display: grid;
  gap: 14px;
  grid-template-columns: 1fr;
}
@media (min-width: 560px) {
  .tiles {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (min-width: 900px) {
  .tiles {
    grid-template-columns: repeat(3, 1fr);
  }
}
.tile {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--surface);
  text-decoration: none;
  color: inherit;
  box-shadow: var(--shadow);
  transition: border-color 0.15s ease, transform 0.15s ease;
  min-height: 100px;
}
.tile:not(.tile--disabled):hover {
  border-color: var(--accent-soft);
  transform: translateY(-1px);
}
.tile--primary {
  border-color: color-mix(in srgb, var(--accent) 35%, var(--border));
}
.tile--disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.tile-k {
  font-weight: 700;
  font-size: 1.02rem;
}
.tile-d {
  font-size: 0.88rem;
  color: var(--fg-muted);
  line-height: 1.45;
}
.warn {
  margin-top: 20px;
  padding: 12px;
  border-radius: 10px;
  background: color-mix(in srgb, var(--danger) 12%, var(--surface));
  color: var(--fg-muted);
  font-size: 0.9rem;
}
</style>
