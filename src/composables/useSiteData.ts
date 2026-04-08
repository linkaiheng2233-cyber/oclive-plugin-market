import { inject, type InjectionKey, type Ref } from 'vue'
import type { SiteData } from '../types'

export const siteDataKey: InjectionKey<Ref<SiteData | null>> = Symbol('siteData')
export const siteLoadingKey: InjectionKey<Ref<boolean>> = Symbol('siteLoading')
export const siteErrorKey: InjectionKey<Ref<string>> = Symbol('siteError')

export function useSiteData() {
  const data = inject(siteDataKey)
  const loading = inject(siteLoadingKey)
  const error = inject(siteErrorKey)
  if (!data || !loading || !error) {
    throw new Error('useSiteData must be used within App')
  }
  return { data, loading, error }
}
