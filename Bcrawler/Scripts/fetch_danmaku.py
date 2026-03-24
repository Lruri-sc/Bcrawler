#!/usr/bin/env python3
"""
fetch_danmaku.py - 批量爬取弹幕并转换为 ASS 字幕
用法: python3 fetch_danmaku.py --cids "123,456,789" --titles '["第1话","第2话","第3话"]' --output /path/to/dir
输出: 每行一个 JSON 进度消息到 stdout
"""

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from typing import Optional

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bili_cookie import get_session

DANMAKU_XML_API = "https://comment.bilibili.com/{cid}.xml"

# ─── ASS Template ───────────────────────────────────────────────

ASS_HEADER = """[Script Info]
Title: {title}
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
Timer: 100.0000
WrapStyle: 2

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: R2L,Microsoft YaHei,54,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,2.0,0,2,20,20,2,1
Style: Top,Microsoft YaHei,54,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,2.0,0,8,20,20,2,1
Style: Bottom,Microsoft YaHei,54,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,2.0,0,2,20,20,2,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""


def parse_danmaku_xml(xml_content: bytes) -> list[dict]:
    danmakus = []
    try:
        root = ET.fromstring(xml_content)
    except ET.ParseError:
        return danmakus

    for d in root.findall("d"):
        text = d.text
        if not text:
            continue
        p = d.get("p", "")
        parts = p.split(",")
        if len(parts) < 8:
            continue
        try:
            danmakus.append({
                "time": float(parts[0]),
                "mode": int(parts[1]),
                "size": int(parts[2]),
                "color": int(parts[3]),
                "text": text.strip(),
            })
        except (ValueError, IndexError):
            continue

    danmakus.sort(key=lambda x: x["time"])
    return danmakus


def seconds_to_ass_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h}:{m:02d}:{s:05.2f}"


def color_to_ass(color_int: int) -> str:
    r = (color_int >> 16) & 0xFF
    g = (color_int >> 8) & 0xFF
    b = color_int & 0xFF
    return f"&H00{b:02X}{g:02X}{r:02X}"


def danmaku_to_ass(danmakus: list[dict], title: str = "Danmaku") -> str:
    lines = [ASS_HEADER.format(title=title)]
    scroll_duration = 12.0
    top_duration = 5.0

    for dm in danmakus:
        start = seconds_to_ass_time(dm["time"])
        color_tag = ""
        if dm["color"] != 16777215:
            color_tag = f"\\c{color_to_ass(dm['color'])}"
        size_tag = ""
        if dm["size"] != 25:
            scaled = int(dm["size"] * 54 / 25)
            size_tag = f"\\fs{scaled}"
        override = ""
        if color_tag or size_tag:
            override = "{" + color_tag + size_tag + "}"

        text = dm["text"].replace("\\", "\\\\").replace("{", "\\{").replace("}", "\\}")
        mode = dm["mode"]

        if mode in (1, 2, 3):
            end = seconds_to_ass_time(dm["time"] + scroll_duration)
            effect_text = f"{{\\move(1940,0,-20,0)}}{override}{text}" if override else f"{{\\move(1940,0,-20,0)}}{text}"
            lines.append(f"Dialogue: 0,{start},{end},R2L,,20,20,2,,{effect_text}")
        elif mode == 4:
            end = seconds_to_ass_time(dm["time"] + top_duration)
            lines.append(f"Dialogue: 0,{start},{end},Bottom,,20,20,2,,{override}{text}")
        elif mode == 5:
            end = seconds_to_ass_time(dm["time"] + top_duration)
            lines.append(f"Dialogue: 0,{start},{end},Top,,20,20,2,,{override}{text}")

    return "\n".join(lines)


def report(current: int, total: int, episode: str, status: str,
           file_path: Optional[str] = None, error: Optional[str] = None):
    msg = {
        "current": current,
        "total": total,
        "episode": episode,
        "status": status,
        "filePath": file_path,
        "error": error,
    }
    print(json.dumps(msg, ensure_ascii=False), flush=True)


def fetch_and_convert(session, cid: int, title: str, output_dir: str, idx: int, total: int):
    report(idx, total, title, "downloading")

    url = DANMAKU_XML_API.format(cid=cid)
    resp = session.get(url, timeout=15)
    resp.raise_for_status()

    report(idx, total, title, "converting")

    danmakus = parse_danmaku_xml(resp.content)
    ass_content = danmaku_to_ass(danmakus, title=title)

    safe_title = re.sub(r'[\\/:*?"<>|]', "_", title)
    output_path = os.path.join(output_dir, f"{safe_title}.ass")

    with open(output_path, "w", encoding="utf-8-sig") as f:
        f.write(ass_content)

    report(idx, total, title, "complete", file_path=output_path)


def main():
    parser = argparse.ArgumentParser(description="批量爬取弹幕并转换 ASS")
    parser.add_argument("--cids", required=True, help="逗号分隔的 cid 列表")
    parser.add_argument("--titles", required=True, help="JSON 格式的标题列表")
    parser.add_argument("--output", required=True, help="输出目录")
    args = parser.parse_args()

    cids = [int(c.strip()) for c in args.cids.split(",")]
    titles = json.loads(args.titles)
    output_dir = args.output
    os.makedirs(output_dir, exist_ok=True)

    session = get_session()
    total = len(cids)

    for i, (cid, title) in enumerate(zip(cids, titles), start=1):
        try:
            fetch_and_convert(session, cid, title, output_dir, i, total)
        except Exception as e:
            report(i, total, title, "error", error=str(e))


if __name__ == "__main__":
    main()
