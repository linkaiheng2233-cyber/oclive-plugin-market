<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getSupabaseClient } from '../lib/supabase'
import type { ForumCategory } from '../lib/forumApi'
import { listForumCategories } from '../lib/forumApi'

const { t } = useI18n()
const supabase = getSupabaseClient()

const loading = ref(false)
const err = ref('')
const cats = ref<ForumCategory[]>([])

async function load() {
  if (!supabase) return
  loading.value = true
  err.value = ''
  const { data, error } = await listForumCategories(supabase)
  loading.value = false
  if (error) {
    err.value = error.message
    return
  }
  cats.value = (data ?? []) as ForumCategory[]
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="page-head">
    <h1>{{ t('market.forum.title') }}</h1>
    <p class="sub">{{ t('market.forum.sub') }}</p>
  </div>

  <p v-if="!supabase" class="warn">{{ t('market.noSupabase') }}</p>
  <p v-else-if="loading" class="state">{{ t('market.loading') }}</p>
  <p v-else-if="err" class="state err">{{ err }}</p>
  <ul v-else class="cats">
    <li v-for="c in cats" :key="c.id" class="cat">
      <RouterLink class="cat-link" :to="`/forum/${c.slug}`">
        <div class="cat-top">
          <span class="cat-title">{{ c.title }}</span>
          <span v-if="c.is_locked" class="badge">{{ t('market.forum.badgeReadOnly') }}</span>
        </div>
        <p class="cat-desc">{{ c.description }}</p>
      </RouterLink>
    </li>
  </ul>
</template>

<style scoped>
.page-head {
  margin-bottom: 16px;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
}
.warn {
  color: var(--danger);
}
.state.err {
  color: var(--danger);
}
.cats {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.cat {
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface);
  box-shadow: var(--shadow);
}
.cat-link {
  display: block;
  padding: 14px;
  text-decoration: none;
  color: inherit;
}
.cat-link:hover .cat-title {
  color: var(--accent);
}
.cat-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}
.cat-title {
  font-weight: 800;
}
.cat-desc {
  margin: 6px 0 0;
  color: var(--fg-muted);
  line-height: 1.55;
}
.badge {
  font-size: 0.78rem;
  padding: 4px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-soft);
}
</style>
