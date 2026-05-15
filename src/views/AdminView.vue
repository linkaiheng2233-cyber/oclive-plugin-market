<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { RouterLink } from "vue-router";
import { useAuthContext } from "../composables/useAuthContext";
import { getSupabaseClient } from "../lib/supabase";
import type { ContentItem, ContentStatus, ContentType } from "../types";

const { t } = useI18n();
const supabase = getSupabaseClient();
const { isAdmin, userId } = useAuthContext();

const loading = ref(false);
const err = ref("");
const items = ref<ContentItem[]>([]);
const typeFilter = ref<"all" | ContentType>("all");
const statusFilter = ref<"all" | ContentStatus>("all");

type Tab = "content" | "forum";
const tab = ref<Tab>("content");

const filtered = computed(() =>
  items.value.filter((x) => {
    const typeOk = typeFilter.value === "all" || x.type === typeFilter.value;
    const statusOk = statusFilter.value === "all" || x.status === statusFilter.value;
    return typeOk && statusOk;
  }),
);

async function loadAll() {
  if (!supabase || !isAdmin.value) return;
  loading.value = true;
  err.value = "";
  const { data, error } = await supabase
    .from("content_items")
    .select("*")
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
  if (!window.confirm(t("market.admin.confirmDelete", { title: item.title }))) return;
  const { error } = await supabase.from("content_items").delete().eq("id", item.id);
  if (error) {
    err.value = error.message;
    return;
  }
  items.value = items.value.filter((x) => x.id !== item.id);
}

type ForumReportTargetType = "thread" | "post";
type ForumReportStatus = "open" | "handled" | "rejected";

type ForumReportRow = {
  id: string;
  target_type: ForumReportTargetType;
  target_id: string;
  reporter_id: string;
  reason_code: string;
  reason_text: string;
  status: ForumReportStatus;
  created_at: string;
  updated_at: string;
};

const forumLoading = ref(false);
const forumErr = ref("");
const reportStatus = ref<ForumReportStatus | "all">("open");
const reports = ref<ForumReportRow[]>([]);
const targets = ref<Record<string, unknown>>({});

function keyOf(ty: ForumReportTargetType, id: string) {
  return `${ty}:${id}`;
}

async function loadForumReports() {
  if (!supabase || !isAdmin.value) return;
  forumLoading.value = true;
  forumErr.value = "";
  targets.value = {};

  let q = supabase.from("forum_reports").select("*").order("updated_at", { ascending: false });
  if (reportStatus.value !== "all") q = q.eq("status", reportStatus.value);

  const { data, error } = await q;
  forumLoading.value = false;
  if (error) {
    forumErr.value = error.message;
    return;
  }
  reports.value = (data ?? []) as ForumReportRow[];

  const threadIds = Array.from(new Set(reports.value.filter((r) => r.target_type === "thread").map((r) => r.target_id)));
  const postIds = Array.from(new Set(reports.value.filter((r) => r.target_type === "post").map((r) => r.target_id)));

  if (threadIds.length) {
    const { data: t } = await supabase.from("forum_threads").select("id,title,status,author_id,category_id").in("id", threadIds);
    for (const row of (t ?? []) as { id: string }[]) targets.value[keyOf("thread", row.id)] = row;
  }
  if (postIds.length) {
    const { data: p } = await supabase.from("forum_posts").select("id,thread_id,floor,status,author_id,content").in("id", postIds);
    for (const row of (p ?? []) as { id: string }[]) targets.value[keyOf("post", row.id)] = row;
  }
}

async function addModerationAction(action: string, targetType: string, targetId: string, note: string) {
  if (!supabase || !userId.value) return;
  await supabase.from("forum_moderation_actions").insert({
    actor_id: userId.value,
    action,
    target_type: targetType,
    target_id: targetId,
    note: note.trim(),
  });
}

async function setReportStatus(r: ForumReportRow, next: ForumReportStatus, note: string) {
  if (!supabase) return;
  const { error } = await supabase.from("forum_reports").update({ status: next }).eq("id", r.id);
  if (error) {
    forumErr.value = error.message;
    return;
  }
  await addModerationAction("note", "report", r.id, `${next}: ${note}`.trim());
  r.status = next;
}

