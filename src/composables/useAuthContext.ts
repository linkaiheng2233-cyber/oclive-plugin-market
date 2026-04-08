import { inject, type InjectionKey, type Ref } from 'vue'

export interface AuthContext {
  authConfigured: Ref<boolean>
  authBusy: Ref<boolean>
  userId: Ref<string>
  userEmail: Ref<string>
  username: Ref<string>
  avatarUrl: Ref<string>
  isAdmin: Ref<boolean>
  signInWithEmail: (email: string) => Promise<void>
  signOut: () => Promise<void>
  refreshProfile: () => Promise<void>
}

export const authContextKey: InjectionKey<AuthContext> = Symbol('authContext')

export function useAuthContext() {
  const ctx = inject(authContextKey)
  if (!ctx) throw new Error('useAuthContext must be used within App')
  return ctx
}

