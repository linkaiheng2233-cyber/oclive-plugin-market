const BLOCKED_WORDS = ['血腥', '肢解', '虐杀', '强奸', '乱伦', '幼女', '幼男', '未成年色情', 'nude', 'rape']

export function violatesContentPolicy(...textParts: string[]): boolean {
  const text = textParts.join(' ').toLowerCase()
  return BLOCKED_WORDS.some((w) => text.includes(w.toLowerCase()))
}
