# ================================================
# TLS TV Manager v4.7 - CORRIGIDO
# Sistema de Gerenciamento de Listas M3U/M3U8
# Versão: 4.7
# ================================================

# ================================================
# SISTEMA DE VERSÃO E AUTO UPDATE
# ================================================

$Script:Version = "4.7"
$Script:RepoUrl = "https://raw.githubusercontent.com/thyagorve/tlstv/main/tlstv-manager.ps1"
$Script:Running = $true
$Script:CurrentChannels = $null
$Script:TestedChannels = $null
$Script:CurrentUrl = $null

# Configurações
$Script:Config = @{
    Timeout = 2
    MaxParallel = 200
    TestMethod = "HEAD"
    UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}

# ================================================
# FUNÇÃO DE AUTO UPDATE
# ================================================

function Check-ForUpdates {
    Write-ColorOutput "🔍 Verificando atualizações..." "Yellow" "🔄"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", $Script:Config.UserAgent)
        $remoteContent = $webClient.DownloadString($Script:RepoUrl)
        
        if ($remoteContent -match '\$Script:Version\s*=\s*"([^"]+)"') {
            $remoteVersion = $matches[1]
            
            Write-ColorOutput "   Versão local: $($Script:Version)" "White"
            Write-ColorOutput "   Versão remota: $remoteVersion" "White"
            
            if ($remoteVersion -gt $Script:Version) {
                Write-ColorOutput "`n🆕 Nova versão disponível! ($remoteVersion)" "Green" "🎉"
                Write-ColorOutput "────────────────────────────────────────" "Gray"
                
                $update = Read-Host "Deseja atualizar agora? (S/N)"
                if ($update -eq "S") {
                    Write-ColorOutput "⬇️ Baixando atualização..." "Yellow" "📥"
                    
                    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
                    $remoteContent | Out-File -FilePath $tempFile -Encoding UTF8
                    
                    Write-ColorOutput "✅ Download concluído!" "Green" "🎯"
                    Write-ColorOutput "🔄 Reiniciando com nova versão..." "Yellow" "🚀"
                    
                    Clear-AllData
                    & $tempFile
                    exit
                } else {
                    Write-ColorOutput "⏭️ Atualização cancelada." "Yellow"
                }
            } else {
                Write-ColorOutput "✅ Você já está na versão mais recente!" "Green" "🎯"
            }
        } else {
            Write-ColorOutput "⚠️ Não foi possível verificar a versão remota." "Yellow"
        }
    }
    catch {
        Write-ColorOutput "❌ Erro ao verificar atualizações: $_" "Red" "💥"
    }
    
    Read-Host "`nPressione Enter para continuar..."
}

# ================================================
# FUNÇÕES PRINCIPAIS
# ================================================

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White", [string]$Emoji = "")
    if ($Emoji) { $Message = "$Emoji $Message" }
    Write-Host $Message -ForegroundColor $Color
}

function Show-Banner {
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║        ⚡ TLS TV MANAGER v$($Script:Version)           ║" "Magenta"
    Write-ColorOutput "║     Auto Update e Progresso Total       ║" "Magenta"
    Write-ColorOutput "╚══════════════════════════════════════════╝" "Cyan"
    Write-ColorOutput ""
}

function Show-Menu {
    Show-Banner
    Write-ColorOutput "📋 MENU PRINCIPAL" "Yellow"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    Write-ColorOutput "1. 📥 Carregar lista (URL ou arquivo)" "White"
    Write-ColorOutput "2. ⚡ Testar links (MODO TURBO)" "White"
    Write-ColorOutput "3. 🔍 Filtrar por categoria" "White"
    Write-ColorOutput "4. 💾 Salvar lista" "White"
    Write-ColorOutput "5. 📊 Estatísticas" "White"
    Write-ColorOutput "6. ⚙️  Configurações" "White"
    Write-ColorOutput "7. 🗑️  Limpar dados" "White"
    Write-ColorOutput "8. 🔄 Verificar atualizações" "White"
    Write-ColorOutput "9. 🚪 Sair" "White"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
}

# ================================================
# FUNÇÃO DE PROGRESSO CORRIGIDA
# ================================================

