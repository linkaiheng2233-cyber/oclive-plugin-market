<script setup lang="ts">
import { ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import AvatarImg from "../components/AvatarImg.vue";
import { useAuthContext } from "../composables/useAuthContext";
import { getSupabaseClient } from "../lib/supabase";

const { t } = useI18n();
const supabase = getSupabaseClient();
const { authConfigured, authBusy, userId, userEmail, username, avatarUrl, signInWithEmail, signOut, refreshProfile } =
  useAuthContext();

const emailInput = ref("");
const nameInput = ref("");
const donationUrlInput = ref("");
const donationQrUrlInput = ref("");
const info = ref("");
const profileReady = ref(false);

async function ensureProfileRow() {
  profileReady.value = false;
  if (!supabase || !userId.value) return;
  const { data: row, error: qErr } = await supabase.from("profiles").select("id").eq("id", userId.value).maybeSingle();
  if (qErr) {
    toast(qErr.message);
    return;
  }
  if (row) {
    profileReady.value = true;
    return;
  }
  const inferred = userEmail.value?.split("@")[0] || `user_${userId.value.slice(0, 8)}`;
  const suffix = userId.value.replace(/-/g, "").slice(0, 8);
  const { error: iErr } = await supabase.from("profiles").insert({
    id: userId.value,
    username: `${inferred}_${suffix}`,
    avatar_url: "",
  });
  if (iErr) {
    toast(t("market.personal.profileInsertFail", { msg: iErr.message }));
    return;
  }
  await refreshProfile();
  profileReady.value = true;
}

watch(
  [userId, username],
  () => {
    if (userId.value) {
      nameInput.value = username.value || "";
      void ensureProfileRow();
      void loadDonation();
    } else {
      nameInput.value = "";
      donationUrlInput.value = "";
      donationQrUrlInput.value = "";
      profileReady.value = false;
    }
  },
  { immediate: true },
);

function toast(msg: string) {
  info.value = msg;
  window.setTimeout(() => {
    if (info.value === msg) info.value = "";
  }, 2200);
}

function friendlyDbError(err: { message: string; code?: string }) {
  if (err.code === "23505" || err.message.includes("duplicate key") || err.message.includes("unique")) {
    return t("market.personal.nameTaken");
  }
  return err.message;
}

async function saveName() {
  const next = nameInput.value.trim();
  if (!supabase || !userId.value || !next) return;
  const { data, error } = await supabase.from("profiles").update({ username: next }).eq("id", userId.value).select("id");
  if (error) {
    toast(friendlyDbError(error));
    return;
  }
  if (!data?.length) {
    toast(t("market.personal.nameNoRow"));
    return;
  }
  await refreshProfile();
  nameInput.value = username.value || next;
  toast(t("market.personal.nameSaved"));
}

async function loadDonation() {
  if (!supabase || !userId.value) return;
  const { data, error } = await supabase
    .from("profiles")
    .select("donation_url,donation_qr_url")
    .eq("id", userId.value)
    .maybeSingle();
  if (error) return;
  donationUrlInput.value = (data as { donation_url?: string; donation_qr_url?: string })?.donation_url || "";
  donationQrUrlInput.value = (data as { donation_url?: string; donation_qr_url?: string })?.donation_qr_url || "";
}

async function saveDonation() {
  if (!supabase || !userId.value) return;
  await ensureProfileRow();
  if (!profileReady.value) {
    toast(t("market.personal.profileNotReady"));
    return;
  }
  const donation_url = donationUrlInput.value.trim();
  const donation_qr_url = donationQrUrlInput.value.trim();
  const { data, error } = await supabase
    .from("profiles")
    .update({ donation_url, donation_qr_url })
    .eq("id", userId.value)
    .select("id");
  if (error) {
    toast(error.message);
    return;
  }
  if (!data?.length) {
    toast(t("market.personal.donateNoRow"));
    return;
  }
  toast(t("market.personal.donateSaved"));
}

async function onDonateQrChange(e: Event) {
  if (!supabase || !userId.value) return;
  const input = e.target as HTMLInputElement;
  const file = input.files?.[0];
  if (!file) return;
  try {
    await ensureProfileRow();
    if (!profileReady.value) throw new Error(t("market.personal.profileNotReadyLong"));
    if (file.size > 10 * 1024 * 1024) throw new Error(t("market.personal.imageTooBig10"));
    const path = `${userId.value}/donate.png`;
    const { error: upErr } = await supabase.storage
      .from("content-files")
      .upload(path, file, { upsert: true, contentType: file.type || "image/png" });
    if (upErr) {
      if (upErr.message.includes("Bucket not found") || upErr.message.includes("not found")) {
        throw new Error(t("market.personal.bucketMissingContent"));
      }
      throw upErr;
    }
    const { data } = supabase.storage.from("content-files").getPublicUrl(path);
    const publicUrl = `${data.publicUrl}?t=${Date.now()}`;
    donationQrUrlInput.value = publicUrl;
    await saveDonation();
  } catch (err) {
    toast(err instanceof Error ? err.message : String(err));
  } finally {
    input.value = "";
  }
}

async function fileToCircleBlob(file: File): Promise<Blob> {
  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const i = new Image();
    i.onload = () => {
      URL.revokeObjectURL(url);
      resolve(i);
    };
    i.onerror = () => reject(new Error(t("market.personal.imageLoadFail")));
    i.src = url;
  });

  const size = 240;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error(t("market.personal.canvasUnavailable"));

  const scale = Math.max(size / img.width, size / img.height);
  const dw = img.width * scale;
  const dh = img.height * scale;
  const dx = (size - dw) / 2;
  const dy = (size - dh) / 2;

  ctx.clearRect(0, 0, size, size);
  ctx.save();
  ctx.beginPath();
  ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2);
  ctx.clip();
  ctx.drawImage(img, dx, dy, dw, dh);
  ctx.restore();

  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.88));
  if (!blob) throw new Error(t("market.personal.avatarCompressFail"));
  return blob;
}

