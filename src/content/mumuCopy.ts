/**
 * 社区站用户可见文案（沐沐语气：轻松、口语、不端着）
 * 与主项目示例角色「沐沐」气质一致：像邻家女孩聊天，不装专家。
 */
export const mumu = {
  siteTagline: 'Oclive · 沐沐的社区小站',

  homeEyebrow: '沐沐帮你指路',
  homeTitle: '嗨，欢迎进来逛逛～',
  homeLead:
    '这里是大家分享角色包与创作资料的地方。随便翻翻，有好东西也可以挂上来，让路过的人都能摸到。',
  homeWelcomeNoAnn:
    '今天还没有新公告，不急，先去「浏览资源」里转转，说不定能挖到宝～',
  annLoading: '等我一下……公告马上来',
  annLabel: '最新公告',

  hubBrowse: { title: '浏览资源', desc: '目前主要收录角色包与相关资料，慢慢逛～' },
  hubSubmit: { title: '发布资源', desc: '登录之后就能贴链接和说明啦，第一个投稿也超欢迎！' },
  hubAnnouncements: { title: '公告栏', desc: '维护通知、社区碎碎念，都会贴在这边。' },
  hubVersions: { title: '发布汇总', desc: '启动器、主程序、编写器去哪儿下？点这里。' },
  hubMe: { title: '个人设置', desc: '改昵称、头像，还有魔法链接登录～' },
  hubManage: { title: '我的上传', desc: '你发过的内容都在这里，想改想删都行。' },
  hubForum: { title: '论坛', desc: '像贴吧那样发帖回帖；遇到垃圾就举报，管理员会来收拾～' },

  noSupabase:
    '咦，这边没连上云端……检查一下 README 里的 Supabase 配置好不好？配好了刷新就能用啦。',

  browseTitle: '逛逛都有啥',
  browseSub: '下面都是已发布的投稿；可以搜关键字、排个序～',
  browseSearchPlaceholder: '搜标题、描述或标签……',
  sortNewest: '最新优先',
  sortOldest: '最早优先',
  sortTitle: '标题 A-Z',
  loading: '加载中……稍等哦',
  emptyBrowse:
    '这边还空荡荡的……要不当第一个发帖的人？点右上角「发布资源」试试～',
  noSearchResults: '没搜到匹配的，换个词试试？或者把筛选改成「全部类型」。',

  announcementsTitle: '公告栏',
  announcementsSub: '维护啊、碎碎念啊、重要的事都会写在这里。',
  emptyAnnouncements: '暂时没有公告，去首页或其它页面逛逛吧～',

  detailLoading: '等我一下……马上好',
  detailNotFound: '咦，找不到这一页……可能删了或者链接抄错啦。',
  detailLoadErr: '加载失败了：',
  detailCrumbBrowse: '回去逛逛',
  dlHint: '链接是作者自己填的，点之前多留个心眼哦；出问题沐沐这边可背不了锅～',
  detailNoDlAnnouncement: '这是公告，没有外挂下载链接啦～',

  submitTitle: '挂个资源上来',
  submitSub: '填完就会出现在浏览里（V1 先不审，大家自觉别乱来哦）。公告只有管理员能发。',
  submitErrorLogin: '先登录一下再来投稿吧～',
  submitErrorFields: '标题、描述、版本都要填好哦。',
  submitErrorUrl: '除了公告以外，链接也要填的～',
  submitErrorAnnounce: '你没有发公告的权限啦。',
  submitErrorPolicy: '内容里碰到了禁用词，改一改再发吧。',
  submitHintUrl: '公告可以不填链接；其它类型记得填网盘或 Release 直链～',
  submitBtn: '发布',
  submitBtnLoading: '正在提交……',

  toastSignOut: '好，已经帮你退出啦。',
  toastEmailSent: '邮件发出去啦，去邮箱点一下链接就能登录～',
} as const