function Show-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Label = "Processando",
        [string]$Status = "",
        [string]$Color = "Cyan"
    )
    
    if ($Total -eq 0) { $Total = 1 }
    $percent = [math]::Round(($Current / $Total) * 100)
    if ($percent -gt 100) { $percent = 100 }
    
    $barLength = 40
    $filled = [math]::Round(($percent / 100) * $barLength)
    if ($filled -gt $barLength) { $filled = $barLength }
    
    $bar = "█" * $filled + "░" * ($barLength - $filled)
    
    # Linha 1: Barra
    Write-Host "`r" -NoNewline
    Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
    Write-Host "`r" -NoNewline
    Write-Host "│ $bar │ $percent%  " -ForegroundColor $Color -NoNewline
    
    # Linha 2: Status - CORRIGIDO (concatenação ao invés de interpolação com :)
    Write-Host "`r" -NoNewline
    Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
    Write-Host "`r" -NoNewline
    
    $statusLine = "$Label: $Current/$Total"
    if ($Status -ne "") { $statusLine = "$statusLine | $Status" }
    
    # Centralizar texto
    $padding = 40 - $statusLine.Length
    if ($padding -lt 0) { $padding = 0 }
    $leftPad = [math]::Floor($padding / 2)
    $rightPad = $padding - $leftPad
    
    Write-Host "│" -ForegroundColor Gray -NoNewline
    Write-Host " " * $leftPad -NoNewline
    Write-Host $statusLine -ForegroundColor White -NoNewline
    Write-Host " " * $rightPad -NoNewline
    Write-Host "│" -ForegroundColor Gray -NoNewline
    
    # Linha 3: Fechamento
    Write-Host "`r" -NoNewline
    Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
    
    # Forçar atualização
    [System.Console]::Out.Flush()
}

# ================================================
# FUNÇÃO DE DOWNLOAD COM PROGRESSO
# ================================================

function Get-M3UListMemory {
    param($Source)
    
    $content = $null
    $isLocalFile = Test-Path $Source
    
    if ($isLocalFile) {
        Write-ColorOutput "📂 Carregando arquivo local..." "Yellow" "📁"
        
        $fileInfo = Get-Item $Source
        $fileSize = $fileInfo.Length
        
        Write-ColorOutput "   Tamanho: $([math]::Round($fileSize/1024, 2)) KB" "Gray"
        Write-ColorOutput "   ⏳ Lendo arquivo..." "Yellow"
        
        try {
            $content = Get-Content -Path $Source -Raw -Encoding UTF8
            Write-ColorOutput "✅ Arquivo carregado!" "Green" "🎯"
            $Script:CurrentUrl = $Source
            return $content
        }
        catch {
            Write-ColorOutput "❌ Erro ao ler arquivo: $_" "Red" "💥"
            return $null
        }
    }
    
    Write-ColorOutput "📥 Baixando lista da URL..." "Yellow" "🔄"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    
    try {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", $Script:Config.UserAgent)
            $webClient.Headers.Add("Accept", "*/*")
            $webClient.Headers.Add("Accept-Encoding", "gzip, deflate")
            $webClient.Headers.Add("Connection", "keep-alive")
            
            $webClient.DownloadProgressChanged += {
                param($sender, $e)
                $percent = $e.ProgressPercentage
                $barLength = 40
                $filled = [math]::Round(($percent / 100) * $barLength)
                if ($filled -gt $barLength) { $filled = $barLength }
                $bar = "█" * $filled + "░" * ($barLength - $filled)
                
                $size = if ($e.TotalBytesToReceive -gt 0) {
                    "$([math]::Round($e.BytesReceived/1024, 1))/$([math]::Round($e.TotalBytesToReceive/1024, 1)) KB"
                } else {
                    "$([math]::Round($e.BytesReceived/1024, 1)) KB"
                }
                
                Write-Host "`r" -NoNewline
                Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
                Write-Host "`r" -NoNewline
                Write-Host "│ $bar │ $percent%  " -ForegroundColor Cyan -NoNewline
                Write-Host "`r" -NoNewline
                Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
                Write-Host "`r" -NoNewline
                Write-Host "│ ⬇️ Baixando: $size              │" -ForegroundColor White -NoNewline
                Write-Host "`r" -NoNewline
                Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
                [System.Console]::Out.Flush()
            }
            
            $content = $webClient.DownloadString($Source)
            Write-Host "`n"
            Write-ColorOutput "✅ Download concluído! Tamanho: $([math]::Round($content.Length/1024, 2)) KB" "Green" "🎯"
            $Script:CurrentUrl = $Source
            return $content
        }
        catch {
            Write-ColorOutput "   Tentativa 1 falhou..." "Yellow"
        }
        
        try {
            Write-ColorOutput "   Usando método alternativo..." "Yellow"
            $response = Invoke-WebRequest -Uri $Source -UserAgent $Script:Config.UserAgent -TimeoutSec 30 -UseBasicParsing
            $content = $response.Content
            
            Write-ColorOutput "✅ Download concluído! Tamanho: $([math]::Round($content.Length/1024, 2)) KB" "Green" "🎯"
            $Script:CurrentUrl = $Source
            return $content
        }
        catch {
            Write-ColorOutput "❌ Todas as tentativas falharam!" "Red" "💥"
            Write-ColorOutput "   Último erro: $_" "Red"
            return $null
        }
    }
    catch {
        Write-ColorOutput "❌ Erro ao baixar: $_" "Red" "💥"
        return $null
    }
}

