// LegionTemp - TrafficMonitor plugin: Lenovo Legion embedded-controller temperatures.
// Source of the numbers: WMI root\WMI, class LENOVO_OTHER_METHOD, method GetFeatureValue(IDs, value).
// IDs (from LenovoLegionToolkit Enums.cs): CpuCurrentTemperature = 0x05040000, GpuCurrentTemperature = 0x05050000.
// The WMI provider needs administrator rights; TrafficMonitor must run elevated.
#define WIN32_LEAN_AND_MEAN
#define _WIN32_DCOM
#include <windows.h>
#include <comdef.h>
#include <Wbemidl.h>
#include <atomic>
#include <string>
#include "PluginInterface.h"

#pragma comment(lib, "wbemuuid.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "oleaut32.lib")

namespace {

constexpr unsigned CPU_TEMP_ID = 0x05040000;
constexpr unsigned GPU_TEMP_ID = 0x05050000;

std::atomic<int> g_cpu{-1};
std::atomic<int> g_gpu{-1};
std::atomic<bool> g_stop{false};
HANDLE g_thread = nullptr;

// one WMI GetFeatureValue call, -1 on any failure
int ReadFeature(IWbemServices* svc, BSTR path, IWbemClassObject* inDef, unsigned id)
{
    IWbemClassObject* in = nullptr;
    if (FAILED(inDef->SpawnInstance(0, &in)))
        return -1;
    VARIANT v; VariantInit(&v);
    v.vt = VT_I4; v.lVal = static_cast<LONG>(id);
    in->Put(L"IDs", 0, &v, 0);
    IWbemClassObject* out = nullptr;
    HRESULT hr = svc->ExecMethod(path, _bstr_t(L"GetFeatureValue"), 0, nullptr, in, &out, nullptr);
    in->Release();
    int result = -1;
    if (SUCCEEDED(hr) && out)
    {
        VARIANT r; VariantInit(&r);
        if (SUCCEEDED(out->Get(L"value", 0, &r, nullptr, nullptr)) && (r.vt == VT_I4 || r.vt == VT_UI4 || r.vt == VT_I2))
        {
            int t = static_cast<int>(r.lVal);
            if (t > 0 && t < 150) result = t;
        }
        VariantClear(&r);
        out->Release();
    }
    return result;
}

void Drop(IWbemServices*& svc, IWbemClassObject*& inDef, BSTR& path)
{
    if (inDef) { inDef->Release(); inDef = nullptr; }
    if (path) { SysFreeString(path); path = nullptr; }
    if (svc) { svc->Release(); svc = nullptr; }
}

DWORD WINAPI Worker(LPVOID)
{
    // own apartment: the TrafficMonitor UI thread is never touched by COM
    if (FAILED(CoInitializeEx(nullptr, COINIT_MULTITHREADED)))
        return 1;
    CoInitializeSecurity(nullptr, -1, nullptr, nullptr, RPC_C_AUTHN_LEVEL_DEFAULT,
                         RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE, nullptr); // fails harmlessly if already set
    IWbemLocator* loc = nullptr;
    IWbemServices* svc = nullptr;
    IWbemClassObject* inDef = nullptr;
    BSTR path = nullptr;
    while (!g_stop)
    {
        if (!svc)
        {
            if (!loc && FAILED(CoCreateInstance(CLSID_WbemLocator, nullptr, CLSCTX_INPROC_SERVER, IID_IWbemLocator, (void**)&loc)))
                loc = nullptr;
            if (loc && SUCCEEDED(loc->ConnectServer(_bstr_t(L"ROOT\\WMI"), nullptr, nullptr, nullptr, 0, nullptr, nullptr, &svc)))
            {
                CoSetProxyBlanket(svc, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE, nullptr, RPC_C_AUTHN_LEVEL_CALL,
                                  RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE);
                IEnumWbemClassObject* en = nullptr;
                if (SUCCEEDED(svc->ExecQuery(_bstr_t(L"WQL"), _bstr_t(L"SELECT * FROM LENOVO_OTHER_METHOD"),
                                             WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY, nullptr, &en)) && en)
                {
                    IWbemClassObject* obj = nullptr; ULONG n = 0;
                    if (SUCCEEDED(en->Next(5000, 1, &obj, &n)) && n == 1)
                    {
                        VARIANT p; VariantInit(&p);
                        if (SUCCEEDED(obj->Get(L"__PATH", 0, &p, nullptr, nullptr)) && p.vt == VT_BSTR)
                            path = SysAllocString(p.bstrVal);
                        VariantClear(&p);
                        obj->Release();
                    }
                    en->Release();
                }
                IWbemClassObject* cls = nullptr;
                if (path && SUCCEEDED(svc->GetObject(_bstr_t(L"LENOVO_OTHER_METHOD"), 0, nullptr, &cls, nullptr)) && cls)
                {
                    IWbemClassObject* outDef = nullptr;
                    cls->GetMethod(L"GetFeatureValue", 0, &inDef, &outDef);
                    if (outDef) outDef->Release();
                    cls->Release();
                }
                if (!inDef || !path)
                    Drop(svc, inDef, path);
            }
        }
        if (svc)
        {
            g_cpu = ReadFeature(svc, path, inDef, CPU_TEMP_ID);
            g_gpu = ReadFeature(svc, path, inDef, GPU_TEMP_ID);
            if (g_cpu < 0 && g_gpu < 0) // lost the provider: reconnect next round
                Drop(svc, inDef, path);
        }
        else
        {
            g_cpu = -1; g_gpu = -1;
        }
        for (int i = 0; i < 20 && !g_stop; ++i) // poll every 2 s
            Sleep(100);
    }
    Drop(svc, inDef, path);
    if (loc) loc->Release();
    CoUninitialize();
    return 0;
}

void EnsureWorker()
{
    if (!g_thread)
        g_thread = CreateThread(nullptr, 0, Worker, nullptr, 0, nullptr);
}

class TempItem : public IPluginItem
{
public:
    TempItem(const wchar_t* name, const wchar_t* id, const wchar_t* label, std::atomic<int>& src)
        : m_name(name), m_id(id), m_label(label), m_src(src) {}
    const wchar_t* GetItemName() const override { return m_name; }
    const wchar_t* GetItemId() const override { return m_id; }
    const wchar_t* GetItemLableText() const override { return m_label; }
    const wchar_t* GetItemValueText() const override { return m_text.c_str(); }
    const wchar_t* GetItemValueSampleText() const override { return L"100 °C"; }
    void Refresh()
    {
        int t = m_src.load();
        m_text = t > 0 ? std::to_wstring(t) + L" °C" : L"--";
    }
private:
    const wchar_t* m_name; const wchar_t* m_id; const wchar_t* m_label;
    std::atomic<int>& m_src;
    std::wstring m_text{L"--"};
};

class LegionTemp : public ITMPlugin
{
public:
    IPluginItem* GetItem(int index) override
    {
        if (index == 0) return &m_cpu;
        if (index == 1) return &m_gpu;
        return nullptr;
    }
    void DataRequired() override
    {
        EnsureWorker(); // WMI runs on its own thread; here we only publish the cached value
        m_cpu.Refresh();
        m_gpu.Refresh();
    }
    const wchar_t* GetInfo(PluginInfoIndex index) override
    {
        switch (index)
        {
        case TMI_NAME: return L"LegionTemp";
        case TMI_DESCRIPTION: return L"Lenovo Legion embedded-controller CPU and GPU temperature (WMI LENOVO_OTHER_METHOD). Needs TrafficMonitor to run as administrator.";
        case TMI_AUTHOR: return L"Kollect";
        case TMI_COPYRIGHT: return L"MIT";
        case TMI_VERSION: return L"1.0";
        case TMI_URL: return L"https://github.com/dxiiren/TrafficMonitor";
        default: return L"";
        }
    }
private:
    TempItem m_cpu{L"Legion CPU Temperature", L"LegionTemp.cpu", L"TEMP: ", g_cpu};
    TempItem m_gpu{L"Legion GPU Temperature", L"LegionTemp.gpu", L"GPU T: ", g_gpu};
};

LegionTemp g_plugin;

} // namespace

extern "C" __declspec(dllexport) ITMPlugin* TMPluginGetInstance()
{
    return &g_plugin;
}

BOOL APIENTRY DllMain(HMODULE, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_DETACH && !reserved)
    {
        g_stop = true;
        if (g_thread) { WaitForSingleObject(g_thread, 1500); CloseHandle(g_thread); g_thread = nullptr; }
    }
    return TRUE;
}
