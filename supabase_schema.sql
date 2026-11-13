-- ============================================================
-- OBSBOT 全球渠道总看板 · Supabase 建表脚本
-- 用法：注册 supabase.com → 建一个 Project → 左侧 SQL Editor
--       粘贴本文件全部内容执行一次即可。
-- 与 WorkBuddy 侧两张表逐列对齐（pipe_records 15 列 +
-- customers_extra 24 列），迁移脚本 src/migrate_to_supabase.py
-- 可在两个通道之间互搬数据。
-- 安全定位：anon key 公开可读写（与 WorkBuddy publishableKey
-- 同级），只放跟进记录这类非敏感协作数据，勿放机密信息。
-- ============================================================

-- ---------- 表一：跟进记录 ----------
CREATE TABLE IF NOT EXISTS public.pipe_records (
  id          text PRIMARY KEY,              -- 格式：类型|去空白客户名，如 agent|StaplesCanada
  ctype       text NOT NULL,                 -- retailer | agent
  customer    text NOT NULL,                 -- 原始客户名（含空格）
  stage       text,                          -- 当前阶段：未接触/已建联/已回复/实质沟通/报价·谈判/已合作·维护中…
  next_action text,                          -- 下一步行动（可换行）
  done_action text,                          -- 已完成动作（可换行）
  owner       text,                          -- 负责人
  plan_date   text,                          -- 计划跟进日期 YYYY-MM-DD
  last_date   text,                          -- 最近跟进日期 YYYY-MM-DD
  difficulty  text,                          -- 开发难点（可换行）
  direction   text,                          -- 方向判断
  verify      text,                          -- 数据核实
  note        text,                          -- 备注（可换行）
  updated_by  text,                          -- 最后填写人
  updated_at  timestamptz DEFAULT now()      -- 服务端时间戳，触发器统一维护
);

COMMENT ON TABLE public.pipe_records IS '客户开发跟进记录：主键 类型|客户名，多人协作，单字段 upsert 不互相覆盖';

-- ---------- 表二：手工录入 / 批量导入的客户 ----------
CREATE TABLE IF NOT EXISTS public.customers_extra (
  id          text PRIMARY KEY,              -- 格式：类型|去空白客户名
  ctype       text NOT NULL,                 -- retailer | agent
  name        text NOT NULL,                 -- 客户名（与官网一致）
  country     text DEFAULT '',               -- ISO 码，如 US/DE/DK
  priority    text DEFAULT '',               -- P1/P2/P3
  intro       text DEFAULT '',               -- 一句话简介
  site        text DEFAULT '',               -- 官网
  region      text DEFAULT '',               -- 覆盖区域
  cats        text DEFAULT '',               -- 主要品类（代理侧）
  ind         text DEFAULT '',               -- 目标行业（14 档）
  owner       text DEFAULT '',               -- 负责人
  note        text DEFAULT '',               -- 备注
  scale_text  text DEFAULT '',               -- 综合体量原文（如 250~260 亿美元）
  comp_raw    text DEFAULT '',               -- 头部竞品品牌体量原文
  webcam_vol  text DEFAULT '',               -- Webcam体量（可推测/预估）
  store_raw   text DEFAULT '',               -- 门店数量原文
  has_store   text DEFAULT '',               -- 是否有门店
  webcam_on   text DEFAULT '',               -- 是否在售webcam
  coop        text DEFAULT '',               -- 是否在合作
  contact     text DEFAULT '',               -- 是否建联
  extra       text DEFAULT '',               -- 预留扩展
  updated_by  text,
  updated_at  timestamptz DEFAULT now(),
  created_at  timestamptz DEFAULT now()
);

COMMENT ON TABLE public.customers_extra IS '客户录入页写入的新客户（单人 + 批量导入），不进源表，构建不会被冲掉';

-- ---------- 时间戳触发器：updated_at 一律以服务端时钟为准 ----------
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS pipe_touch_ts ON public.pipe_records;
CREATE TRIGGER pipe_touch_ts
  BEFORE INSERT OR UPDATE ON public.pipe_records
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS extra_touch_ts ON public.customers_extra;
CREATE TRIGGER extra_touch_ts
  BEFORE INSERT OR UPDATE ON public.customers_extra
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ---------- RLS：anon（共享链接里的页面）与 authenticated 全放开 ----------
-- 与 WorkBuddy 侧策略一致；页面 key 是公开的，只承载非敏感协作数据
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pipe_records    TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customers_extra  TO anon, authenticated;

ALTER TABLE public.pipe_records   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers_extra ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pipe_read   ON public.pipe_records;
DROP POLICY IF EXISTS pipe_insert ON public.pipe_records;
DROP POLICY IF EXISTS pipe_update ON public.pipe_records;
DROP POLICY IF EXISTS pipe_delete ON public.pipe_records;
CREATE POLICY pipe_read   ON public.pipe_records FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY pipe_insert ON public.pipe_records FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY pipe_update ON public.pipe_records FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY pipe_delete ON public.pipe_records FOR DELETE TO anon, authenticated USING (true);

DROP POLICY IF EXISTS extra_read   ON public.customers_extra;
DROP POLICY IF EXISTS extra_insert ON public.customers_extra;
DROP POLICY IF EXISTS extra_update ON public.customers_extra;
DROP POLICY IF EXISTS extra_delete ON public.customers_extra;
CREATE POLICY extra_read   ON public.customers_extra FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY extra_insert ON public.customers_extra FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY extra_update ON public.customers_extra FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY extra_delete ON public.customers_extra FOR DELETE TO anon, authenticated USING (true);

-- ---------- 表三：跟进历史（2026-11 新增，只增不改不删） ----------
-- 每次跟进字段落库后自动追加一行（旧值→新值 · 谁 · 何时），抽屉里的
-- 「跟进历史」时间线读它。页面同步写入，无需人工操作。
-- 注意：这张表可以后补——在旧库上重跑本文件全部内容是幂等的
-- （IF NOT EXISTS + DROP POLICY IF EXISTS），已建过的表不会被改动。
CREATE TABLE IF NOT EXISTS public.pipe_history (
  hid        bigserial PRIMARY KEY,          -- 自增，只增不改
  record_id  text NOT NULL,                  -- 对应 pipe_records.id
  ctype      text,
  customer   text,
  field      text,                           -- 内部字段名：stage/done/next/planDate/lastDate/owner/difficulty/direction/verify/note
  old_val    text,
  new_val    text,
  by         text,                           -- 填写人
  at         timestamptz DEFAULT now()
);

COMMENT ON TABLE public.pipe_history IS '跟进字段修改留痕：只插入，不开放 UPDATE/DELETE，保证历史不可篡改';

CREATE INDEX IF NOT EXISTS pipe_history_rec_idx ON public.pipe_history (record_id, at DESC);

GRANT SELECT, INSERT ON public.pipe_history TO anon, authenticated;   -- 有意不给 UPDATE/DELETE

ALTER TABLE public.pipe_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS hist_read   ON public.pipe_history;
DROP POLICY IF EXISTS hist_insert ON public.pipe_history;
CREATE POLICY hist_read   ON public.pipe_history FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY hist_insert ON public.pipe_history FOR INSERT TO anon, authenticated WITH CHECK (true);

-- 执行完成后：
--   1. python src/migrate_to_supabase.py --check   验证连通
--   2. python src/migrate_to_supabase.py --seed    灌入本地种子（Evelyn 680 条 + 手工录入 2 家）
--   3. WorkBuddy 额度恢复后：
--      python src/migrate_to_supabase.py --from-workbuddy   把旧库全部记录搬过来（含 Cyan 填的原表客户）
