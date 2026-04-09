/** 浏览器直接请求 api.github.com（公开仓库），无需 token；匿名约 60 次/小时/IP */

export interface GitHubReleaseAsset {
  name: string
  browser_download_url: string
  size: number
}

export interface GitHubRelease {
  id: number
  tag_name: string
  name: string | null
  published_at: string | null
  html_url: string
  body: string | null
  assets: GitHubReleaseAsset[]
}

export async function fetchReleases(
  owner: string,
  repo: string,
  perPage = 15
): Promise<GitHubRelease[]> {
  const url = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/releases?per_page=${perPage}`
  const r = await fetch(url, {
    headers: {
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  })
  if (r.status === 403) {
    const rem = r.headers.get('x-ratelimit-remaining')
    throw new Error(
      rem === '0'
        ? 'GitHub 接口访问次数暂时用完，请过几分钟再试。'
        : `GitHub 拒绝访问（403），请稍后再试。`
    )
  }
  if (!r.ok) {
    const t = await r.text()
    throw new Error(`无法拉取发布列表（${r.status}）${t ? `：${t.slice(0, 120)}` : ''}`)
  }
  return r.json() as Promise<GitHubRelease[]>
}

export function excerptBody(body: string | null, max = 220): string {
  if (!body?.trim()) return ''
  const plain = body
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/\[([^\]]+)]\([^)]+\)/g, '$1')
    .replace(/[#*_`]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  return plain.length <= max ? plain : `${plain.slice(0, max)}…`
}
