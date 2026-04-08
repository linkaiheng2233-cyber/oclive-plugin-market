<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { PACK_BRANCH_KINDS, PACK_BRANCH_LABELS } from '../../types'

const route = useRoute()

const isDetail = computed(() => route.name === 'pack-detail')

const subLinks = computed(() => {
  const part = PACK_BRANCH_KINDS.map((k) => ({
    to: `/packs/part/${k}`,
    label: PACK_BRANCH_LABELS[k],
    kind: k,
  }))
  return [
    { to: '/packs/full', label: '完整角色包' },
    ...part,
    { to: '/packs/compose', label: '模块组合' },
  ]
})

function linkActive(to: string) {
  if (to === '/packs/full') {
    return route.path === '/packs/full' || route.path === '/packs' || route.path === '/packs/'
  }
  return route.path === to || route.path.startsWith(`${to}/`)
}
</script>

<template>
  <div class="packs-layout">
    <div v-if="!isDetail" class="subnav-wrap">
      <p class="eyebrow">角色包</p>
      <h1 class="title">按模块浏览与组合</h1>
      <p class="lead">
        完整包以图集展示；各子页可筛选单类素材（场景、人设、身份、世界观、日程）。在「模块组合」里用搜索框挑选并拼成一套，后续可接入导入 OCLive。
      </p>
      <nav class="subnav" aria-label="角色包子导航">
        <RouterLink
          v-for="l in subLinks"
          :key="l.to"
          :to="l.to"
          class="sub-link"
          :class="{ 'sub-link--active': linkActive(l.to) }"
        >
          {{ l.label }}
        </RouterLink>
      </nav>
    </div>
    <RouterView />
  </div>
</template>

<style scoped>
.packs-layout {
  max-width: 1120px;
  margin: 0 auto;
  padding: 0 18px 32px;
}

.subnav-wrap {
  margin-bottom: 22px;
}

.eyebrow {
  margin: 0 0 4px;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--fg-soft);
}

.title {
  margin: 0 0 8px;
  font-size: 1.45rem;
  letter-spacing: -0.02em;
}

.lead {
  margin: 0 0 16px;
  color: var(--fg-muted);
  font-size: 0.92rem;
  line-height: 1.55;
  max-width: 62ch;
}

.subnav {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 10px;
}

.sub-link {
  display: inline-flex;
  align-items: center;
  padding: 7px 12px;
  font-size: 0.84rem;
  font-weight: 500;
  text-decoration: none;
  color: var(--fg-muted);
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  transition:
    color 0.15s ease,
    border-color 0.15s ease,
    background 0.15s ease;
}

.sub-link:hover {
  color: var(--accent);
  border-color: var(--accent-soft);
}

.sub-link--active {
  color: var(--accent);
  border-color: color-mix(in srgb, var(--accent) 45%, var(--border));
  background: color-mix(in srgb, var(--accent) 8%, var(--surface));
  font-weight: 600;
}
</style>
