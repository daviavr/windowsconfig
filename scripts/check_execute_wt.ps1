$env:TEMP = "$env:LOCALAPPDATA\Temp"
$env:TMP  = "$env:LOCALAPPDATA\Temp"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

# Look for a Windows Terminal process with a main window
$terminal = Get-Process WindowsTerminal -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object -First 1

if ($terminal) {
    # Restore if minimized
    [Win32]::ShowWindowAsync($terminal.MainWindowHandle, 9) | Out-Null  # SW_RESTORE
    [Win32]::SetForegroundWindow($terminal.MainWindowHandle) | Out-Null
}
else {
    Start-Process wt.exe
}