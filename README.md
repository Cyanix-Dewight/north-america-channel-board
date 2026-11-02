# 北美渠道总看板 · North America Channel Board

零售商与代理/集成商的渠道开发看板，单文件离线 HTML + Streamlit 外壳。
数据源：`北美渠道客户整理 (6).xlsx`（零售商 65 家 / 代理集成商 60 家 / 竞品格局 47 条）。

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
dashboard/index.html    看板本体（自包含，无外链）
```

## 本地运行

```bash
pip install -r requirements.txt
streamlit run app.py
```

打开 http://localhost:8501 ，如需调整嵌入高度：`http://localhost:8501/?h=1300`。

## 部署到 Streamlit Community Cloud

1. 打开 https://share.streamlit.io ，用 GitHub 账号登录并授权。
2. 点 **Create app** → **Deploy a public app from GitHub**。
3. 填：Repository `Cyanix-Dewight/north-america-channel-board`、Branch `main`、Main file path `app.py`。
4. （可选）在 Advanced settings 里选 Python 3.11。
5. 点 **Deploy**，首次构建约 1–3 分钟，完成后得到 `https://<app-name>.streamlit.app`。

## 更新看板

看板由本地工程构建，产物是单个 HTML：

```bash
python build_v5.py       # 生成 北美渠道总看板.html
python publish.py        # 复制到 deploy/dashboard/index.html
```

然后把 `deploy/` 的内容推到本仓库（网页上传或 `git push`），Streamlit Cloud 检测到提交会自动重新部署。

## 注意

- 看板是**单文件离线**的，所有数据内联在 HTML 里；更新数据必须重新构建并推送，不是实时读 Excel。
- 「开发跟进」页填写的内容存在**访问者自己的浏览器**（localStorage），不写回 Excel，也不会同步给其他人。要交接或留档请用页面上的**导出 CSV**（支持再导入）。
- 空值一律显示为「未填写 / 未量化 / 待核实」，不填 0、不推测。
- 加元按 1 CAD = 0.73 USD 折算，属口径假设，非实时汇率。
