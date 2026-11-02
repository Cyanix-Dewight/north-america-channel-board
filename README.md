# 北美渠道总看板 · North America Channel Board

零售商与代理/集成商的渠道开发看板，单文件离线 HTML + Streamlit 外壳。
数据源：`北美渠道客户整理 (6).xlsx`（零售商 65 家 / 代理集成商 60 家 / 竞品格局 47 条）。

## 访问地址

| 方式 | 地址 | 说明 |
|---|---|---|
| **GitHub Pages**（推荐） | https://cyanix-dewight.github.io/north-america-channel-board/ | 静态直开、满屏显示，打开即用 |
| Streamlit | 部署后为 `https://<app-name>.streamlit.app` | 需要在 share.streamlit.io 手动创建（见下文） |

## 页面结构

| 页签 | 内容 |
|---|---|
| 总览 | P1–P3 分布、体量 Top 12（对数刻度）、体量分档、国家分布、推进阶段漏斗、本期判断 |
| P 码总表 | 按 P 码 → 体量排序的完整清单，点任意行看体量与判断依据 |
| 开发跟进 | 可编辑的跟进记录表：阶段 / 下一步 / 负责人 / 计划与最近跟进 / 难点 / 预期方向 / 数据核实 |
| 体量分析 | 统一美元口径的体量排行、加元折算明细、体量 × 竞品 SKU 散点 |
| 竞品与入驻预判 / P 码判定与校准 | 零售商侧看 OBSBOT 产品落位建议；代理侧看三因子判定与原表校准 |
| 总部地图 | 北美总部位置与密度 |
| 客户主表 | 全字段表格 + 排序 + CSV 导出 |
| 方法与口径 | 每一步算法与数据口径，可复核 |

顶部「零售商 / 代理 / 集成商」切换决定当前看到的是哪一类客户，页签随之显隐。

## 目录

```
app.py                  Streamlit 入口（嵌入 dashboard/index.html）
requirements.txt        依赖
.streamlit/config.toml  主题与服务器配置
dashboard/index.html    看板本体（Streamlit 读取的副本）
docs/index.html         看板本体（GitHub Pages 托管的页面）
docs/.nojekyll          让 Pages 跳过 Jekyll 处理
```

两份 HTML 内容完全一致，`publish.py` 会同时更新，避免改了一边忘了另一边。

## 本地运行

```bash
pip install -r requirements.txt
streamlit run app.py
```

打开 http://localhost:8501 ，如需调整嵌入高度：`http://localhost:8501/?h=1300`。

## 部署到 Streamlit Community Cloud（可选）

GitHub Pages 已经能直接访问，如果还想要 Streamlit 入口：

1. 打开 https://share.streamlit.io ，用 GitHub 账号登录并授权。
2. 点 **Create app** → **Deploy a public app from GitHub**。
3. 填：Repository `Cyanix-Dewight/north-america-channel-board`、Branch `main`、Main file path `app.py`。
4. （可选）在 Advanced settings 里选 Python 3.11。
5. 点 **Deploy**，首次构建约 1–3 分钟，完成后得到 `https://<app-name>.streamlit.app`。

## 更新看板

看板由本地工程构建，产物是单个 HTML：

```bash
python build_v5.py       # 生成 北美渠道总看板.html
python publish.py        # 同步到 dashboard/index.html 与 docs/index.html
cd deploy && git add -A && git commit -m "update dashboard" && git push
```

推送后 GitHub Pages 会在 30–60 秒内自动重建；Streamlit 若已创建则同步重新部署。

GitHub Pages 的站点源配置在仓库 **Settings → Pages**（Source: `main` 分支的 `/docs` 目录），一般不需要再动。

## 多人协作填写（开发跟进页）

跟进记录已经不是「各存各的」了。通过网址打开时：

- 右上角有 **填写人** 输入框，填一次会记在这台浏览器上，之后每次提交都会带上你的名字（鼠标悬停行可看到「最近更新」）。
- 卡片右上角的状态角标：**云端已同步 18:37** 表示正常；**云端未连接 · 已存本机** 表示网络或服务异常，改动先存本地并自动重试。
- 任何人改动任意一格，其他人的页面**每 6 秒自动拉取一次**（切回标签页时立即拉取），不需要刷新。
- **按字段保存**：两个人同时改同一家的不同列不会互相覆盖；改同一列以最后一次提交为准。
- 写入失败会做 3 次短退避重试，仍失败则入队，每 2.5 秒再试；改动没写进云端就关页面，浏览器会弹出确认提示。

**注意**：直接用 `file://` 双击本地 HTML 打开时，不会联网，角标显示「本机记录」，行为与旧版本一致（数据只在这台电脑）。要协作必须走网址。

数据存在云端表 `pipe_records`（WorkBuddy 云服务，`wbapp_AGkoQ4nhcy53ZjRenRni7X`），主键是 `客户类型|客户名`，所以 Excel 行序调整不会错位。云端表**不开放删除**：页面上的「清空记录」只清当前浏览器缓存，不会删掉同事填的内容。

## 注意

- 看板是**单文件离线**的，所有渠道数据内联在 HTML 里；更新数据必须重新构建并推送，不是实时读 Excel。
- 只有「开发跟进」页的填写内容会同步到云端；P 码、体量、竞品这些分析结果仍是构建时算好的。
- 空值一律显示为「未填写 / 未量化 / 待核实」，不填 0、不推测。
- 加元按 1 CAD = 0.73 USD 折算，属口径假设，非实时汇率。