async function onAvatarChange(e: Event) {
  if (!supabase || !userId.value) return;
  const input = e.target as HTMLInputElement;
  const file = input.files?.[0];
  if (!file) return;
  try {
    await ensureProfileRow();
    if (!profileReady.value) throw new Error(t("market.personal.profileNotReadyLong"));
    if (file.size > 16 * 1024 * 1024) throw new Error(t("market.personal.imageTooBig16"));
    const blob = await fileToCircleBlob(file);
    const path = `${userId.value}/avatar.jpg`;
    const { error: upErr } = await supabase.storage
      .from("avatars")
      .upload(path, blob, { upsert: true, contentType: "image/jpeg" });
    if (upErr) {
      if (upErr.message.includes("Bucket not found") || upErr.message.includes("not found")) {
        throw new Error(t("market.personal.bucketMissingAvatar"));
      }
      throw upErr;
    }
    const { data } = supabase.storage.from("avatars").getPublicUrl(path);
    const publicUrl = `${data.publicUrl}?t=${Date.now()}`;
    const { data: upd, error: dbErr } = await supabase
      .from("profiles")
      .update({ avatar_url: publicUrl })
      .eq("id", userId.value)
      .select("id");
    if (dbErr) throw dbErr;
    if (!upd?.length) throw new Error(t("market.personal.avatarDbMissing"));
    await refreshProfile();
    toast(t("market.personal.avatarSaved"));
  } catch (err) {
    toast(err instanceof Error ? err.message : String(err));
  } finally {
    input.value = "";
  }
}
</script>

<template>
  <div class="page-head">
    <h1>{{ t("market.personal.title") }}</h1>
    <p class="sub">{{ t("market.personal.sub") }}</p>
  </div>

  <p v-if="info" class="info">{{ info }}</p>
  <p v-if="!authConfigured" class="warn">{{ t("market.personal.noSupabase") }}</p>

  <section v-if="!userId" class="card">
    <label class="field">
      <span>{{ t("market.personal.email") }}</span>
      <input v-model="emailInput" type="email" placeholder="you@example.com" />
    </label>
    <button :disabled="authBusy || !emailInput" @click="signInWithEmail(emailInput)">
      {{ t("market.personal.sendMagicLink") }}
    </button>
  </section>

  <section v-else class="card">
    <div class="top">
      <div class="avatar-wrap">
        <AvatarImg v-if="avatarUrl" :stored-url="avatarUrl" img-class="avatar" />
        <div v-else class="avatar placeholder">{{ username.slice(0, 1) || "U" }}</div>
      </div>
      <div>
        <p class="line"><strong>{{ t("market.personal.emailLine") }}</strong>{{ userEmail }}</p>
        <p class="line"><strong>{{ t("market.personal.nameLine") }}</strong>{{ username || t("market.personal.nameUnset") }}</p>
      </div>
    </div>

    <label class="field">
      <span>{{ t("market.personal.changeName") }}</span>
      <input v-model="nameInput" :placeholder="t('market.personal.namePh')" />
    </label>
    <p v-if="userId && !profileReady" class="hint">{{ t("market.personal.syncing") }}</p>
    <div class="ops">
      <button :disabled="!nameInput.trim() || !profileReady" @click="saveName">{{ t("market.personal.saveName") }}</button>
      <label class="upload">
        {{ t("market.personal.pickAvatar") }}
        <input type="file" accept="image/*" @change="onAvatarChange" />
      </label>
      <button class="ghost" @click="signOut">{{ t("market.personal.signOut") }}</button>
    </div>
  </section>

  <section v-if="userId" class="card card--donate">
    <h2 class="h2">{{ t("market.personal.donateTitle") }}</h2>
    <p class="donate-hint">{{ t("market.personal.donateHint") }}</p>

    <label class="field">
      <span>{{ t("market.personal.donateUrl") }}</span>
      <input v-model="donationUrlInput" :placeholder="t('market.personal.donateUrlPh')" />
    </label>

    <label class="field">
      <span>{{ t("market.personal.donateQr") }}</span>
      <input v-model="donationQrUrlInput" :placeholder="t('market.personal.donateQrPh')" />
    </label>

    <div class="ops">
      <button :disabled="!profileReady" @click="saveDonation">{{ t("market.personal.saveDonate") }}</button>
      <label class="upload">
        {{ t("market.personal.uploadQr") }}
        <input type="file" accept="image/*" @change="onDonateQrChange" />
      </label>
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
.card--donate {
  margin-top: 14px;
  max-width: 760px;
}
.h2 {
  margin: 0 0 8px;
  font-size: 1.05rem;
}
.donate-hint {
  margin: 0 0 12px;
  color: var(--fg-muted);
  font-size: 0.9rem;
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