async function hideThread(r: ForumReportRow) {
  if (!supabase) return;
  const note = window.prompt(t("market.admin.promptNote"), t("market.admin.defaultHideThread")) ?? "";
  const { error } = await supabase.from("forum_threads").update({ status: "hidden" }).eq("id", r.target_id);
  if (error) {
    forumErr.value = error.message;
    return;
  }
  await addModerationAction("hide_thread", "thread", r.target_id, note);
  await setReportStatus(r, "handled", note);
  await loadForumReports();
}

async function lockThread(r: ForumReportRow) {
  if (!supabase) return;
  const note = window.prompt(t("market.admin.promptNote"), t("market.admin.defaultLockThread")) ?? "";
  const { error } = await supabase.from("forum_threads").update({ status: "locked" }).eq("id", r.target_id);
  if (error) {
    forumErr.value = error.message;
    return;
  }
  await addModerationAction("lock_thread", "thread", r.target_id, note);
  await setReportStatus(r, "handled", note);
  await loadForumReports();
}

async function hidePost(r: ForumReportRow) {
  if (!supabase) return;
  const note = window.prompt(t("market.admin.promptNote"), t("market.admin.defaultHidePost")) ?? "";
  const { error } = await supabase.from("forum_posts").update({ status: "hidden" }).eq("id", r.target_id);
  if (error) {
    forumErr.value = error.message;
    return;
  }
  await addModerationAction("hide_post", "post", r.target_id, note);
  await setReportStatus(r, "handled", note);
  await loadForumReports();
}

async function rejectReport(r: ForumReportRow) {
  const note = window.prompt(t("market.admin.promptReject"), t("market.admin.defaultReject")) ?? "";
  await setReportStatus(r, "rejected", note);
  await loadForumReports();
}

onMounted(() => {
  void loadAll();
});
</script>

