# -*- coding: utf-8 -*-
"""Streamlit 入口：把单文件看板整体嵌进页面。

看板本身是自包含的 HTML（无外链），这里只做一层容器：
- 隐藏 Streamlit 自带的工具栏 / 页头 / 页脚，让看板满屏
- iframe 高度可用 URL 参数调整：?h=1200
"""
from pathlib import Path

import streamlit as st
import streamlit.components.v1 as components

st.set_page_config(
    page_title="北美渠道总看板",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="collapsed",
)

DASH = Path(__file__).parent / "dashboard" / "index.html"

st.markdown(
    """
    <style>
      #MainMenu, header[data-testid="stHeader"], footer {visibility: hidden; height: 0;}
      [data-testid="stAppViewContainer"] > .main {padding: 0;}
      [data-testid="stVerticalBlock"] {gap: 0;}
      .block-container {padding: 0 !important; max-width: 100% !important;}
      iframe {border: 0; display: block;}
    </style>
    """,
    unsafe_allow_html=True,
)

if not DASH.exists():
    st.error(f"找不到看板文件：{DASH}。请把构建产物放到 dashboard/index.html。")
    st.stop()

try:
    height = int(st.query_params.get("h", 1120))
except (TypeError, ValueError):
    height = 1120

components.html(DASH.read_text(encoding="utf-8"), height=height, scrolling=True)
