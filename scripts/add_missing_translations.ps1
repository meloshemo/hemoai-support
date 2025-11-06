# Script to add missing translations (es, fr, de, ar) to localization_service.dart
# This script finds keys with only tr and en, and adds translations for other languages

$filePath = "lib/services/localization_service.dart"
$content = Get-Content $filePath -Raw -Encoding UTF8

# Translation mappings for common English words/phrases
$translations = @{
    'Water Today' = @{ es='Agua Hoy'; fr="Eau Aujourd'hui"; de='Wasser Heute'; ar='الماء اليوم' }
    'Goal' = @{ es='Meta'; fr='Objectif'; de='Ziel'; ar='الهدف' }
    'Add Glass' = @{ es='Agregar Vaso'; fr='Ajouter Verre'; de='Glas Hinzufügen'; ar='إضافة كوب' }
    'Set Goal' = @{ es='Establecer Meta'; fr="Définir l'Objectif"; de='Ziel Setzen'; ar='تعيين الهدف' }
    'User' = @{ es='Usuario'; fr='Utilisateur'; de='Benutzer'; ar='المستخدم' }
    'Reminders' = @{ es='Recordatorios'; fr='Rappels'; de='Erinnerungen'; ar='التذكيرات' }
    'Upcoming' = @{ es='Próximos'; fr='À Venir'; de='Anstehend'; ar='القادمة' }
    'Overdue' = @{ es='Vencidos'; fr='En Retard'; de='Überfällig'; ar='متأخرة' }
    'Completed' = @{ es='Completados'; fr='Terminés'; de='Abgeschlossen'; ar='مكتملة' }
    'Loading' = @{ es='Cargando'; fr='Chargement'; de='Laden'; ar='جاري التحميل' }
    'Show Password' = @{ es='Mostrar Contraseña'; fr='Afficher le Mot de Passe'; de='Passwort Anzeigen'; ar='إظهار كلمة المرور' }
    'Hide Password' = @{ es='Ocultar Contraseña'; fr='Masquer le Mot de Passe'; de='Passwort Verbergen'; ar='إخفاء كلمة المرور' }
    'Remember me' = @{ es='Recuérdame'; fr='Se souvenir de moi'; de='Angemeldet bleiben'; ar='تذكرني' }
}

Write-Host "Starting translation addition..." -ForegroundColor Cyan

# Find all keys with only tr and en
$pattern = "(?'key'    '[^']+':\s*\{[^}]*'tr':\s*'[^']*',\s*'en':\s*'[^']*',\s*)(?'close'\},)"
$matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "Found $($matches.Count) keys with missing translations" -ForegroundColor Yellow

$addedCount = 0
$contentLines = $content -split "`n"

foreach ($match in $matches) {
    $keyMatch = $match.Groups['key'].Value
    $enMatch = [regex]::Match($keyMatch, "'en':\s*'([^']*)'")
    
    if ($enMatch.Success) {
        $enText = $enMatch.Groups[1].Value
        Write-Host "Processing: $enText" -ForegroundColor Gray
        
        # Try to get translation from dictionary or use generic approach
        $esText = $translations[$enText].es
        $frText = $translations[$enText].fr
        $deText = $translations[$enText].de
        $arText = $translations[$enText].ar
        
        if (-not $esText) {
            # Generic fallback - use English for now (can be improved with translation API)
            $esText = $enText
            $frText = $enText
            $deText = $enText
            $arText = $enText
        }
        
        # Create new translation block
        $newTranslation = $keyMatch + "`n      'es': '$esText',`n      'fr': '$frText',`n      'de': '$deText',`n      'ar': '$arText',`n" + $match.Groups['close'].Value
        
        # Replace in content
        $content = $content -replace [regex]::Escape($match.Value), $newTranslation
        $addedCount++
    }
}

Write-Host "Added translations for $addedCount keys" -ForegroundColor Green

# Save file
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path $filePath).Path, $content, $utf8NoBom)

Write-Host "File updated successfully!" -ForegroundColor Green

