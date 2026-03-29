Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class AudioDevice {
    public string Name;
    public string Id;
    public bool IsDefault;
}

public static class AudioSwitcher {
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    private class MMDeviceEnumerator {}

    [ComImport, Guid("870af99c-171d-4f9e-af0d-e63df40c2bc9")]
    private class PolicyConfigClient {}

    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDeviceEnumerator {
        int EnumAudioEndpoints(int dataFlow, int stateMask, out IMMDeviceCollection devices);
        int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice device);
    }

    [Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDeviceCollection {
        int GetCount(out int count);
        int Item(int index, out IMMDevice device);
    }

    [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDevice {
        int Activate(ref Guid iid, int clsCtx, IntPtr activationParams,
            [MarshalAs(UnmanagedType.IUnknown)] out object iface);
        int OpenPropertyStore(int access, out IPropertyStore properties);
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
        int GetState(out int state);
    }

    [Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore {
        int GetCount(out int count);
        int GetAt(int index, out PROPERTYKEY key);
        int GetValue(ref PROPERTYKEY key, out PROPVARIANT value);
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROPERTYKEY {
        public Guid fmtid;
        public int pid;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct PROPVARIANT {
        [FieldOffset(0)] public short vt;
        [FieldOffset(8)] public IntPtr pwszVal;
    }

    [Guid("f8679f50-850a-41cf-9c72-430f290290c8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPolicyConfig {
        int GetMixFormat(string a, IntPtr b);
        int GetDeviceFormat(string a, bool b, IntPtr c);
        int ResetDeviceFormat(string a);
        int SetDeviceFormat(string a, IntPtr b, IntPtr c);
        int GetProcessingPeriod(string a, bool b, IntPtr c, IntPtr d);
        int SetProcessingPeriod(string a, IntPtr b);
        int GetShareMode(string a, IntPtr b);
        int SetShareMode(string a, IntPtr b);
        int GetPropertyValue(string a, bool b, IntPtr c, IntPtr d);
        int SetPropertyValue(string a, bool b, IntPtr c, IntPtr d);
        int SetDefaultEndpoint(string deviceId, int role);
        int SetEndpointVisibility(string a, int b);
    }

    public static List<AudioDevice> GetCaptureDevices() {
        var list = new List<AudioDevice>();
        var enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumerator());

        IMMDeviceCollection devices;
        enumerator.EnumAudioEndpoints(1, 1, out devices); // eCapture, ACTIVE

        string defaultId = "";
        try {
            IMMDevice defaultDev;
            enumerator.GetDefaultAudioEndpoint(1, 0, out defaultDev); // eCapture, eConsole
            defaultDev.GetId(out defaultId);
        } catch {}

        int count;
        devices.GetCount(out count);

        var nameKey = new PROPERTYKEY();
        nameKey.fmtid = new Guid("a45c254e-df1c-4efd-8020-67d146a850e0");
        nameKey.pid = 14; // PKEY_Device_FriendlyName

        for (int i = 0; i < count; i++) {
            IMMDevice dev;
            devices.Item(i, out dev);
            string id;
            dev.GetId(out id);

            IPropertyStore props;
            dev.OpenPropertyStore(0, out props);
            PROPVARIANT pv;
            props.GetValue(ref nameKey, out pv);
            string name = Marshal.PtrToStringUni(pv.pwszVal);

            list.Add(new AudioDevice { Name = name, Id = id, IsDefault = (id == defaultId) });
        }
        return list;
    }

    public static void SetDefault(string deviceId) {
        var pc = (IPolicyConfig)(new PolicyConfigClient());
        pc.SetDefaultEndpoint(deviceId, 0); // eConsole
        pc.SetDefaultEndpoint(deviceId, 1); // eMultimedia
        pc.SetDefaultEndpoint(deviceId, 2); // eCommunications
    }
}
"@

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$mics = [AudioSwitcher]::GetCaptureDevices()

if ($mics.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("No microphones found.", "Switch Mic", 0, 48)
    exit
}

# --- Build GUI ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Switch Microphone"
$form.Size = New-Object System.Drawing.Size(380, (80 + $mics.Count * 36))
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::FromArgb(212, 212, 212)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.TopMost = $true

$y = 12
$script:selectedId = ""
foreach ($mic in $mics) { if ($mic.IsDefault) { $script:selectedId = $mic.Id } }

foreach ($mic in $mics) {
    $rb = New-Object System.Windows.Forms.RadioButton
    $rb.Text = $mic.Name
    $rb.Tag = $mic.Id
    $rb.Location = New-Object System.Drawing.Point(16, $y)
    $rb.Size = New-Object System.Drawing.Size(330, 28)
    $rb.FlatStyle = "Flat"
    $rb.ForeColor = [System.Drawing.Color]::FromArgb(212, 212, 212)
    if ($mic.IsDefault) {
        $rb.Checked = $true
        $rb.Text += "  (current)"
        $rb.ForeColor = [System.Drawing.Color]::FromArgb(59, 130, 246)
    }
    $rb.Add_CheckedChanged({
        if ($this.Checked) { $script:selectedId = $this.Tag }
    })
    $form.Controls.Add($rb)
    $y += 36
}

$btnOk = New-Object System.Windows.Forms.Button
$btnOk.Text = "Switch"
$btnOk.Size = New-Object System.Drawing.Size(80, 30)
$btnOk.Location = New-Object System.Drawing.Point(150, ($y + 4))
$btnOk.FlatStyle = "Flat"
$btnOk.BackColor = [System.Drawing.Color]::FromArgb(59, 130, 246)
$btnOk.ForeColor = [System.Drawing.Color]::White
$btnOk.DialogResult = "OK"
$form.Controls.Add($btnOk)
$form.AcceptButton = $btnOk

$result = $form.ShowDialog()

if ($result -eq "OK") {
    $currentDefault = ""
    foreach ($mic in $mics) { if ($mic.IsDefault) { $currentDefault = $mic.Id } }
    if ($script:selectedId -ne $currentDefault) {
        [AudioSwitcher]::SetDefault($script:selectedId)
    }
}
