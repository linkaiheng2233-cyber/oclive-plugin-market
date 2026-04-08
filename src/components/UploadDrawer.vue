<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import type { CharacterPackSections, PackBranchKind } from '../types'

type UploadKind = 'plugin' | 'pack' | 'pack-branch' | 'module'

type UploadPayload =
  | {
      kind: 'plugin'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      tags: string[]
      minVersion: string
    }
  | {
      kind: 'pack'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      sections: CharacterPackSections
    }
  | {
      kind: 'pack-branch'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      branchKind: PackBranchKind
      content: string
    }
  | {
      kind: 'module'
      name: string
      author: string
      link: string
      intro: string
      previewImage: string
      moduleKind: string
      tags: string[]
    }

const props = defineProps<{
  open: boolean
  authConfigured: boolean
  userEmail: string
  authBusy: boolean
}>()
const emit = defineEmits<{
  close: []
  submit: [payload: UploadPayload]
  login: [email: string]
  logout: []
}>()
const authEmail = ref('')

const activeKind = ref<UploadKind>('pack')
const tabDefs: Array<{ key: UploadKind; label: string }> = [
  { key: 'pack', label: '完整角色包' },
  { key: 'pack-branch', label: '角色包分支' },
  { key: 'plugin', label: '插件' },
  { key: 'module', label: '模块' },
]

const common = reactive({
  name: '',
  author: '',
  link: '',
  intro: '',
  previewImage: '',
})

const pluginExtra = reactive({
  minVersion: '',
  tagsText: '',
})

const moduleExtra = reactive({
  moduleKind: '',
  tagsText: '',
})

const packSections = reactive<CharacterPackSections>({
  scene: '',
  persona: '',
  identity: '',
  world: '',
})

const branchExtra = reactive({
  branchKind: 'scene' as PackBranchKind,
  content: '',
})

function tagsFromText(s: string) {
  return s
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean)
}

const canSubmit = computed(() => {
  const baseOk =
    common.name.trim() &&
    common.author.trim() &&
    common.link.trim() &&
    common.intro.trim() &&
    common.previewImage.trim()
  if (!baseOk) return false
  if (props.authConfigured && !props.userEmail) return false
  if (activeKind.value === 'pack') {
    return (
      packSections.scene.trim() &&
      packSections.persona.trim() &&
      packSections.identity.trim() &&
      packSections.world.trim()
    )
  }
  if (activeKind.value === 'pack-branch') return !!branchExtra.content.trim()
  return true
})

function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape' && props.open) emit('close')
}

function resetForm() {
  common.name = ''
  common.author = ''
  common.link = ''
  common.intro = ''
  common.previewImage = ''
  pluginExtra.minVersion = ''
  pluginExtra.tagsText = ''
  moduleExtra.moduleKind = ''
  moduleExtra.tagsText = ''
  packSections.scene = ''
  packSections.persona = ''
  packSections.identity = ''
  packSections.world = ''
  branchExtra.branchKind = 'scene'
  branchExtra.content = ''
}

function submit() {
  if (!canSubmit.value) return
  const base = {
    name: common.name.trim(),
    author: common.author.trim(),
    link: common.link.trim(),
    intro: common.intro.trim(),
    previewImage: common.previewImage.trim(),
  }
  if (activeKind.value === 'plugin') {
    emit('submit', {
      kind: 'plugin',
      ...base,
      tags: tagsFromText(pluginExtra.tagsText),
      minVersion: pluginExtra.minVersion.trim() || '0.2.0',
    })
  } else if (activeKind.value === 'pack') {
    emit('submit', {
      kind: 'pack',
      ...base,
      sections: {
        scene: packSections.scene.trim(),
        persona: packSections.persona.trim(),
        identity: packSections.identity.trim(),
        world: packSections.world.trim(),
      },
    })
  } else if (activeKind.value === 'pack-branch') {
    emit('submit', {
      kind: 'pack-branch',
      ...base,
      branchKind: branchExtra.branchKind,
      content: branchExtra.content.trim(),
    })
  } else {
    emit('submit', {
      kind: 'module',
      ...base,
      moduleKind: moduleExtra.moduleKind.trim() || 'custom',
      tags: tagsFromText(moduleExtra.tagsText),
    })
  }
  resetForm()
  emit('close')
}

