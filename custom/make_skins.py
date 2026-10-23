"""Generate the three compact Kollect skins (A = 2x2, B = one-line strip, C = vertical stack).

Each skin uses the LegionTemp plugin items (colour-coded CPU / MEM / GPU / TEMP).
Writes custom/KollectA, custom/KollectB, custom/KollectC (skin.xml + backgrounds via make_bg.ps1).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))

SKINS = {
    # name: (width, height, [(item, x, y, w), ...])
    "KollectA": (184, 46, [("lt_cpu", 10, 3, 76), ("lt_mem", 100, 3, 76), ("lt_gpu", 10, 24, 76), ("lt_temp", 100, 24, 76)]),
    "KollectB": (380, 24, [("lt_cpu", 10, 2, 80), ("lt_mem", 100, 2, 82), ("lt_gpu", 194, 2, 78), ("lt_temp", 284, 2, 86)]),
    "KollectC": (96, 88, [("lt_cpu", 10, 3, 80), ("lt_mem", 10, 24, 80), ("lt_gpu", 10, 45, 80), ("lt_temp", 10, 66, 80)]),
}
LABELS = {"lt_cpu": "CPU  ", "lt_mem": "MEM  ", "lt_gpu": "GPU  ", "lt_temp": "TMP  "}
HIDDEN = ["cpu", "memory", "gpu", "cpu_temperature", "gpu_temperature", "up", "down", "hdd_temperature"]


def layout(tag, w, h, items):
    rows = [f'\t\t<{tag} width="{w}" height="{h}">']
    for name, x, y, iw in items:
        rows.append(f'\t\t\t<{name} x="{x}" y="{y}" width="{iw}" align="0" show="1"/>')
    for name in HIDDEN:
        rows.append(f'\t\t\t<{name} x="0" y="0" width="0" align="0" show="0"/>')
    rows.append(f"\t\t</{tag}>")
    return "\n".join(rows)


for name, (w, h, items) in SKINS.items():
    d = os.path.join(HERE, name)
    os.makedirs(d, exist_ok=True)
    xml = "\n".join([
        "<root>",
        "\t<plugin_map>",
        "\t\t<lt_cpu>LegionTemp.cpu_usage</lt_cpu>",
        "\t\t<lt_mem>LegionTemp.mem</lt_mem>",
        "\t\t<lt_gpu>LegionTemp.gpu_usage</lt_gpu>",
        "\t\t<lt_temp>LegionTemp.cpu</lt_temp>",
        "\t</plugin_map>",
        "\t<skin>",
        "\t\t<text_color>16777215</text_color>",
        "\t\t<specify_each_item_color>0</specify_each_item_color>",
        "\t\t<skin_author>Kollect</skin_author>",
        '\t\t<font name="Segoe UI" size="9" style="0"/>',
        "\t\t<display_text>",
        *[f"\t\t\t<{k}>{v}</{k}>" for k, v in LABELS.items()],
        "\t\t</display_text>",
        "\t</skin>",
        '\t<layout text_height="18" no_label="0">',
        layout("layout_l", w, h, items),
        layout("layout_s", w, h, items),
        "\t</layout>",
        f'\t<preview width="{w + 10}" height="{h + 10}">',
        '\t\t<l x="0" y="0"/>',
        '\t\t<s x="0" y="0"/>',
        "\t</preview>",
        "</root>",
        "",
    ])
    with open(os.path.join(d, "skin.xml"), "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"{name}: {w}x{h}, {len(items)} items")
