-- 添加 announcement 类型，并限制仅管理员可插入公告

ALTER TABLE public.content_items
  DROP CONSTRAINT IF EXISTS content_items_type_check;

ALTER TABLE public.content_items
  ADD CONSTRAINT content_items_type_check
  CHECK (type IN ('character', 'plugin', 'module', 'branch', 'announcement'));

DROP POLICY IF EXISTS "authors can insert content" ON public.content_items;

CREATE POLICY "authors can insert content"
  ON public.content_items
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = author_id
    AND (
      type IS DISTINCT FROM 'announcement'
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.is_admin = true
      )
    )
  );