function sendLoginLink() {
  if (!authEmail.value.trim()) return
  emit('login', authEmail.value.trim())
}

watch(
  () => props.open,
  (v) => {
    document.body.style.overflow = v ? 'hidden' : ''
  }
)

onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => {
  window.removeEventListener('keydown', onKey)
  document.body.style.overflow = ''
})
</script>

<template>
  <Teleport to="body">
    <div v-if="open" class="backdrop" @click.self="emit('close')">
      <aside class="drawer" role="dialog" aria-modal="true" aria-labelledby="upload-title">
        <header class="drawer-head">
          <h2 id="upload-title">创作者 · 上架</h2>
          <button type="button" class="icon-close" aria-label="关闭" @click="emit('close')">×</button>
        </header>

        <div class="drawer-body">
          <section class="auth-box">
            <template v-if="authConfigured">
              <p v-if="userEmail" class="auth-ok">
                已登录：<strong>{{ userEmail }}</strong>
                <button type="button" class="mini-link" :disabled="authBusy" @click="emit('logout')">
                  退出
                </button>
              </p>
              <div v-else class="auth-login">
                <label class="field">
                  <span>邮箱登录（上传完整角色包需要）</span>
                  <input v-model="authEmail" type="email" placeholder="you@example.com" />
                </label>
                <button type="button" class="btn ghost" :disabled="authBusy || !authEmail" @click="sendLoginLink">
                  {{ authBusy ? '发送中...' : '发送登录链接' }}
                </button>
              </div>
            </template>
            <p v-else class="note">
              尚未配置 Supabase 环境变量；当前仅可本地保存（不共享）。
            </p>
          </section>

          <p class="lead">
            已接入云端：登录后会同步到 Supabase；未配置云端时自动回退到本地浏览器存储。
          </p>
          <p class="note">基础字段只要三样：可用链接、预览图、介绍。再按类型补充最少必要信息即可。</p>

          <div class="tabs" role="tablist" aria-label="上传类型">
            <button
              v-for="t in tabDefs"
              :key="t.key"
              type="button"
              class="tab"
              :class="{ active: activeKind === t.key }"
              @click="activeKind = t.key"
            >
              {{ t.label }}
            </button>
          </div>

          <form class="form" @submit.prevent="submit">
            <label class="field">
              <span>名称</span>
              <input v-model="common.name" required placeholder="例如：夜航档案 / 记忆增强模块" />
            </label>
            <label class="field">
              <span>作者</span>
              <input v-model="common.author" required placeholder="你的昵称或团队名" />
            </label>
            <label class="field">
              <span>可用链接</span>
              <input v-model="common.link" required type="url" placeholder="https://..." />
            </label>
            <label class="field">
              <span>预览图链接</span>
              <input v-model="common.previewImage" required type="url" placeholder="https://.../cover.png" />
            </label>
            <label class="field">
              <span>介绍</span>
              <textarea v-model="common.intro" required rows="3" placeholder="一句话说明适用场景与亮点" />
            </label>

            <template v-if="activeKind === 'pack'">
              <label class="field"><span>场景</span><textarea v-model="packSections.scene" rows="2" required /></label>
              <label class="field"><span>人设</span><textarea v-model="packSections.persona" rows="2" required /></label>
              <label class="field"><span>身份</span><textarea v-model="packSections.identity" rows="2" required /></label>
              <label class="field"><span>世界观</span><textarea v-model="packSections.world" rows="2" required /></label>
            </template>

            <template v-else-if="activeKind === 'pack-branch'">
              <label class="field">
                <span>分支类别</span>
                <select v-model="branchExtra.branchKind">
                  <option value="scene">场景</option>
                  <option value="persona">人设</option>
                  <option value="identity">身份</option>
                  <option value="world">世界观</option>
                </select>
              </label>
              <label class="field">
                <span>分支内容</span>
                <textarea v-model="branchExtra.content" rows="3" required />
              </label>
            </template>

            <template v-else-if="activeKind === 'plugin'">
              <label class="field">
                <span>最低 oclive 版本</span>
                <input v-model="pluginExtra.minVersion" placeholder="例如：0.2.0" />
              </label>
              <label class="field">
                <span>标签（逗号分隔）</span>
                <input v-model="pluginExtra.tagsText" placeholder="memory, llm, utility" />
              </label>
            </template>

            <template v-else>
              <label class="field">
                <span>模块类型</span>
                <input v-model="moduleExtra.moduleKind" placeholder="memory / emotion / custom" />
              </label>
              <label class="field">
                <span>标签（逗号分隔）</span>
                <input v-model="moduleExtra.tagsText" placeholder="emotion, realtime" />
              </label>
            </template>

            <div class="actions">
              <button type="submit" class="btn primary" :disabled="!canSubmit">
                {{ authConfigured ? '提交到云端' : '保存到本站' }}
              </button>
              <button type="button" class="btn ghost" @click="resetForm">清空</button>
            </div>
          </form>
        </div>
      </aside>
    </div>
  </Teleport>
