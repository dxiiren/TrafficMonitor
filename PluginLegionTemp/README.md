# LegionTemp

TrafficMonitor plugin that shows the Lenovo Legion embedded-controller temperatures.

- Items: `LegionTemp.cpu` (label `TEMP:`) and `LegionTemp.gpu` (label `GPU T:`).
- Source: WMI `root\WMI`, class `LENOVO_OTHER_METHOD`, method `GetFeatureValue(IDs, value)`.
  - `IDs = 0x05040000` CPU current temperature
  - `IDs = 0x05050000` GPU current temperature
  - IDs taken from LenovoLegionToolkit `Enums.cs` (`CpuCurrentTemperature`, `GpuCurrentTemperature`).
- Read-only. The WMI provider needs administrator rights, so TrafficMonitor must run elevated.
- WMI is polled every 2 s on a worker thread with its own COM apartment; `DataRequired` only publishes the cached value. Shows `--` when the call fails.

Build (VS 2022 Build Tools, C++): `cmd /d /c PluginLegionTemp\build.cmd` produces `LegionTemp.dll` (x64). Copy it to `<TrafficMonitor>\plugins\`.

Skin and config: see `custom/KollectMonitor` (`install.ps1`, run elevated). The skin maps the plugin item with `<plugin_map>` and enables it in the taskbar via `plugin_display_item = LegionTemp.cpu`.
