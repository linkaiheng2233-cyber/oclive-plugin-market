/** 无客户端或未注册协议时引导下载 */
export const OCLIVE_CLIENT_RELEASE_LATEST =
  "https://github.com/oclive/oclive/releases/latest";

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

export function ocliveInstallHref(gitUrl: string): string {
  return `oclive://install?plugin=${encodeURIComponent(gitUrl)}`;
}
