<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthContext } from '../composables/useAuthContext'
import { mumu } from '../content/mumuCopy'
import { violatesContentPolicy } from '../lib/contentPolicy'
import { getSupabaseClient } from '../lib/supabase'
import { CONTENT_TYPE_LABELS, RESOURCE_TYPES, type ContentItem, type ContentType } from '../types'

const supabase = getSupabaseClient()
const router = useRouter()
const { userId, isAdmin } = useAuthContext()

const submitting = ref(false)
const formError = ref('')

const type = ref<ContentType>('plugin')
const title = ref('')
const description = ref('')
const version = ref('1.0.0')
const downloadUrl = ref('')
const tagsStr = ref('')

const typeOptions = computed(() => {
  const base = [...RESOURCE_TYPES]
  if (isAdmin.value) base.push('announcement' as ContentType)
  return base
})

watch([isAdmin, type], () => {
  if (type.value === 'announcement' && !isAdmin.value) type.value = 'plugin'
})

async function submit() {
  formError.value = ''
  if (!supabase || !userId.value) {
    formError.value = mumu.submitErrorLogin
    return
  }
  const t = title.value.trim()
  const d = description.value.trim()
  const v = version.value.trim()
  const url = downloadUrl.value.trim()
  if (!t || !d || !v) {
    formError.value = mumu.submitErrorFields
    return
  }
  if (type.value !== 'announcement' && !url) {
    formError.value = mumu.submitErrorUrl
    return
  }
  if (type.value === 'announcement' && !isAdmin.value) {
    formError.value = mumu.submitErrorAnnounce
    return
  }
  if (violatesContentPolicy(t, d)) {
    formError.value = mumu.submitErrorPolicy
    return
  }

  const tags = tagsStr.value
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean)

  const row: Omit<ContentItem, 'id' | 'author_name' | 'created_at' | 'updated_at' | 'download_count' | 'last_published_at'> = {
    type: type.value,
    title: t,
    description: d,
    version: v,
    download_url: type.value === 'announcement' ? url || '' : url,
    tags,
    author_id: userId.value,
    status: 'published',
    metadata: {},
  }

  submitting.value = true
  const { data, error } = await supabase.from('content_items').insert(row).select('id').single()
  submitting.value = false
  if (error) {
    formError.value = error.message
    return
  }
  if (data?.id) {
    await router.push({ name: 'item-detail', params: { id: data.id } })
  }
}
</script>

<template>
  <div class="submit">
    <header class="head">
      <h1>{{ mumu.submitTitle }}</h1>
      <p class="sub">{{ mumu.submitSub }}</p>
    </header>

    <form class="form" @submit.prevent="submit">
      <label class="field">
        <span class="label">类型</span>
        <select v-model="type" class="input" required>
          <option v-for="opt in typeOptions" :key="opt" :value="opt">{{ CONTENT_TYPE_LABELS[opt] }}</option>
        </select>
      </label>

      <label class="field">
        <span class="label">标题 <span class="req">*</span></span>
        <input v-model="title" class="input" type="text" required maxlength="200" autocomplete="off" />
      </label>

      <label class="field">
        <span class="label">描述 <span class="req">*</span></span>
        <textarea v-model="description" class="textarea" rows="6" required maxlength="20000" />
      </label>

      <label class="field">
        <span class="label">版本 <span class="req">*</span></span>
        <input v-model="version" class="input" type="text" required placeholder="例如 1.0.0" />
      </label>

      <label class="field">
        <span class="label">下载链接 <span v-if="type !== 'announcement'" class="req">*</span></span>
        <input
          v-model="downloadUrl"
          class="input"
          type="url"
          :required="type !== 'announcement'"
          placeholder="网盘或 GitHub Release 直链"
          autocomplete="off"
        />
        <span class="hint">{{ mumu.submitHintUrl }}</span>
      </label>

      <label class="field">
        <span class="label">标签（可选）</span>
        <input v-model="tagsStr" class="input" type="text" placeholder="逗号分隔多个标签" autocomplete="off" />
      </label>

      <p v-if="formError" class="err">{{ formError }}</p>

      <button type="submit" class="btn" :disabled="submitting">
        {{ submitting ? mumu.submitBtnLoading : mumu.submitBtn }}
      </button>
    </form>
  </div>
</template>

<style scoped>
.submit {
  max-width: 560px;
}
.head h1 {
  margin: 0 0 8px;
}
.sub {
  margin: 0 0 22px;
  color: var(--fg-muted);
  font-size: 0.95rem;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.label {
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--fg-muted);
}
.req {
  color: var(--danger);
}
.input,
.textarea {
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  font-size: 0.95rem;
  width: 100%;
  box-sizing: border-box;
}
.textarea {
  resize: vertical;
  min-height: 120px;
  font-family: inherit;
}
.hint {
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.err {
  color: var(--danger);
  font-size: 0.9rem;
  margin: 0;
}
.btn {
  align-self: flex-start;
  padding: 11px 22px;
  font-weight: 600;
  border: none;
  border-radius: 10px;
  background: var(--accent);
  color: var(--accent-fg);
  cursor: pointer;
}
.btn:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}
</style>