# ================================================
# FUNÇÃO DE PARSING COM PROGRESSO
# ================================================

function Parse-M3UQuick {
    param($Content)
    
    Write-ColorOutput "🔄 Processando lista M3U..." "Yellow" "⚙️"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    
    if ([string]::IsNullOrEmpty($Content)) {
        Write-ColorOutput "❌ Conteúdo vazio!" "Red" "💥"
        return @()
    }
    
    $channels = @()
    $lines = $Content -split "`r`n|`n|`r"
    $lines = $lines | Where-Object { $_.Trim() -ne "" }
    
    $total = $lines.Count
    Write-ColorOutput "   Linhas encontradas: $total" "Gray"
    
    $hasExtM3U = $lines | Where-Object { $_ -match "#EXTM3U" }
    if ($hasExtM3U) {
        Write-ColorOutput "   ✅ Formato M3U detectado" "Green"
    } else {
        Write-ColorOutput "   ⚠️ Pode não ser uma lista M3U padrão" "Yellow"
    }
    
    Write-ColorOutput "`n"
    
    $i = 0
    $count = 0
    $errors = 0
    $lastUpdate = 0
    $startTime = Get-Date
    
    while ($i -lt $total) {
        $line = $lines[$i].Trim()
        
        $currentPercent = [math]::Round(($i / $total) * 100)
        if ($currentPercent -ne $lastUpdate -or $i % 100 -eq 0) {
            $lastUpdate = $currentPercent
            
            $elapsed = (Get-Date) - $startTime
            if ($elapsed.TotalSeconds -gt 0) {
                $speed = [math]::Round($i / $elapsed.TotalSeconds, 1)
            } else {
                $speed = 0
            }
            
            $statusText = "Canais: $count | $($speed) linhas/s"
            Show-Progress -Current $i -Total $total -Label "Analisando" -Status $statusText -Color "Yellow"
        }
        
        if ($line.StartsWith("#EXTINF:")) {
            $channel = @{
                Info = $line
                Url = ""
                Name = "Desconhecido"
                Group = "Sem grupo"
                Logo = ""
                Status = "⏳"
                ResponseTime = 0
                Valid = $false
                TvgId = ""
                TvgName = ""
                TvgLogo = ""
            }
            
            if ($line -match ',([^,]+)$') {
                $channel.Name = $matches[1].Trim()
                if ([string]::IsNullOrEmpty($channel.Name)) {
                    $channel.Name = "Canal $count"
                }
            }
            
            if ($line -match 'group-title="([^"]+)"') { 
                $channel.Group = $matches[1].Trim()
            }
            
            if ($line -match 'tvg-logo="([^"]+)"') { 
                $channel.Logo = $matches[1].Trim()
                $channel.TvgLogo = $matches[1].Trim()
            }
            
            if ($line -match 'tvg-id="([^"]+)"') { 
                $channel.TvgId = $matches[1].Trim()
            }
            
            if ($line -match 'tvg-name="([^"]+)"') { 
                $channel.TvgName = $matches[1].Trim()
                if ($channel.Name -eq "Desconhecido") {
                    $channel.Name = $matches[1].Trim()
                }
            }
            
            $i++
            $urlFound = $false
            while ($i -lt $total -and !$urlFound) {
                $nextLine = $lines[$i].Trim()
                
                if ($nextLine.StartsWith("#")) {
                    $i++
                    continue
                }
                
                if ($nextLine -match '^https?://' -or $nextLine -match '^rtmp://' -or $nextLine -match '^http://') {
                    $channel.Url = $nextLine
                    $urlFound = $true
                    $count++
                } elseif ($nextLine -match '^[a-zA-Z0-9]') {
                    $channel.Url = $nextLine
                    $urlFound = $true
                    $count++
                } else {
                    $i++
                }
            }
            
            if ($channel.Url) {
                $channels += $channel
            } else {
                $errors++
            }
            
        } else {
            $i++
        }
    }
    
    Show-Progress -Current $total -Total $total -Label "✅ Concluído" -Status "$count canais encontrados" -Color "Green"
    Write-Host "`n`n"
    
    Write-ColorOutput "✅ Processados $($channels.Count) canais" "Green" "📊"
    if ($errors -gt 0) {
        Write-ColorOutput "   ⚠️ $errors canais ignorados (sem URL)" "Yellow"
    }
    
    if ($channels.Count -eq 0) {
        Write-ColorOutput "`n⚠️ Nenhum canal encontrado!" "Yellow" "⚠️"
        Write-ColorOutput "   As primeiras linhas do arquivo:" "Gray"
        $firstLines = $lines | Select-Object -First 10
        $idx = 1
        foreach ($line in $firstLines) {
            $display = if ($line.Length -gt 80) { $line.Substring(0, 80) + "..." } else { $line }
            Write-ColorOutput "   $idx. $display" "Gray"
            $idx++
        }
        Write-ColorOutput "`n   💡 Dica: Verifique se a URL está correta" "Yellow"
    }
    
    return $channels
}

