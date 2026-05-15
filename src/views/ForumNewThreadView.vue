<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter, useRoute, RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'
import type { ForumCategory } from '../lib/forumApi'
import { createThreadWithFirstPost, getForumCategoryBySlug, listForumCategories } from '../lib/forumApi'

const { t } = useI18n()
const supabase = getSupabaseClient()
const router = useRouter()
const route = useRoute()
const { userId } = useAuthContext()

const qSlug = computed(() => String(route.query.category || ''))

const loading = ref(false)
const err = ref('')
const info = ref('')

const categories = ref<ForumCategory[]>([])
const category = ref<ForumCategory | null>(null)

const title = ref('')
const content = ref('')
const tagsInput = ref('')

const canSubmit = computed(() => !!supabase && !!userId.value && !!category.value && title.value.trim() && content.value.trim())

function toast(msg: string) {
  info.value = msg
  window.setTimeout(() => {
    if (info.value === msg) info.value = ''
  }, 2400)
}

async function loadCategories() {
  if (!supabase) return
  const { data, error } = await listForumCategories(supabase)
  if (error) {
    err.value = error.message
    return
  }
  categories.value = (data ?? []) as ForumCategory[]
}

async function resolveCategory() {
  if (!supabase) return
  category.value = null
  err.value = ''
  if (qSlug.value) {
    const { data, error } = await getForumCategoryBySlug(supabase, qSlug.value)
    if (error) {
      err.value = error.message
      return
    }
    category.value = (data ?? null) as ForumCategory | null
  } else {
    category.value = categories.value[0] ?? null
  }
}

async function submit() {
  if (!supabase) return
  if (!userId.value) {
    await router.push({ name: 'personal', query: { redirect: route.fullPath } })
    return
  }
  if (!category.value) return
  if (category.value.is_locked) {
    toast(t('market.forum.toastCategoryReadOnly'))
    return
  }
  loading.value = true
  err.value = ''
  const tags = tagsInput.value
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean)
    .slice(0, 8)

  const { thread, error } = await createThreadWithFirstPost({
    supabase,
    categoryId: category.value.id,
    authorId: userId.value,
    title: title.value.trim(),
    content: content.value.trim(),
    tags,
  })
  loading.value = false
  if (error || !thread) {
    err.value = error?.message || t('market.forum.errSubmitFailed')
    return
  }
  toast(t('market.forum.toastThreadCreated'))
  await router.push(`/t/${thread.id}`)
}

watch(qSlug, () => void resolveCategory())
onMounted(async () => {
  await loadCategories()
  await resolveCategory()
})
</script>

<template>
  <div class="crumb">
    <RouterLink to="/forum">{{ t('market.forum.crumbForum') }}</RouterLink>
    <span class="sep">/</span>
    <span>{{ t('market.forum.crumbNewThread') }}</span>
  </div>

  <div class="page-head">
    <h1>{{ t('market.forum.crumbNewThread') }}</h1>
    <p class="sub">{{ t('market.forum.newThreadPageSub') }}</p>
  </div>

  <p v-if="info" class="info">{{ info }}</p>
  <p v-if="!supabase" class="warn">{{ t('market.noSupabase') }}</p>
  <p v-else-if="!userId" class="warn">
    {{ t('market.forum.notLoggedInLead') }}
    <RouterLink :to="`/me?redirect=${encodeURIComponent(route.fullPath)}`">{{ t('market.forum.goSignIn') }}</RouterLink>
    {{ t('market.forum.thenCreateThread') }}
  </p>

  <section v-else class="card">
    <p v-if="err" class="err">{{ err }}</p>

    <label class="field">
      <span>{{ t('market.forum.fieldCategory') }}</span>
      <select v-model="category" :disabled="!!qSlug">
        <option v-for="c in categories" :key="c.id" :value="c">
          {{ c.title }}{{ c.is_locked ? t('market.forum.optionLockedSuffix') : '' }}
        </option>
      </select>
    </label>

    <label class="field">
      <span>{{ t('market.forum.fieldTitle') }}</span>
      <input v-model="title" :placeholder="t('market.forum.titlePlaceholder')" maxlength="120" />
    </label>

    <label class="field">
      <span>{{ t('market.forum.fieldContent') }}</span>
      <textarea v-model="content" rows="10" :placeholder="t('market.forum.contentPlaceholder')" />
    </label>

    <label class="field">
      <span>{{ t('market.forum.fieldTags') }}</span>
      <input v-model="tagsInput" :placeholder="t('market.forum.tagsPlaceholder')" />
    </label>

    <div class="ops">
      <button :disabled="loading || !canSubmit" @click="submit">
        {{ loading ? t('market.forum.submitting') : t('market.submitBtn') }}
      </button>
      <RouterLink class="ghost" :to="category ? `/forum/${category.slug}` : '/forum'">{{ t('market.forum.back') }}</RouterLink>
    </div>
  </section>
</template>

<style scoped>
.crumb {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.85rem;
  color: var(--fg-soft);
  margin-bottom: 12px;
}
.crumb a {
  color: var(--accent);
  text-decoration: none;
}
.sep {
  opacity: 0.7;
}
.page-head {
  margin-bottom: 16px;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
}
.info {
  margin: 0 0 12px;
  color: var(--accent);
}
.warn {
  color: var(--danger);
}
.card {
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface);
  padding: 14px;
  max-width: 760px;
}
.err {
  margin: 0 0 10px;
  color: var(--danger);
}
.field {
  display: grid;
  gap: 6px;
  margin-bottom: 12px;
}
.field span {
  font-size: 0.82rem;
  color: var(--fg-soft);
}
input,
textarea,
select {
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
  padding: 9px 10px;
  font: inherit;
  color: inherit;
}
textarea {
  resize: vertical;
}
.ops {
  display: flex;
  gap: 10px;
  align-items: center;
}
button {
  border: 1px solid var(--border);
  background: var(--accent);
  color: var(--accent-fg);
  border-radius: 999px;
  padding: 9px 16px;
  cursor: pointer;
  font-weight: 800;
}
button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.ghost {
  color: var(--fg-muted);
  text-decoration: none;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 9px 14px;
  background: var(--surface-2);
}
</style>
