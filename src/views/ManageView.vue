<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useAuthContext } from "../composables/useAuthContext";
import { getSupabaseClient } from "../lib/supabase";
import type { ContentItem, ContentStatus, ContentType } from "../types";

const { t } = useI18n();
const supabase = getSupabaseClient();
const { userId, userEmail } = useAuthContext();

const loading = ref(false);
const err = ref("");
const items = ref<ContentItem[]>([]);
type ManageTab = "all" | ContentType | "plugin" | "module" | "branch";
const typeFilter = ref<ManageTab>("all");

const filtered = computed(() => {
  if (typeFilter.value === "all") return items.value;
  if (typeFilter.value === "plugin" || typeFilter.value === "module" || typeFilter.value === "branch") {
    return [];
  }
  return items.value.filter((x) => x.type === typeFilter.value);
});

function asList(meta: unknown) {
  try {
    return JSON.stringify(meta, null, 2);
  } catch {
    return "{}";
  }
}

async function loadMine() {
  if (!supabase || !userId.value) return;
  loading.value = true;
  err.value = "";
  const { data, error } = await supabase
    .from("content_items")
    .select("*")
    .eq("author_id", userId.value)
    .order("updated_at", { ascending: false });
  loading.value = false;
  if (error) {
    err.value = error.message;
    return;
  }
  items.value = (data ?? []) as ContentItem[];
}

async function toggleStatus(item: ContentItem) {
  if (!supabase) return;
  const next: ContentStatus = item.status === "published" ? "hidden" : "published";
  const { error } = await supabase.from("content_items").update({ status: next }).eq("id", item.id);
  if (error) {
    err.value = error.message;
    return;
  }
  item.status = next;
}

async function removeItem(item: ContentItem) {
  if (!supabase) return;
  if (!window.confirm(t("market.manage.confirmDelete", { title: item.title }))) return;
  const { error } = await supabase.from("content_items").delete().eq("id", item.id);
  if (error) {
    err.value = error.message;
    return;
  }
  items.value = items.value.filter((x) => x.id !== item.id);
}

async function editItem(item: ContentItem) {
  if (!supabase) return;
  const nextTitle = window.prompt(t("market.manage.promptTitle"), item.title);
  if (!nextTitle) return;
  const description = window.prompt(t("market.manage.promptDesc"), item.description);
  if (!description) return;
  const tagsStr = window.prompt(t("market.manage.promptTags"), item.tags.join(","));
  if (tagsStr == null) return;
  const version = window.prompt(t("market.manage.promptVersion"), item.version || "v1.0.0");
  if (!version) return;
  const metadataStr = window.prompt(t("market.manage.promptMetadata"), asList(item.metadata));
  if (metadataStr == null) return;
  let metadata: Record<string, unknown> = {};
  try {
    metadata = JSON.parse(metadataStr);
  } catch {
    window.alert(t("market.manage.metaInvalid"));
    return;
  }

  const { error } = await supabase
    .from("content_items")
    .update({
      title: nextTitle,
      description,
      tags: tagsStr
        .split(",")
        .map((x) => x.trim())
        .filter(Boolean),
      version,
      metadata,
    })
    .eq("id", item.id);
  if (error) {
    err.value = error.message;
    return;
  }
  Object.assign(item, {
    title: nextTitle,
    description,
    tags: tagsStr
      .split(",")
      .map((x) => x.trim())
      .filter(Boolean),
    version,
    metadata,
  });
}

onMounted(() => {
  void loadMine();
});
</script>

<template>
  <div class="page-head">
    <h1>{{ t("market.manage.title") }}</h1>
    <p class="sub">{{ t("market.manage.sub") }}</p>
    <p v-if="userEmail" class="hint">{{ t("market.manage.account", { email: userEmail }) }}</p>
  </div>

  <p v-if="!userId" class="state err">{{ t("market.manage.needLogin") }}</p>
  <template v-else>
    <div class="tabs">
      <button class="tab" :class="{ active: typeFilter === 'all' }" @click="typeFilter = 'all'">
        {{ t("market.manage.tabAll") }}
      </button>
      <button class="tab" :class="{ active: typeFilter === 'character' }" @click="typeFilter = 'character'">
        {{ t("market.manage.tabCharacter") }}
      </button>
      <button class="tab" :class="{ active: typeFilter === 'plugin' }" @click="typeFilter = 'plugin'">
        {{ t("market.manage.tabPlugin") }}
      </button>
      <button class="tab" :class="{ active: typeFilter === 'module' }" @click="typeFilter = 'module'">
        {{ t("market.manage.tabModule") }}
      </button>
      <button class="tab" :class="{ active: typeFilter === 'branch' }" @click="typeFilter = 'branch'">
        {{ t("market.manage.tabBranch") }}
      </button>
      <button class="tab" :class="{ active: typeFilter === 'announcement' }" @click="typeFilter = 'announcement'">
        {{ t("market.manage.tabAnnounce") }}
      </button>
    </div>

    <p v-if="loading" class="state">{{ t("market.manage.loading") }}</p>
    <p v-else-if="err" class="state err">{{ err }}</p>
    <ul v-else-if="filtered.length" class="list">
      <li v-for="item in filtered" :key="item.id" class="row">
        <div class="meta">
          <p class="title">{{ item.title }}</p>
          <p class="desc">{{ item.description }}</p>
          <p class="tiny">
            {{ t(`market.contentType.${item.type}`) }} · {{ item.version }} ·
            <span :class="item.status === 'published' ? 'ok' : 'warn'">{{ item.status }}</span>
          </p>
        </div>
        <div class="ops">
          <button @click="editItem(item)">{{ t("market.manage.edit") }}</button>
          <button @click="toggleStatus(item)">
            {{ item.status === "published" ? t("market.manage.hide") : t("market.manage.restore") }}
          </button>
          <button class="danger" @click="removeItem(item)">{{ t("market.manage.delete") }}</button>
        </div>
      </li>
    </ul>
    <p v-else class="state">{{ t("market.manage.empty") }}</p>
  </template>
</template>

<style scoped>
.page-head {
  margin-bottom: 16px;
}
h1 {
  margin: 0 0 8px;
}
.sub {
  margin: 0 0 4px;
  color: var(--fg-muted);
}
.hint {
  margin: 0;
  color: var(--fg-soft);
  font-size: 0.85rem;
}
.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 14px;
}
.tab {
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  color: var(--fg-muted);
  padding: 6px 12px;
  cursor: pointer;
}
.tab.active {
  border-color: var(--accent-soft);
  color: var(--accent);
}
.list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 10px;
}
.row {
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--surface);
  padding: 12px;
  display: flex;
  gap: 12px;
  justify-content: space-between;
  align-items: flex-start;
}
.title {
  margin: 0 0 4px;
  font-weight: 700;
}
.desc {
  margin: 0 0 4px;
  color: var(--fg-muted);
}
.tiny {
  margin: 0;
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.ok {
  color: #2e7d32;
}
.warn {
  color: #b26a00;
}
.ops {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.ops button {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 8px;
  padding: 6px 10px;
  cursor: pointer;
}
.ops .danger {
  color: #a33f2f;
}
.state.err {
  color: var(--danger);
}
</style>
