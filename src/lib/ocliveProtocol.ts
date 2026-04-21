/** 无客户端或未注册协议时引导下载 */
export const OCLIVE_CLIENT_RELEASE_LATEST =
  "https://github.com/oclive/oclive/releases/latest";

/** 构建时注入，与客户端 `DEFAULT_PLUGIN_INDEX_URL` / `OCLIVE_PLUGIN_INDEX_URL` 对齐 */
export function pluginIndexUrlFromEnv(): string {
  const u = import.meta.env.VITE_PLUGIN_INDEX_URL
  return typeof u === "string" ? u.trim() : ""
}

/**
 * 使用 `metadata.git` 构造 `oclive://install?plugin=<git_url>`（`git_url` 经 encodeURIComponent）。
 * 浏览器打开后由已安装的 Oclive 客户端（协议处理器）接收。
 */
export function ocliveInstallHrefFromGit(gitUrl: string): string {
  const g = gitUrl.trim()
  if (!g) return ""
  return `oclive://install?plugin=${encodeURIComponent(g)}`
}

/** @deprecated 使用 {@link ocliveInstallHrefFromGit}，语义更明确 */
export function ocliveInstallHref(gitUrl: string): string {
  return ocliveInstallHrefFromGit(gitUrl)
}

export function gitUrlFromContentMetadata(
  metadata: Record<string, unknown> | undefined,
): string | null {
  if (!metadata) return null;
  const g = metadata.git;
  if (typeof g === "string" && g.trim()) {
    return g.trim();
  }
  return null;
}
