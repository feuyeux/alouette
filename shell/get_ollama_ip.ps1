#!/usr/bin/env pwsh

# PowerShell equivalent of get_ollama_ip.sh

param()

$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO]  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]    $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "[WARN]  $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Show-Help {
    Write-Host @"
Ollama Service IP Detection (PowerShell)
Usage: ./get_ollama_ip.ps1 [--port <PORT>] [--export] [--json] [--check] [--help]

Options:
  --port <PORT>  Specify Ollama port (default: 11434 or $env:OLLAMA_PORT)
  --export       Output shell export lines
  --json         Output JSON object
  --check        Verify service availability
  --help         Show this help text

Examples:
  ./get_ollama_ip.ps1
  ./get_ollama_ip.ps1 --export
  ./get_ollama_ip.ps1 --port 11435 --check
"@
}

function Get-PrimaryIp {
    try {
        $addresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -ne '0.0.0.0' } |
            Sort-Object -Property SkipAsSource, InterfaceMetric |
            Select-Object -ExpandProperty IPAddress
        if ($addresses) {
            return $addresses[0]
        }
    } catch {
        # Ignore and fall back
    }

    try {
        $socket = New-Object System.Net.Sockets.UdpClient
        $socket.Connect('8.8.8.8', 80)
        $localEndPoint = $socket.Client.LocalEndPoint
        $socket.Close()
        if ($localEndPoint) {
            return $localEndPoint.ToString().Split(':')[0]
        }
    } catch {
        # Ignore and fall through
    }

    return $null
}

function Get-AllLocalIps {
    try {
        return Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -ne '0.0.0.0' } |
            Select-Object -ExpandProperty IPAddress
    } catch {
        return @()
    }
}

function Test-OllamaService {
    param(
        [string]$Ip,
        [int]$Port
    )

    $url = "http://$Ip`:$Port/api/tags"
    try {
        $result = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        return $result.StatusCode -ge 200 -and $result.StatusCode -lt 400
    } catch {
        try {
            $probe = Test-NetConnection -ComputerName $Ip -Port $Port -WarningAction SilentlyContinue
            return $probe.TcpTestSucceeded
        } catch {
            return $false
        }
    }
}

function Show-Details {
    param(
        [string]$ResolvedIp,
        [int]$Port
    )

    Write-Host ""  # spacer
    Write-Info "Primary IP: $ResolvedIp"
    Write-Info "Ollama URL: http://$ResolvedIp`:$Port"

    $allIps = Get-AllLocalIps
    if ($allIps.Count -gt 0) {
        Write-Host ""  # spacer
        Write-Info "Interface scan:"
        foreach ($ip in $allIps) {
            if (Test-OllamaService -Ip $ip -Port $Port) {
                Write-Success "Reachable -> $ip`:$Port"
            } else {
                Write-WarningMessage "No response -> $ip`:$Port"
            }
        }
    }

    Write-Host ""  # spacer
    Write-Info "Sample Flutter config:"
    Write-Host "  final config = LLMConfig(" -ForegroundColor Gray
    Write-Host "    provider: 'ollama'," -ForegroundColor Gray
    Write-Host "    serverUrl: 'http://$ResolvedIp`:$Port'," -ForegroundColor Gray
    Write-Host "    selectedModel: 'llama3.2'," -ForegroundColor Gray
    Write-Host "  );" -ForegroundColor Gray
}

$portValue = if ($env:OLLAMA_PORT) { [int]$env:OLLAMA_PORT } else { 11434 }
$outputFormat = 'text'
$checkService = $false

for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        '--port' {
            if ($i + 1 -ge $args.Length) {
                Write-ErrorMessage "Missing value for --port"
                exit 1
            }
            if (-not [int]::TryParse($args[$i + 1], [ref]$null)) {
                Write-ErrorMessage "Invalid port: $($args[$i + 1])"
                exit 1
            }
            $portValue = [int]$args[$i + 1]
            $i++
        }
        '--export' { $outputFormat = 'export' }
        '--json'   { $outputFormat = 'json' }
        '--check'  { $checkService = $true }
        '--help'   { Show-Help; exit 0 }
        default {
            Write-ErrorMessage "Unknown option: $($args[$i])"
            Show-Help
            exit 1
        }
    }
}

$primaryIp = Get-PrimaryIp
if (-not $primaryIp) {
    Write-ErrorMessage 'Unable to determine local IP address.'
    exit 1
}

if (-not $checkService) {
    switch ($outputFormat) {
        'export' {
            Write-Output "export OLLAMA_HOST=\"http://$primaryIp`:$portValue\""
            Write-Output "export OLLAMA_IP=\"$primaryIp\""
            Write-Output "export OLLAMA_PORT=\"$portValue\""
        }
        'json' {
            $payload = [ordered]@{
                ip  = $primaryIp
                port = $portValue
                url = "http://$primaryIp`:$portValue"
                api_url = "http://$primaryIp`:$portValue/api"
            }
            $payload | ConvertTo-Json -Depth 2
        }
        default {
            Write-Output $primaryIp
        }
    }
    return
}

Write-Info "Checking Ollama service on port $portValue..."
$selectedIp = $primaryIp
if (Test-OllamaService -Ip 'localhost' -Port $portValue) {
    Write-Success "Service reachable at localhost:$portValue"
    $selectedIp = 'localhost'
} elseif (Test-OllamaService -Ip $primaryIp -Port $portValue) {
    Write-Success "Service reachable at $primaryIp`:$portValue"
} else {
    Write-WarningMessage 'Service not reachable on primary interfaces. Scanning all adapters.'
    foreach ($ip in Get-AllLocalIps) {
        if (Test-OllamaService -Ip $ip -Port $portValue) {
            Write-Success "Service reachable at $ip`:$portValue"
            $selectedIp = $ip
            break
        }
    }
    if ($selectedIp -eq $primaryIp) {
        Write-WarningMessage 'Verify that Ollama is running and listening on the requested port.'
        Write-Info "Start command example: set OLLAMA_HOST=0.0.0.0:$portValue && ollama serve"
    }
}

switch ($outputFormat) {
    'export' {
        Write-Output "export OLLAMA_HOST=\"http://$selectedIp`:$portValue\""
        Write-Output "export OLLAMA_IP=\"$selectedIp\""
        Write-Output "export OLLAMA_PORT=\"$portValue\""
    }
    'json' {
        $payload = [ordered]@{
            ip  = $selectedIp
            port = $portValue
            url = "http://$selectedIp`:$portValue"
            api_url = "http://$selectedIp`:$portValue/api"
            reachable = (Test-OllamaService -Ip $selectedIp -Port $portValue)
        }
        $payload | ConvertTo-Json -Depth 2
    }
    default {
        Write-Output $selectedIp
    }
}

Show-Details -ResolvedIp $selectedIp -Port $portValue
