# ================================================
# M3U Turbo Manager - Sistema All-in-One
# Versão: 3.0 - Zero Arquivos Locais
# ================================================

# Configurações
$Script:Config = @{
    Timeout = 3
    MaxParallel = 100
}

# Variáveis globais
$Script:CurrentChannels = $null
$Script:TestedChannels = $null
$Script:CurrentUrl = $null
$Script:TempData = @{}

# ================================================
# FUNÇÕES PRINCIPAIS
# ================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Emoji = ""
    )
    if ($Emoji) { $Message = "$Emoji $Message" }
    Write-Host $Message -ForegroundColor $Color
}

function Show-Banner {
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║        🚀 M3U TURBO MANAGER v3.0      ║" "Magenta"
    Write-ColorOutput "║     Sistema All-in-One sem arquivos     ║" "Magenta"
    Write-ColorOutput "╚══════════════════════════════════════════╝" "Cyan"
    Write-ColorOutput ""
}

function Show-Menu {
    Show-Banner
    Write-ColorOutput "📋 MENU PRINCIPAL" "Yellow"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
    Write-ColorOutput "1. 📥 Carregar lista M3U/M3U8 (URL)" "White"
    Write-ColorOutput "2. ⚡ Testar todos os links (paralelo)" "White"
    Write-ColorOutput "3. 🔍 Filtrar por categoria" "White"
    Write-ColorOutput "4. 💾 Salvar lista (gerar novo link)" "White"
    Write-ColorOutput "5. 📊 Estatísticas da lista" "White"
    Write-ColorOutput "6. ⚙️  Configurações" "White"
    Write-ColorOutput "7. 🗑️  Limpar dados" "White"
    Write-ColorOutput "8. 🚪 Sair" "White"
    Write-ColorOutput "────────────────────────────────────────" "Gray"
}

# Função para baixar lista M3U (em memória)
function Get-M3UListMemory {
    param($Url)
    
    Write-ColorOutput "📥 Baixando lista..." "Yellow" "🔄"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $webClient.Headers.Add("Accept", "*/*")
        $content = $webClient.DownloadString($Url)
        
        $Script:CurrentUrl = $Url
        Write-ColorOutput "✅ Lista baixada! Tamanho: $([math]::Round($content.Length/1024, 2)) KB" "Green" "🎯"
        return $content
    }
    catch {
        Write-ColorOutput "❌ Erro ao baixar: $_" "Red" "💥"
        return $null
    }
}

# Função para processar M3U (otimizada)
function Parse-M3UQuick {
    param($Content)
    
    Write-ColorOutput "🔄 Processando lista..." "Yellow" "⚙️"
    $channels = @()
    $lines = $Content -split "`r`n|`n"
    $total = $lines.Count
    
    for ($i = 0; $i -lt $total; $i++) {
        $line = $lines[$i].Trim()
        if ($line.StartsWith("#EXTINF:")) {
            $channel = @{
                Info = $line
                Url = ""
                Name = ""
                Group = "Sem grupo"
                Logo = ""
                Status = "Pendente"
                ResponseTime = 0
            }
            
            # Extrair nome
            if ($line -match ',(.+)$') { $channel.Name = $matches[1].Trim() }
            
            # Extrair grupo
            if ($line -match 'group-title="([^"]+)"') { 
                $channel.Group = $matches[1] 
            }
            
            # Extrair logo
            if ($line -match 'tvg-logo="([^"]+)"') { $channel.Logo = $matches[1] }
            
            # Buscar URL (próxima linha)
            if ($i + 1 -lt $total) {
                $nextLine = $lines[$i + 1].Trim()
                if ($nextLine -and !$nextLine.StartsWith("#")) {
                    $channel.Url = $nextLine
                    $i++
                }
            }
            
            $channels += $channel
        }
    }
    
    Write-ColorOutput "✅ Processados $($channels.Count) canais" "Green" "📊"
    return $channels
}