<template>
  <div class="page-head">
    <h1>{{ t("market.admin.title") }}</h1>
    <p class="sub">{{ t("market.admin.sub") }}</p>
  </div>

  <p v-if="!isAdmin" class="state err">{{ t("market.admin.notAdmin") }}</p>
  <template v-else>
    <div class="tabs">
      <button class="tab" :class="{ 'tab--active': tab === 'content' }" @click="tab = 'content'">
        {{ t("market.admin.tabContent") }}
      </button>
      <button class="tab" :class="{ 'tab--active': tab === 'forum' }" @click="tab = 'forum'; loadForumReports()">
        {{ t("market.admin.tabForum") }}
      </button>
    </div>

    <section v-if="tab === 'content'">
      <div class="filters">
        <select v-model="typeFilter">
          <option value="all">{{ t("market.admin.filterAllTypes") }}</option>
          <option value="character">{{ t("market.contentType.character") }}</option>
          <option value="announcement">{{ t("market.contentType.announcement") }}</option>
        </select>
        <select v-model="statusFilter">
          <option value="all">{{ t("market.admin.filterAllStatus") }}</option>
          <option value="published">{{ t("market.admin.statusPublished") }}</option>
          <option value="hidden">{{ t("market.admin.statusHidden") }}</option>
        </select>
      </div>

      <p v-if="loading" class="state">{{ t("market.admin.loading") }}</p>
      <p v-else-if="err" class="state err">{{ err }}</p>
      <ul v-else-if="filtered.length" class="list">
        <li v-for="item in filtered" :key="item.id" class="row">
          <div>
            <p class="title">{{ item.title }}</p>
            <p class="tiny">{{ item.type }} · {{ item.author_id }} · {{ item.status }}</p>
          </div>
          <div class="ops">
            <button @click="toggleStatus(item)">
              {{ item.status === "published" ? t("market.admin.hide") : t("market.admin.restore") }}
            </button>
            <button class="danger" @click="removeItem(item)">{{ t("market.admin.delete") }}</button>
          </div>
        </li>
      </ul>
      <p v-else class="state">{{ t("market.admin.emptyContent") }}</p>
    </section>

    <section v-else class="forum">
      <div class="filters">
        <select v-model="reportStatus" @change="loadForumReports">
          <option value="open">{{ t("market.admin.reportFilterOpen") }}</option>
          <option value="handled">{{ t("market.admin.reportFilterHandled") }}</option>
          <option value="rejected">{{ t("market.admin.reportFilterRejected") }}</option>
          <option value="all">{{ t("market.admin.reportFilterAll") }}</option>
        </select>
        <button @click="loadForumReports">{{ t("market.admin.refresh") }}</button>
      </div>

      <p v-if="forumLoading" class="state">{{ t("market.admin.loading") }}</p>
      <p v-else-if="forumErr" class="state err">{{ forumErr }}</p>
      <ul v-else-if="reports.length" class="list">
        <li v-for="r in reports" :key="r.id" class="row">
          <div class="rep">
            <p class="title">
              <strong>[{{ r.status }}]</strong>
              {{ r.reason_code }}
              <span class="tiny">· {{ new Date(r.created_at).toLocaleString() }}</span>
            </p>
            <p v-if="r.reason_text" class="tiny">{{ r.reason_text }}</p>
            <p class="tiny">
              {{ t("market.admin.target", { type: r.target_type }) }}
              <span class="mono">{{ r.target_id }}</span>
            </p>
            <p v-if="(targets[`${r.target_type}:${r.target_id}`] as { title?: string })?.title" class="tiny">
              {{
                t("market.admin.threadTitle", {
                  title: (targets[`${r.target_type}:${r.target_id}`] as { title: string }).title,
                })
              }}
            </p>
            <p v-else-if="(targets[`${r.target_type}:${r.target_id}`] as { thread_id?: string })?.thread_id" class="tiny">
              {{
                t("market.admin.postFloor", {
                  floor: (targets[`${r.target_type}:${r.target_id}`] as { floor: number }).floor,
                })
              }}
              <RouterLink :to="`/t/${(targets[`${r.target_type}:${r.target_id}`] as { thread_id: string }).thread_id}`">{{
                t("market.admin.open")
              }}</RouterLink>
            </p>
          </div>

          <div class="ops">
            <template v-if="r.status === 'open'">
              <button v-if="r.target_type === 'thread'" @click="hideThread(r)">{{ t("market.admin.hideThread") }}</button>
              <button v-if="r.target_type === 'thread'" @click="lockThread(r)">{{ t("market.admin.lockThread") }}</button>
              <button v-if="r.target_type === 'post'" @click="hidePost(r)">{{ t("market.admin.hidePost") }}</button>
              <button class="ghost" @click="rejectReport(r)">{{ t("market.admin.reject") }}</button>
            </template>
            <template v-else>
              <button class="ghost" @click="setReportStatus(r, 'open', 'reopen')">{{ t("market.admin.reopen") }}</button>
            </template>
          </div>
        </li>
      </ul>
      <p v-else class="state">{{ t("market.admin.emptyReports") }}</p>
    </section>
  </template>
</template>

<style scoped>
.page-head {
  margin-bottom: 16px;
}
.sub {
  margin: 0;
  color: var(--fg-muted);
}
.filters {
  display: flex;
  gap: 10px;
  margin: 14px 0;
}
.filters select {
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 7px 10px;
  background: var(--surface);
}
.filters button {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 8px;
  padding: 7px 12px;
  cursor: pointer;
}
.tabs {
  display: flex;
  gap: 10px;
  margin: 12px 0;
}
.tab {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 999px;
  padding: 7px 14px;
  cursor: pointer;
  font: inherit;
  color: var(--fg-muted);
}
.tab--active {
  background: var(--accent);
  color: var(--accent-fg);
  border-color: color-mix(in srgb, var(--accent) 35%, var(--border));
}
.list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 10px;
}
.row {
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--surface);
  padding: 12px;
  display: flex;
  justify-content: space-between;
  gap: 12px;
}
.title {
  margin: 0 0 4px;
  font-weight: 700;
}
.tiny {
  margin: 0;
  font-size: 0.8rem;
  color: var(--fg-soft);
}
.ops {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.ops button {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 8px;
  padding: 6px 10px;
  cursor: pointer;
}
.ops .ghost {
  color: var(--fg-muted);
}
.ops .danger {
  color: #a33f2f;
}
.rep .mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}
.state.err {
  color: var(--danger);
}
</style>