# ================================================
# TESTE ULTRA RÁPIDO COM PROGRESSO
# ================================================

function Test-UrlsTurbo {
    param($Channels)
    
    if ($Channels.Count -eq 0) {
        Write-ColorOutput "❌ Nenhum canal para testar!" "Red" "⚠️"
        return $Channels
    }
    
    Write-ColorOutput "⚡ Iniciando teste TURBO de $($Channels.Count) links..." "Yellow" "🚀"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    
    $results = @()
    $total = $Channels.Count
    $completed = 0
    $validCount = 0
    $invalidCount = 0
    $errorCount = 0
    $startTime = Get-Date
    
    $batchSize = $Script:Config.MaxParallel
    $batches = [math]::Ceiling($total / $batchSize)
    
    $jobs = @()
    
    for ($b = 0; $b -lt $batches; $b++) {
        $start = $b * $batchSize
        $end = [math]::Min($start + $batchSize - 1, $total - 1)
        $batch = $Channels[$start..$end]
        
        $job = Start-Job -ScriptBlock {
            param($batchChannels, $timeout)
            $localResults = @()
            
            foreach ($ch in $batchChannels) {
                $result = $ch.Clone()
                $url = $ch.Url
                $result.Valid = $false
                $result.Status = "❌"
                $result.ResponseTime = 9999
                
                try {
                    if ($url -match '^https?://' -or $url -match '^rtmp://') {
                        $request = [System.Net.WebRequest]::Create($url)
                        $request.Method = "HEAD"
                        $request.Timeout = $timeout * 1000
                        $request.UserAgent = "Mozilla/5.0"
                        $request.AllowAutoRedirect = $false
                        $request.KeepAlive = $false
                        
                        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                        $response = $request.GetResponse()
                        $stopwatch.Stop()
                        
                        if ($response.StatusCode -eq 200) {
                            $result.Valid = $true
                            $result.Status = "✅"
                            $result.StatusCode = 200
                            $result.ResponseTime = $stopwatch.ElapsedMilliseconds
                            $result.ContentLength = $response.ContentLength
                        } else {
                            $result.Status = "⚠️"
                            $result.StatusCode = $response.StatusCode
                            $result.ResponseTime = $stopwatch.ElapsedMilliseconds
                        }
                        
                        $response.Close()
                    } else {
                        $result.Status = "🚫"
                        $result.Error = "URL inválida"
                    }
                }
                catch {
                    $result.Status = "❌"
                    $result.Error = $_.Exception.Message.Substring(0, 30)
                    $result.ResponseTime = -1
                }
                
                $localResults += $result
            }
            
            return $localResults
        } -ArgumentList $batch, $Script:Config.Timeout
        
        $jobs += $job
    }
    
    $allResults = @()
    
    while ($jobs.Count -gt 0) {
        $job = $jobs[0]
        if ($job.State -eq "Completed") {
            $batchResults = Receive-Job -Job $job
            $allResults += $batchResults
            $completed += $batchResults.Count
            $validCount += ($batchResults | Where-Object { $_.Valid }).Count
            $invalidCount += ($batchResults | Where-Object { !$_.Valid -and $_.Status -ne "❌" }).Count
            $errorCount += ($batchResults | Where-Object { $_.Status -eq "❌" }).Count
            
            Remove-Job -Job $job
            $jobs = $jobs[1..($jobs.Count-1)]
            
            $elapsed = (Get-Date) - $startTime
            if ($elapsed.TotalSeconds -gt 0) {
                $speed = [math]::Round($completed / $elapsed.TotalSeconds, 1)
            } else {
                $speed = 0
            }
            
            if ($speed -gt 0 -and $completed -lt $total) {
                $remaining = [math]::Round(($total - $completed) / $speed)
                $timeStr = "~${remaining}s"
            } else {
                $timeStr = "calculando..."
            }
            
            $percent = [math]::Round(($completed / $total) * 100)
            $barLength = 40
            $filled = [math]::Round(($percent / 100) * $barLength)
            $bar = "█" * $filled + "░" * ($barLength - $filled)
            
            Write-Host "`r" -NoNewline
            Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
            Write-Host "`r" -NoNewline
            Write-Host "│ $bar │ $percent%  " -ForegroundColor Cyan -NoNewline
            
            Write-Host "`r" -NoNewline
            Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
            Write-Host "`r" -NoNewline
            Write-Host "│ ✅ $validCount  ❌ $invalidCount  ⚠️ $errorCount  │ $completed/$total  ⚡${speed}/s  ⏱$timeStr" -ForegroundColor White -NoNewline
            
            Write-Host "`r" -NoNewline
            Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
            [System.Console]::Out.Flush()
        } else {
            Start-Sleep -Milliseconds 50
        }
    }
    
    Write-Host "`r├────────────────────────────────────────┤" -ForegroundColor Gray
    Write-Host "│ ✅ FINALIZADO!                        │" -ForegroundColor Green
    Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray
    
    Write-Host "`n"
    Write-ColorOutput "📊 RESULTADO FINAL" "Yellow"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    Write-ColorOutput "✅ Válidos: $validCount" "Green"
    Write-ColorOutput "❌ Inválidos: $invalidCount" "Red"
    Write-ColorOutput "⚠️  Erros: $errorCount" "Yellow"
    Write-ColorOutput "⏱  Tempo total: $([math]::Round(((Get-Date) - $startTime).TotalSeconds, 1))s" "Cyan"
    Write-ColorOutput "⚡ Velocidade média: $([math]::Round($total / ((Get-Date) - $startTime).TotalSeconds, 1)) links/s" "Cyan"
    
    return $allResults
}

