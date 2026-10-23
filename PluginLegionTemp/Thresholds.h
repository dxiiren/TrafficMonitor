// Status thresholds and colours for the LegionTemp plugin items (no Windows dependency, unit-tested by TestThresholds.cpp).
#pragma once

namespace legion {

enum class Level { Normal = 0, Warn = 1, Crit = 2 };

constexpr int USAGE_WARN = 60, USAGE_CRIT = 85; // CPU / MEM / GPU percent: <60 normal, 60..85 yellow, >85 red
constexpr int TEMP_WARN = 70, TEMP_CRIT = 85;   // Celsius: <70 normal, 70..85 yellow, >85 red

constexpr Level Classify(int value, int warn, int crit)
{
    return value < 0 ? Level::Normal : value > crit ? Level::Crit : value >= warn ? Level::Warn : Level::Normal;
}
constexpr Level UsageLevel(int percent) { return Classify(percent, USAGE_WARN, USAGE_CRIT); }
constexpr Level TempLevel(int celsius) { return Classify(celsius, TEMP_WARN, TEMP_CRIT); }

// 0x00BBGGRR (same layout as the Win32 RGB macro). Normal returns the host's own text colour, passed in.
constexpr unsigned long Rgb(unsigned r, unsigned g, unsigned b) { return r | (g << 8) | (b << 16); }
constexpr unsigned long LevelColor(Level l, bool dark_mode, unsigned long normal_color)
{
    return l == Level::Warn ? (dark_mode ? Rgb(255, 192, 0) : Rgb(200, 140, 0))
         : l == Level::Crit ? (dark_mode ? Rgb(255, 70, 70) : Rgb(200, 0, 0))
         : normal_color;
}

} // namespace legion
