// Console harness for the threshold logic. Build + run: PluginLegionTemp\test.cmd
#include <cstdio>
#include "Thresholds.h"
using namespace legion;
static int fails = 0;
static void Check(const char* what, bool ok) { std::printf("%s  %s\n", ok ? "PASS" : "FAIL", what); if (!ok) ++fails; }
int main()
{
    Check("usage 0 normal", UsageLevel(0) == Level::Normal);
    Check("usage 59 normal", UsageLevel(59) == Level::Normal);
    Check("usage 60 yellow", UsageLevel(60) == Level::Warn);
    Check("usage 85 yellow", UsageLevel(85) == Level::Warn);
    Check("usage 86 red", UsageLevel(86) == Level::Crit);
    Check("usage 100 red", UsageLevel(100) == Level::Crit);
    Check("usage -1 (n/a) normal", UsageLevel(-1) == Level::Normal);
    Check("temp 69 normal", TempLevel(69) == Level::Normal);
    Check("temp 70 yellow", TempLevel(70) == Level::Warn);
    Check("temp 85 yellow", TempLevel(85) == Level::Warn);
    Check("temp 86 red", TempLevel(86) == Level::Crit);
    Check("dark yellow RGB(255,192,0)", LevelColor(Level::Warn, true, 0) == Rgb(255, 192, 0));
    Check("light yellow RGB(200,140,0)", LevelColor(Level::Warn, false, 0) == Rgb(200, 140, 0));
    Check("dark red RGB(255,70,70)", LevelColor(Level::Crit, true, 0) == Rgb(255, 70, 70));
    Check("light red RGB(200,0,0)", LevelColor(Level::Crit, false, 0) == Rgb(200, 0, 0));
    Check("normal passes host colour", LevelColor(Level::Normal, true, 0x123456) == 0x123456);
    std::printf(fails ? "FAILED %d\n" : "ALL PASS\n", fails);
    return fails ? 1 : 0;
}