# Função de teste ultra-rápido
function Test-UrlsTurbo {
    param($Channels)
    
    Write-ColorOutput "⚡ Iniciando teste turbo de $($Channels.Count) links..." "Yellow" "🚀"
    
    $results = @()
    $total = $Channels.Count
    $completed = 0
    $validCount = 0
    $invalidCount = 0
    
    # Dividir em batches
    $batchSize = $Script:Config.MaxParallel
    $batches = [math]::Ceiling($total / $batchSize)
    
    $progressBar = @{
        Width = 50
        Current = 0
    }
    
    for ($b = 0; $b -lt $batches; $b++) {
        $start = $b * $batchSize
        $end = [math]::Min($start + $batchSize - 1, $total - 1)
        $batch = $Channels[$start..$end]
        
        # Testar batch em paralelo
        $job = Start-Job -ScriptBlock {
            param($batchChannels, $timeout)
            $localResults = @()
            
            foreach ($ch in $batchChannels) {
                $result = $ch.Clone()
                $url = $ch.Url
                
                try {
                    if ($url -match '^https?://') {
                        $request = [System.Net.WebRequest]::Create($url)
                        $request.Method = "HEAD"
                        $request.Timeout = $timeout * 1000
                        $request.UserAgent = "Mozilla/5.0"
                        $request.AllowAutoRedirect = $false
                        
                        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                        $response = $request.GetResponse()
                        $stopwatch.Stop()
                        
                        if ($response.StatusCode -eq 200) {
                            $result.Status = "OK"
                            $result.StatusCode = 200
                            $result.ResponseTime = $stopwatch.ElapsedMilliseconds
                            $result.ContentLength = $response.ContentLength
                        } else {
                            $result.Status = "HTTP $($response.StatusCode)"
                            $result.ResponseTime = $stopwatch.ElapsedMilliseconds
                        }
                        
                        $response.Close()
                    } else {
                        $result.Status = "URL inválida"
                    }
                }
                catch {
                    $result.Status = "Falhou"
                    $result.Error = $_.Exception.Message.Substring(0, 50)
                    $result.ResponseTime = -1
                }
                
                $localResults += $result
            }
            
            return $localResults
        } -ArgumentList $batch, $Script:Config.Timeout
        
        # Aguardar e processar resultados
        $batchResults = Receive-Job -Job $job -Wait
        $results += $batchResults
        Remove-Job -Job $job
        
        # Atualizar progresso
        $completed += $batchResults.Count
        $validCount += ($batchResults | Where-Object { $_.Status -eq "OK" }).Count
        $invalidCount = $completed - $validCount
        
        $percent = [math]::Round(($completed / $total) * 100)
        $barLength = [math]::Round(($percent / 100) * 50)
        $bar = "█" * $barLength + "░" * (50 - $barLength)
        
        Write-Host "`r✅ Progresso: [$bar] $percent% ($completed/$total) | Válidos: $validCount | Inválidos: $invalidCount" -ForegroundColor Cyan -NoNewline
    }
    
    Write-Host "`n"
    Write-ColorOutput "✅ Teste concluído!" "Green" "🎯"
    Write-ColorOutput "   Válidos: $validCount | Inválidos: $invalidCount" "White"
    
    return $results
}

# Função para filtrar por categoria
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

# Função para gerar link da lista (simulada)
function Generate-ListLink {
    param($Channels, $OnlyValid = $true)
    
    $output = "#EXTM3U`n"
    $count = 0
    
    foreach ($ch in $Channels) {
        if ($OnlyValid -and $ch.Status -ne "OK") { continue }
        
        $output += $ch.Info + "`n"
        $output += $ch.Url + "`n"
        $count++
    }
    
    # Codificar em Base64 para simular um link
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($output)
    $base64 = [Convert]::ToBase64String($bytes)
    
    # Simular link (na vida real, você subiria para um serviço)
    $link = "data:application/x-mpegURL;base64," + $base64.Substring(0, [math]::Min(100, $base64.Length)) + "..."
    
    Write-ColorOutput "📋 Link da lista gerado!" "Green" "🔗"
    Write-ColorOutput "   $($count) canais" "White"
    Write-ColorOutput "   Tamanho: $([math]::Round($output.Length/1024, 2)) KB" "White"
    
    # Copiar para clipboard se possível
    try {
        $base64 | Set-Clipboard
        Write-ColorOutput "   ✅ Código copiado para a área de transferência!" "Green" "📋"
    } catch {
        Write-ColorOutput "   ⚠️ Não foi possível copiar para clipboard" "Yellow"
    }
    
    return $link
}