# ================================================
# DEMAIS FUNÇÕES
# ================================================

function Filter-Categories {
    param($Channels, $Filter)
    
    if ($Filter -eq "todos" -or !$Filter) {
        return $Channels
    }
    
    $filtered = $Channels | Where-Object {
        $_.Group -and $_.Group -match $Filter
    }
    
    if ($filtered.Count -eq 0) {
        Write-ColorOutput "⚠️ Nenhum canal encontrado para '$Filter', mantendo todos" "Yellow" "🔄"
        return $Channels
    }
    
    Write-ColorOutput "✅ Filtrados $($filtered.Count) canais para: $Filter" "Green" "🎯"
    return $filtered
}

function Generate-ListLink {
    param($Channels, $OnlyValid = $true)
    
    Write-ColorOutput "💾 Gerando lista..." "Yellow" "📝"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    
    $output = "#EXTM3U`n"
    $count = 0
    $total = $Channels.Count
    $i = 0
    $startTime = Get-Date
    
    foreach ($ch in $Channels) {
        $i++
        if ($i % 50 -eq 0 -or $i -eq $total) {
            $percent = [math]::Round(($i / $total) * 100)
            $barLength = 40
            $filled = [math]::Round(($percent / 100) * $barLength)
            if ($filled -gt $barLength) { $filled = $barLength }
            $bar = "█" * $filled + "░" * ($barLength - $filled)
            
            $elapsed = (Get-Date) - $startTime
            if ($elapsed.TotalSeconds -gt 0 -and $i -gt 0) {
                $speed = [math]::Round($i / $elapsed.TotalSeconds, 1)
            } else {
                $speed = 0
            }
            
            Write-Host "`r" -NoNewline
            Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
            Write-Host "`r" -NoNewline
            Write-Host "│ $bar │ $percent%  " -ForegroundColor Cyan -NoNewline
            Write-Host "`r" -NoNewline
            Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
            Write-Host "`r" -NoNewline
            Write-Host "│ 📝 Gerando: $i/$total canais | $($speed)/s │" -ForegroundColor White -NoNewline
            Write-Host "`r" -NoNewline
            Write-Host "├────────────────────────────────────────┤" -ForegroundColor Gray -NoNewline
            [System.Console]::Out.Flush()
        }
        
        if ($OnlyValid -and !$ch.Valid) { continue }
        
        $output += $ch.Info + "`n"
        $output += $ch.Url + "`n"
        $count++
    }
    
    Write-Host "`n"
    
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($output)
    $base64 = [Convert]::ToBase64String($bytes)
    
    Write-ColorOutput "📋 Lista gerada com sucesso!" "Green" "🔗"
    Write-ColorOutput "   $($count) canais" "White"
    Write-ColorOutput "   Tamanho: $([math]::Round($output.Length/1024, 2)) KB" "White"
    
    try {
        $base64 | Set-Clipboard
        Write-ColorOutput "   ✅ Código copiado para a área de transferência!" "Green" "📋"
    } catch {
        Write-ColorOutput "   ⚠️ Não foi possível copiar para clipboard" "Yellow"
    }
    
    return $base64
}

