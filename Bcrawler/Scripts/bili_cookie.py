#!/usr/bin/env python3
"""
bili_cookie.py - B站匿名 Cookie 自动管理
- 自动获取 buvid3 / buvid4
- 缓存到本地 ~/.bcrawler/cookie.json
- 其他脚本 import 这个模块直接拿 headers + cookies

用法1 (命令行刷新):
    python3 bili_cookie.py --refresh

用法2 (被其他脚本 import):
    from bili_cookie import get_session
    session = get_session()
    resp = session.get("https://api.bilibili.com/...")
"""

import json
import os
import sys
import time
from pathlib import Path

import requests

COOKIE_DIR = Path.home() / ".bcrawler"
COOKIE_FILE = COOKIE_DIR / "cookie.json"

SPI_API = "https://api.bilibili.com/x/frontend/finger/spi"

BASE_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/120.0.0.0 Safari/537.36",
    "Referer": "https://www.bilibili.com/",
    "Origin": "https://www.bilibili.com",
}


def fetch_fresh_cookies() -> dict:
    """从 B站 SPI 接口获取匿名 buvid3 / buvid4"""
    resp = requests.get(SPI_API, headers=BASE_HEADERS, timeout=10)
    resp.raise_for_status()
    data = resp.json()

    if data.get("code") != 0:
        raise RuntimeError(f"SPI API error: {data.get('message')}")

    buvid3 = data["data"]["b_3"]
    buvid4 = data["data"]["b_4"]

    cookie_data = {
        "buvid3": buvid3,
        "buvid4": buvid4,
        "fetched_at": int(time.time()),
    }

    # 缓存到磁盘
    COOKIE_DIR.mkdir(parents=True, exist_ok=True)
    COOKIE_FILE.write_text(json.dumps(cookie_data, indent=2))

    return cookie_data


def load_cookies() -> dict:
    """
    加载缓存的 cookie，如果不存在或超过 24 小时则自动刷新。
    """
    if COOKIE_FILE.exists():
        try:
            data = json.loads(COOKIE_FILE.read_text())
            age = int(time.time()) - data.get("fetched_at", 0)
            if age < 86400:  # 24 小时内有效
                return data
        except (json.JSONDecodeError, KeyError):
            pass

    # 需要刷新
    return fetch_fresh_cookies()


def get_cookies_dict() -> dict:
    """返回可直接传给 requests 的 cookies 字典"""
    data = load_cookies()
    return {
        "buvid3": data["buvid3"],
        "buvid4": data["buvid4"],
    }


def get_session() -> requests.Session:
    """
    返回一个配置好 headers + cookies 的 requests.Session。
    其他脚本直接:
        from bili_cookie import get_session
        session = get_session()
    """
    session = requests.Session()
    session.headers.update(BASE_HEADERS)
    session.cookies.update(get_cookies_dict())
    return session


def main():
    """命令行模式: 刷新 cookie 并输出"""
    import argparse
    parser = argparse.ArgumentParser(description="B站 Cookie 管理")
    parser.add_argument("--refresh", action="store_true", help="强制刷新 cookie")
    parser.add_argument("--show", action="store_true", help="显示当前 cookie")
    args = parser.parse_args()

    if args.refresh:
        data = fetch_fresh_cookies()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    elif args.show:
        data = load_cookies()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        # 默认输出当前 cookie (给 Swift 读)
        data = load_cookies()
        print(json.dumps(data, ensure_ascii=False))


if __name__ == "__main__":
    main()