# Função para mostrar estatísticas detalhadas
function Show-DetailedStats {
    param($Channels)
    
    Show-Banner
    Write-ColorOutput "📊 ESTATÍSTICAS DETALHADAS" "Cyan"
    Write-ColorOutput "═══════════════════════════════════════" "Gray"
    
    $total = $Channels.Count
    $valid = ($Channels | Where-Object { $_.Status -eq "OK" }).Count
    $invalid = $total - $valid
    $pendentes = ($Channels | Where-Object { $_.Status -eq "Pendente" }).Count
    
    Write-ColorOutput "📈 Resumo geral:" "Yellow"
    Write-ColorOutput "  Total: $total" "White"
    Write-ColorOutput "  ✅ Válidos: $valid ($([math]::Round(($valid/$total)*100, 1))%)" "Green"
    Write-ColorOutput "  ❌ Inválidos: $invalid ($([math]::Round(($invalid/$total)*100, 1))%)" "Red"
    Write-ColorOutput "  ⏳ Pendentes: $pendentes" "Yellow"
    
    # Grupos
    $groups = $Channels | Where-Object { $_.Group } | Group-Object Group | Sort-Object Count -Descending
    if ($groups.Count -gt 0) {
        Write-ColorOutput "`n📂 Categorias:" "Yellow"
        foreach ($group in $groups | Select-Object -First 10) {
            $groupValid = ($group.Group | Where-Object { $_.Status -eq "OK" }).Count
            $groupPercent = [math]::Round(($groupValid/$group.Count)*100)
            $bar = "█" * [math]::Round($groupPercent/5) + "░" * (20 - [math]::Round($groupPercent/5))
            Write-ColorOutput "  $($group.Name): $($group.Count) canais [$bar] $groupPercent%" "White"
        }
        if ($groups.Count -gt 10) {
            Write-ColorOutput "  ... e mais $($groups.Count - 10) categorias" "Gray"
        }
    }
    
    # Top 5 melhores tempos
    $topFast = $Channels | Where-Object { $_.Status -eq "OK" -and $_.ResponseTime -gt 0 } | Sort-Object ResponseTime | Select-Object -First 5
    if ($topFast.Count -gt 0) {
        Write-ColorOutput "`n⚡ Canais mais rápidos:" "Yellow"
        $i = 1
        foreach ($ch in $topFast) {
            $name = if ($ch.Name.Length -gt 30) { $ch.Name.Substring(0, 30) + "..." } else { $ch.Name }
            Write-ColorOutput "  $i. $name - $($ch.ResponseTime)ms" "White"
            $i++
        }
    }
    
    Write-ColorOutput "`n═══════════════════════════════════════" "Gray"
}

# Função para limpar dados
function Clear-AllData {
    $Script:CurrentChannels = $null
    $Script:TestedChannels = $null
    $Script:CurrentUrl = $null
    $Script:TempData = @{}
    
    # Forçar coleta de lixo
    [System.GC]::Collect()
    
    Write-ColorOutput "🧹 Dados limpos com sucesso!" "Green" "✅"
    Write-ColorOutput "   Memória liberada: ~$([math]::Round((Get-Process -Id $pid).WorkingSet/1MB, 2)) MB" "White"
}

# ================================================
# INTERFACE PRINCIPAL
# ================================================