</template>

<style scoped>
.backdrop {
  position: fixed;
  inset: 0;
  z-index: 200;
  background: rgba(58, 52, 42, 0.35);
  display: flex;
  justify-content: flex-end;
}

.drawer {
  width: min(440px, 100%);
  height: 100%;
  background: var(--surface);
  border-left: 1px solid var(--border);
  box-shadow: -8px 0 24px rgba(42, 38, 32, 0.08);
  display: flex;
  flex-direction: column;
  animation: slide 0.2s ease-out;
}

@keyframes slide {
  from {
    transform: translateX(12px);
    opacity: 0.9;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.drawer-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 18px;
  border-bottom: 1px solid var(--border);
}

.drawer-head h2 {
  margin: 0;
  font-size: 1.1rem;
}

.icon-close {
  border: none;
  background: transparent;
  font-size: 1.5rem;
  line-height: 1;
  cursor: pointer;
  color: var(--fg-muted);
  padding: 4px 8px;
}

.drawer-body {
  padding: 16px 18px 28px;
  overflow-y: auto;
}

.lead {
  margin: 0 0 12px;
  color: var(--fg-muted);
  line-height: 1.55;
}

.auth-box {
  margin-bottom: 12px;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
}
.auth-ok {
  margin: 0;
  color: var(--fg-muted);
  font-size: 0.88rem;
}
.auth-login {
  display: grid;
  gap: 10px;
}
.mini-link {
  margin-left: 8px;
  border: none;
  background: transparent;
  color: var(--accent);
  cursor: pointer;
  text-decoration: underline;
}

.note {
  font-size: 0.88rem;
  color: var(--fg-soft);
  line-height: 1.5;
  margin: 0 0 12px;
}

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
}

.tab {
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg-muted);
  border-radius: 999px;
  padding: 6px 12px;
  font-size: 0.82rem;
  cursor: pointer;
}
.tab.active {
  border-color: var(--accent-soft);
  background: color-mix(in srgb, var(--accent) 12%, var(--surface));
  color: var(--fg);
  font-weight: 600;
}

.form {
  display: grid;
  gap: 10px;
}

.field {
  display: grid;
  gap: 6px;
}

.field span {
  font-size: 0.8rem;
  color: var(--fg-soft);
}

.field input,
.field textarea,
.field select {
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  border-radius: 10px;
  padding: 9px 10px;
  font: inherit;
  font-size: 0.9rem;
}

.field textarea {
  resize: vertical;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 6px;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 0.9rem;
  font-weight: 600;
  text-decoration: none;
  border: 1px solid transparent;
  cursor: pointer;
}

.btn.primary {
  background: var(--accent);
  color: var(--accent-fg);
}

.btn.ghost {
  background: transparent;
  border-color: var(--border);
  color: var(--fg-muted);
}

.btn:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

code {
  font-size: 0.85em;
  background: var(--code-bg);
  padding: 2px 6px;
  border-radius: 5px;
}
</style>
