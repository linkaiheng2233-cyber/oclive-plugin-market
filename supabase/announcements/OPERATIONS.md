# 告示（公告）相关操作速查

在 **Supabase → SQL Editor** 里新建查询，**复制下面某一整段**进去执行即可。一般用 **postgres** 角色会绕过 RLS，能删能插。

公告数据在表 **`public.content_items`**，条件为 **`type = 'announcement'`**。

---

## 1. 列出所有公告（先看有哪些、复制要删的 `id`）

```sql
select id, title, created_at
from public.content_items
where type = 'announcement'
order by created_at desc;
```

---

## 2. 预览「只留最新一条」时会留下哪一条

```sql
select id, title, created_at
from public.content_items
where type = 'announcement'
order by created_at desc, id desc
limit 1;
```

---

## 3. 清空所有公告（一条不剩）

```sql
delete from public.content_items
where type = 'announcement';
```

清完后若要沐沐那条，再执行下面 **第 8 节** 或打开 `2026-04-09_dev_plugins_and_security_mumu.sql` 全选执行一次。

---

## 4. 只保留「最新一条」公告，其余全部删掉

**注意：**以后若需要**多条不同公告同时存在**，不要用这段。

```sql
delete from public.content_items c
where c.type = 'announcement'
  and c.id <> (
    select ci.id
    from public.content_items ci
    where ci.type = 'announcement'
    order by ci.created_at desc, ci.id desc
    limit 1
  );
```

---

## 5. 只删掉「沐沐的小喇叭…」同标题的旧行（其它标题的公告保留）

适合叠了很多条**同一标题**的沐沐公告；与 `2026-04-09_dev_plugins_and_security_mumu.sql` 开头的删除逻辑一致。

```sql
delete from public.content_items
where type = 'announcement'
  and title = '沐沐的小喇叭：接下来要忙插件和角色包啦';
```

---

## 6. 按 `id` 删掉「一条」公告

先把第 **1 节** 跑一遍，复制要删的那行的 `id`，替换下面单引号里的 UUID：

```sql
delete from public.content_items
where id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
```

---

## 7. 按 `id` 一次删掉「多条」公告

```sql
delete from public.content_items
where type = 'announcement'
  and id in (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  );
```

---

## 8. 插入（或更新）沐沐那条开发计划公告

正文、标题以仓库里的脚本为准；脚本会先 **删同标题** 再 **插入**，重复执行一般不会叠出多条同标题。

请打开同目录文件 **`2026-04-09_dev_plugins_and_security_mumu.sql`**，**全选复制**到 SQL Editor 执行整段（不要只复制一半）。

若你坚持用「仅管理员」当 `author_id`，按该文件里的说明改用方案 B。

---

## 和仓库里 `.sql` 文件的对应关系（可选）

| 文件 | 作用 |
|------|------|
| `2026-04-09_dev_plugins_and_security_mumu.sql` | 沐沐公告：同标题先删再插 + 插入 |
| `clear_all_announcements.sql` | 等同上面 **第 3 节** |
| `keep_latest_announcement_only.sql` | 等同上面 **第 4 节** |
| `cleanup_duplicate_announcements.sql` | 查询 + 注释掉的按 id / 只留最新示例 |

建库、迁移、RLS 等总流程见上一级 **`../README.md`**。
