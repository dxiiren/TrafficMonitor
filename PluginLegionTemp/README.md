# LegionTemp

TrafficMonitor plugin that shows the Lenovo Legion embedded-controller temperatures.

- Items (custom-drawn, value colour-coded by status): `LegionTemp.cpu_usage` (`CPU:`), `LegionTemp.mem` (`MEM:`), `LegionTemp.gpu_usage` (`GPU:`), `LegionTemp.cpu` (`TEMP:`, EC CPU temperature). `LegionTemp.gpu` (`GPU T:`) stays plain text.
- Status colours (label keeps the normal text colour, only the value changes):

  | Item | Normal | Yellow | Red |
  |---|---|---|---|
  | CPU / MEM / GPU % | below 60 | 60 to 85 | above 85 |
  | TEMP (Celsius) | below 70 | 70 to 85 | above 85 |

  Normal is the host's own text colour. Yellow is RGB(255,192,0) on dark and RGB(200,140,0) on light; red is RGB(255,70,70) on dark and RGB(200,0,0) on light. Logic lives in `Thresholds.h`; `test.cmd` builds and runs the `TestThresholds.cpp` harness.
- Source: WMI `root\WMI`, class `LENOVO_OTHER_METHOD`, method `GetFeatureValue(IDs, value)`.
  - `IDs = 0x05040000` CPU current temperature
  - `IDs = 0x05050000` GPU current temperature
  - IDs taken from LenovoLegionToolkit `Enums.cs` (`CpuCurrentTemperature`, `GpuCurrentTemperature`).
- Read-only. The WMI provider needs administrator rights, so TrafficMonitor must run elevated.
- WMI is polled every 2 s on a worker thread with its own COM apartment; `DataRequired` only publishes the cached value. Shows `--` when the call fails.

Build (VS 2022 Build Tools, C++): `cmd /d /c PluginLegionTemp\build.cmd` produces `LegionTemp.dll` (x64). Copy it to `<TrafficMonitor>\plugins\`.

Skin and config: see `custom/KollectMonitor` (`install.ps1`, run elevated). The skin maps the four items with `<plugin_map>`; the taskbar shows them via `tbar_display_item = 0` and `plugin_display_item = LegionTemp.cpu,LegionTemp.cpu_usage,LegionTemp.gpu_usage,LegionTemp.mem`. The config also sets `always_on_top = false` and `lock_window_pos = true`.
