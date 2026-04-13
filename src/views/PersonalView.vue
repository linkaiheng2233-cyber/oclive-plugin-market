<script setup lang="ts">
import { ref, watch } from 'vue'
import AvatarImg from '../components/AvatarImg.vue'
import { useAuthContext } from '../composables/useAuthContext'
import { getSupabaseClient } from '../lib/supabase'

const supabase = getSupabaseClient()
const { authConfigured, authBusy, userId, userEmail, username, avatarUrl, signInWithEmail, signOut, refreshProfile } =
  useAuthContext()

const emailInput = ref('')
const nameInput = ref('')
const info = ref('')
const profileReady = ref(false)

/** 登录后若没有 profiles 行（例如早期触发器失败、昵称唯一冲突），补一行，否则更新会「静默失败」 */
async function ensureProfileRow() {
  profileReady.value = false
  if (!supabase || !userId.value) return
  const { data: row, error: qErr } = await supabase.from('profiles').select('id').eq('id', userId.value).maybeSingle()
  if (qErr) {
    toast(qErr.message)
    return
  }
  if (row) {
    profileReady.value = true
    return
  }
  const inferred = userEmail.value?.split('@')[0] || `user_${userId.value.slice(0, 8)}`
  const suffix = userId.value.replace(/-/g, '').slice(0, 8)
  const { error: iErr } = await supabase.from('profiles').insert({
    id: userId.value,
    username: `${inferred}_${suffix}`,
    avatar_url: '',
  })
  if (iErr) {
    toast(`资料行创建失败：${iErr.message}（若提示昵称重复，可在 Supabase Table Editor 里手动改 profiles）`)
    return
  }
  await refreshProfile()
  profileReady.value = true
}

watch(
  [userId, username],
  () => {
    if (userId.value) {
      nameInput.value = username.value || ''
      void ensureProfileRow()
    } else {
      nameInput.value = ''
      profileReady.value = false
    }
  },
  { immediate: true }
)

function toast(msg: string) {
  info.value = msg
  window.setTimeout(() => {
    if (info.value === msg) info.value = ''
  }, 2200)
}

function friendlyDbError(err: { message: string; code?: string }) {
  if (err.code === '23505' || err.message.includes('duplicate key') || err.message.includes('unique')) {
    return '这个昵称已经被人用了，换一个试试～'
  }
  return err.message
}

async function saveName() {
  const next = nameInput.value.trim()
  if (!supabase || !userId.value || !next) return
  const { data, error } = await supabase
    .from('profiles')
    .update({ username: next })
    .eq('id', userId.value)
    .select('id')
  if (error) {
    toast(friendlyDbError(error))
    return
  }
  if (!data?.length) {
    toast('没有更新成功：库里可能没有你的资料行，请刷新页面或看下方说明。')
    return
  }
  await refreshProfile()
  nameInput.value = username.value || next
  toast('昵称已更新。')
}

async function fileToCircleBlob(file: File): Promise<Blob> {
  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const i = new Image()
    i.onload = () => {
      URL.revokeObjectURL(url)
      resolve(i)
    }
    i.onerror = () => reject(new Error('图片加载失败'))
    i.src = url
  })

  const size = 240
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('Canvas 不可用')

  const scale = Math.max(size / img.width, size / img.height)
  const dw = img.width * scale
  const dh = img.height * scale
  const dx = (size - dw) / 2
  const dy = (size - dh) / 2

  ctx.clearRect(0, 0, size, size)
  ctx.save()
  ctx.beginPath()
  ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2)
  ctx.clip()
  ctx.drawImage(img, dx, dy, dw, dh)
  ctx.restore()

  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.88))
  if (!blob) throw new Error('头像压缩失败')
  return blob
}

