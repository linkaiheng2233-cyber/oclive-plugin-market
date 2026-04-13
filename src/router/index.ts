import { createRouter, createWebHistory } from 'vue-router'
import { getSupabaseClient } from '../lib/supabase'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: () => import('../views/HomeView.vue') },
    { path: '/browse', name: 'browse', component: () => import('../views/BrowseView.vue') },
    { path: '/item/:id', name: 'item-detail', component: () => import('../views/ItemDetailView.vue'), props: true },
    {
      path: '/submit',
      name: 'submit',
      meta: { requiresAuth: true },
      component: () => import('../views/SubmitResourceView.vue'),
    },
    { path: '/announcements', name: 'announcements', component: () => import('../views/AnnouncementsView.vue') },
    { path: '/me', name: 'personal', component: () => import('../views/PersonalView.vue') },
    { path: '/manage', name: 'manage', component: () => import('../views/ManageView.vue') },
    { path: '/admin', name: 'admin', component: () => import('../views/AdminView.vue') },
    { path: '/versions', name: 'versions', component: () => import('../views/VersionsView.vue') },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true
  const supabase = getSupabaseClient()
  if (!supabase) return { name: 'home' }
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (session) return true
  return { name: 'personal', query: { redirect: to.fullPath } }
})

export default router