function Show-DetailedStats {
    param($Channels)
    
    Show-Banner
    Write-ColorOutput "📊 ESTATÍSTICAS DETALHADAS" "Cyan"
    Write-ColorOutput "═══════════════════════════════════════" "Gray"
    
    $total = $Channels.Count
    $valid = ($Channels | Where-Object { $_.Valid }).Count
    $invalid = $total - $valid
    
    Write-ColorOutput "📈 Resumo geral:" "Yellow"
    Write-ColorOutput "  Total: $total" "White"
    Write-ColorOutput "  ✅ Válidos: $valid ($([math]::Round(($valid/$total)*100, 1))%)" "Green"
    Write-ColorOutput "  ❌ Inválidos: $invalid ($([math]::Round(($invalid/$total)*100, 1))%)" "Red"
    
    $topFast = $Channels | Where-Object { $_.Valid -and $_.ResponseTime -gt 0 } | Sort-Object ResponseTime | Select-Object -First 10
    if ($topFast.Count -gt 0) {
        Write-ColorOutput "`n⚡ TOP 10 MAIS RÁPIDOS:" "Yellow"
        Write-ColorOutput "────────────────────────────────────────" "Gray"
        $i = 1
        foreach ($ch in $topFast) {
            $name = if ($ch.Name.Length -gt 35) { $ch.Name.Substring(0, 35) + "..." } else { $ch.Name }
            $ping = "$($ch.ResponseTime)ms"
            Write-ColorOutput "  $i. $name" "White"
            Write-ColorOutput "     ⚡ $ping │ $($ch.Group)" "Gray"
            $i++
        }
    }
    
    $groups = $Channels | Where-Object { $_.Group } | Group-Object Group | Sort-Object Count -Descending
    if ($groups.Count -gt 0) {
        Write-ColorOutput "`n📂 CATEGORIAS:" "Yellow"
        Write-ColorOutput "────────────────────────────────────────" "Gray"
        foreach ($group in $groups | Select-Object -First 10) {
            $groupValid = ($group.Group | Where-Object { $_.Valid }).Count
            $groupPercent = [math]::Round(($groupValid/$group.Count)*100)
            $bar = "█" * [math]::Round($groupPercent/5) + "░" * (20 - [math]::Round($groupPercent/5))
            Write-ColorOutput "  $($group.Name): $($group.Count) canais" "White"
            Write-ColorOutput "     [$bar] $groupPercent% válidos" "Gray"
        }
        if ($groups.Count -gt 10) {
            Write-ColorOutput "  ... e mais $($groups.Count - 10) categorias" "Gray"
        }
    }
    
    Write-ColorOutput "`n═══════════════════════════════════════" "Gray"
}