async function onAvatarChange(e: Event) {
  if (!supabase || !userId.value) return
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  try {
    await ensureProfileRow()
    if (!profileReady.value) throw new Error('资料未就绪，请稍后再试或刷新页面。')
    if (file.size > 16 * 1024 * 1024) throw new Error('图片过大（>16MB）')
    const blob = await fileToCircleBlob(file)
    const path = `${userId.value}/avatar.jpg`
    const { error: upErr } = await supabase.storage
      .from('avatars')
      .upload(path, blob, { upsert: true, contentType: 'image/jpeg' })
    if (upErr) {
      if (upErr.message.includes('Bucket not found') || upErr.message.includes('not found')) {
        throw new Error('头像存储桶未创建：请在 Supabase 执行 schema.sql 里 storage 段，或 Storage 里新建公开桶 avatars')
      }
      throw upErr
    }
    const { data } = supabase.storage.from('avatars').getPublicUrl(path)
    const publicUrl = `${data.publicUrl}?t=${Date.now()}`
    const { data: upd, error: dbErr } = await supabase
      .from('profiles')
      .update({ avatar_url: publicUrl })
      .eq('id', userId.value)
      .select('id')
    if (dbErr) throw dbErr
    if (!upd?.length) throw new Error('头像地址没写进资料表：请确认 profiles 里有你的账号行。')
    await refreshProfile()
    toast('头像已更新。')
  } catch (err) {
    toast(err instanceof Error ? err.message : String(err))
  } finally {
    input.value = ''
  }
}
</script>

<template>
  <div class="page-head">
    <h1>个人设置</h1>
    <p class="sub">登录/退出账号，设置昵称与头像（圆形裁切 + 压缩上传）。</p>
  </div>

  <p v-if="info" class="info">{{ info }}</p>
  <p v-if="!authConfigured" class="warn">未配置 Supabase 环境变量，账号系统不可用。</p>

  <section v-if="!userId" class="card">
    <label class="field">
      <span>邮箱</span>
      <input v-model="emailInput" type="email" placeholder="you@example.com" />
    </label>
    <button :disabled="authBusy || !emailInput" @click="signInWithEmail(emailInput)">发送登录链接</button>
  </section>

  <section v-else class="card">
    <div class="top">
      <div class="avatar-wrap">
        <AvatarImg v-if="avatarUrl" :stored-url="avatarUrl" img-class="avatar" />
        <div v-else class="avatar placeholder">{{ username.slice(0, 1) || 'U' }}</div>
      </div>
      <div>
        <p class="line"><strong>邮箱：</strong>{{ userEmail }}</p>
        <p class="line"><strong>昵称：</strong>{{ username || '未设置' }}</p>
      </div>
    </div>

    <label class="field">
      <span>修改昵称</span>
      <input v-model="nameInput" placeholder="新的昵称" />
    </label>
    <p v-if="userId && !profileReady" class="hint">正在同步资料…</p>
    <div class="ops">
      <button :disabled="!nameInput.trim() || !profileReady" @click="saveName">保存昵称</button>
      <label class="upload">
        选择头像
        <input type="file" accept="image/*" @change="onAvatarChange" />
      </label>
      <button class="ghost" @click="signOut">退出账号</button>
    </div>
  </section>
</template>

<style scoped>
.page-head {
  margin-bottom: 16px;
}
h1 {
  margin: 0 0 8px;
  font-size: 1.45rem;
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
  max-width: 560px;
}
.top {
  display: flex;
  gap: 14px;
  margin-bottom: 12px;
}
.avatar-wrap {
  width: 76px;
  height: 76px;
}
.avatar {
  width: 76px;
  height: 76px;
  object-fit: cover;
  border-radius: 999px;
  border: 1px solid var(--border);
}
.avatar.placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: var(--fg-soft);
  background: var(--surface-2);
}
.line {
  margin: 0 0 6px;
  color: var(--fg-muted);
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
.field input {
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface-2);
  padding: 9px 10px;
}
.ops {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
button,
.upload {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 10px;
  padding: 8px 12px;
  cursor: pointer;
  font: inherit;
}
.upload input {
  display: none;
}
.ghost {
  color: var(--fg-muted);
}
.hint {
  font-size: 0.85rem;
  color: var(--fg-soft);
  margin: 0 0 8px;
}
</style>