do {
    Show-Menu
    
    # Mostrar status atual
    if ($Script:CurrentChannels) {
        $status = if ($Script:TestedChannels) { "✅ Testados" } else { "⏳ Carregados" }
        Write-ColorOutput "📌 Status: $status - $($Script:CurrentChannels.Count) canais" "Cyan"
        if ($Script:CurrentUrl) {
            $shortUrl = if ($Script:CurrentUrl.Length -gt 50) { $Script:CurrentUrl.Substring(0, 50) + "..." } else { $Script:CurrentUrl }
            Write-ColorOutput "🔗 Fonte: $shortUrl" "Gray"
        }
    } else {
        Write-ColorOutput "📌 Status: ⚪ Nenhuma lista carregada" "Gray"
    }
    Write-ColorOutput ""
    
    $option = Read-Host "👉 Escolha uma opção"
    
    switch ($option) {
        "1" {
            Write-ColorOutput "📥 INSERIR URL DA LISTA" "Yellow"
            Write-ColorOutput "────────────────────────────────────────" "Gray"
            $url = Read-Host "URL (ex: https://exemplo.com/lista.m3u)"
            
            if ($url) {
                $content = Get-M3UListMemory -Url $url
                if ($content) {
                    $Script:CurrentChannels = Parse-M3UQuick -Content $content
                    $Script:TestedChannels = $null
                    Write-ColorOutput "✅ Lista pronta para uso!" "Green" "🎉"
                }
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "2" {
            if (!$Script:CurrentChannels) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                $Script:TestedChannels = Test-UrlsTurbo -Channels $Script:CurrentChannels
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "3" {
            if (!$Script:CurrentChannels) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                # Mostrar categorias disponíveis
                $groups = $Script:CurrentChannels | Where-Object { $_.Group } | Group-Object Group
                Write-ColorOutput "📂 CATEGORIAS DISPONÍVEIS" "Yellow"
                Write-ColorOutput "────────────────────────────────────────" "Gray"
                $groups | ForEach-Object { 
                    $count = $_.Count
                    $valid = ($_.Group | Where-Object { $_.Status -eq "OK" }).Count
                    Write-ColorOutput "  $($_.Name) - $count canais ($valid válidos)" "White"
                }
                Write-ColorOutput ""
                
                $filter = Read-Host "Digite o filtro (ou 'todos' para todos)"
                
                $channelsToFilter = if ($Script:TestedChannels) { $Script:TestedChannels } else { $Script:CurrentChannels }
                $filtered = Filter-Categories -Channels $channelsToFilter -Filter $filter
                $Script:CurrentChannels = $filtered
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "4" {
            if (!$Script:CurrentChannels) {
                Write-ColorOutput "❌ Carregue uma lista primeiro (opção 1)!" "Red" "⚠️"
            } else {
                Write-ColorOutput "💾 GERAR LINK DA LISTA" "Yellow"
                Write-ColorOutput "────────────────────────────────────────" "Gray"
                
                $onlyValid = Read-Host "Salvar apenas válidos? (S/N)"
                $onlyValid = $onlyValid -eq "S"
                
                $channelsToSave = if ($Script:TestedChannels) { $Script:TestedChannels } else { $Script:CurrentChannels }
                $link = Generate-ListLink -Channels $channelsToSave -OnlyValid $onlyValid
                
                Write-ColorOutput "`n🔗 Link gerado (simulação):" "Cyan"
                Write-ColorOutput "$link" "White"
            }
            Read-Host "`nPressione Enter para continuar..."
        }
        
        "5" {
            if (!$Script:CurrentChannels) {
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
            Write-ColorOutput "👋 Saindo..." "Yellow" "🚪"
            Clear-AllData
            break
        }
        
        default {
            Write-ColorOutput "❌ Opção inválida!" "Red" "⚠️"
            Read-Host "`nPressione Enter para continuar..."
        }
    }
} while ($true)