function Clear-AllData {
    $Script:CurrentChannels = $null
    $Script:TestedChannels = $null
    $Script:CurrentUrl = $null
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-ColorOutput "🧹 Dados limpos com sucesso!" "Green" "✅"
}

function Exit-Script {
    Write-ColorOutput "👋 Saindo..." "Yellow" "🚪"
    Clear-AllData
    $Script:Running = $false
    [System.Environment]::Exit(0)
}

# ================================================
# INTERFACE PRINCIPAL
# ================================================

while ($Script:Running) {
    Show-Menu
    
    if ($Script:CurrentChannels) {
        $status = if ($Script:TestedChannels) { "✅ Testados" } else { "⏳ Carregados" }
        $validCount = if ($Script:TestedChannels) { ($Script:TestedChannels | Where-Object { $_.Valid }).Count } else { 0 }
        Write-ColorOutput "📌 Status: $status - $($Script:CurrentChannels.Count) canais" "Cyan"
        if ($Script:TestedChannels) {
            Write-ColorOutput "   ✅ Válidos: $validCount | ❌ Inválidos: $($Script:CurrentChannels.Count - $validCount)" "White"
        }
        if ($Script:CurrentUrl) {
            $shortUrl = if ($Script:CurrentUrl.Length -gt 60) { $Script:CurrentUrl.Substring(0, 60) + "..." } else { $Script:CurrentUrl }
            Write-ColorOutput "   📁 Fonte: $shortUrl" "Gray"
        }
    } else {
        Write-ColorOutput "📌 Status: ⚪ Nenhuma lista carregada" "Gray"
    }
    Write-ColorOutput ""
    
    $option = Read-Host "👉 Escolha uma opção"
    
    switch ($option) {
        "1" {
            Write-ColorOutput "📥 CARREGAR LISTA" "Yellow"
            Write-ColorOutput "────────────────────────────────────────" "Gray"
            Write-ColorOutput "   Digite uma URL ou caminho de arquivo local" "Gray"
            Write-ColorOutput "   Exemplo URL: http://auth.urltech.gy/get.php?username=..." "Gray"
            Write-ColorOutput "   Exemplo local: C:\Users\usuario\Desktop\lista.m3u" "Gray"
            Write-ColorOutput "   Exemplo local: .\lista.m3u" "Gray"
            Write-ColorOutput ""
            
            $source = Read-Host "URL ou caminho"
            
            if ($source) {
                $content = Get-M3UListMemory -Source $source
                if ($content) {
                    $Script:CurrentChannels = Parse-M3UQuick -Content $content
                    $Script:TestedChannels = $null
                    if ($Script:CurrentChannels.Count -gt 0) {
                        Write-ColorOutput "`n✅ Lista pronta para uso!" "Green" "🎉"
                    } else {
                        Write-ColorOutput "`n⚠️ Nenhum canal encontrado. Verifique o arquivo/URL." "Yellow" "⚠️"
                    }
                }
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "2" {
            if (!$Script:CurrentChannels -or $Script:CurrentChannels.Count -eq 0) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                $Script:TestedChannels = Test-UrlsTurbo -Channels $Script:CurrentChannels
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "3" {
            if (!$Script:CurrentChannels -or $Script:CurrentChannels.Count -eq 0) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                $groups = $Script:CurrentChannels | Where-Object { $_.Group } | Group-Object Group
                if ($groups.Count -gt 0) {
                    Write-ColorOutput "📂 CATEGORIAS DISPONÍVEIS" "Yellow"
                    Write-ColorOutput "────────────────────────────────────────" "Gray"
                    $groups | ForEach-Object { 
                        $count = $_.Count
                        $valid = ($_.Group | Where-Object { $_.Valid }).Count
                        $status = if ($valid -gt 0) { "✅ $valid válidos" } else { "⏳ não testados" }
                        Write-ColorOutput "  $($_.Name) - $count canais ($status)" "White"
                    }
                    Write-ColorOutput ""
                } else {
                    Write-ColorOutput "⚠️ Nenhuma categoria encontrada" "Yellow"
                }
                
                $filter = Read-Host "Digite o filtro (ou 'todos' para todos)"
                
                $channelsToFilter = if ($Script:TestedChannels) { $Script:TestedChannels } else { $Script:CurrentChannels }
                $filtered = Filter-Categories -Channels $channelsToFilter -Filter $filter
                $Script:CurrentChannels = $filtered
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "4" {
            if (!$Script:CurrentChannels -or $Script:CurrentChannels.Count -eq 0) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                Write-ColorOutput "💾 GERAR LINK DA LISTA" "Yellow"
                Write-ColorOutput "────────────────────────────────────────" "Gray"
                
                $onlyValid = Read-Host "Salvar apenas válidos? (S/N)"
                $onlyValid = $onlyValid -eq "S"
                
                $channelsToSave = if ($Script:TestedChannels) { $Script:TestedChannels } else { $Script:CurrentChannels }
                $link = Generate-ListLink -Channels $channelsToSave -OnlyValid $onlyValid
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "5" {
            if (!$Script:CurrentChannels -or $Script:CurrentChannels.Count -eq 0) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                $channelsToShow = if ($Script:TestedChannels) { $Script:TestedChannels } else { $Script:CurrentChannels }
                Show-DetailedStats -Channels $channelsToShow
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "6" {
            Write-ColorOutput "⚙️ CONFIGURAÇÕES" "Yellow"
            Write-ColorOutput "────────────────────────────────────────" "Gray"
            Write-ColorOutput "Timeout atual: $($Script:Config.Timeout)s" "White"
            Write-ColorOutput "Testes paralelos: $($Script:Config.MaxParallel)" "White"
            Write-ColorOutput ""
            
            $newTimeout = Read-Host "Novo timeout (segundos) [Enter para manter]"
            if ($newTimeout -match '^\d+$') { $Script:Config.Timeout = [int]$newTimeout }
            
            $newParallel = Read-Host "Novo limite de testes paralelos [Enter para manter]"
            if ($newParallel -match '^\d+$') { $Script:Config.MaxParallel = [int]$newParallel }
            
            Write-ColorOutput "✅ Configurações atualizadas!" "Green" "⚡"
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "7" {
            Write-ColorOutput "🗑️ LIMPAR DADOS" "Yellow"
            Write-ColorOutput "────────────────────────────────────────" "Gray"
            $confirm = Read-Host "Tem certeza? (S/N)"
            if ($confirm -eq "S") {
                Clear-AllData
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "8" {
            Check-ForUpdates
        }
        
        "9" {
            Exit-Script
            break
        }
        
        default {
            Write-ColorOutput "❌ Opção inválida!" "Red" "⚠️"
            Read-Host "`nPressione Enter para continuar..."
        }
    }
}

Write-ColorOutput "👋 Programa finalizado!" "Green" "✅"
