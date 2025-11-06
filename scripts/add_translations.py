#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script to add missing translations (es, fr, de, ar) to localization_service.dart
Finds keys with only tr and en, and adds translations for other languages
"""

import re
import sys

# Translation dictionary for common phrases
TRANSLATIONS = {
    'Water Today': {'es': 'Agua Hoy', 'fr': "Eau Aujourd'hui", 'de': 'Wasser Heute', 'ar': 'الماء اليوم'},
    'Goal': {'es': 'Meta', 'fr': 'Objectif', 'de': 'Ziel', 'ar': 'الهدف'},
    '+1 Glass': {'es': '+1 Vaso', 'fr': '+1 Verre', 'de': '+1 Glas', 'ar': '+1 كوب'},
    'Set Goal': {'es': 'Establecer Meta', 'fr': "Définir l'Objectif", 'de': 'Ziel Setzen', 'ar': 'تعيين الهدف'},
    'glasses': {'es': 'vasos', 'fr': 'verres', 'de': 'Gläser', 'ar': 'أكواب'},
    'Goal updated': {'es': 'Meta actualizada', 'fr': 'Objectif mis à jour', 'de': 'Ziel aktualisiert', 'ar': 'تم تحديث الهدف'},
    'User': {'es': 'Usuario', 'fr': 'Utilisateur', 'de': 'Benutzer', 'ar': 'المستخدم'},
    'Remember me': {'es': 'Recuérdame', 'fr': 'Se souvenir de moi', 'de': 'Angemeldet bleiben', 'ar': 'تذكرني'},
    'Reminders': {'es': 'Recordatorios', 'fr': 'Rappels', 'de': 'Erinnerungen', 'ar': 'التذكيرات'},
    'Upcoming': {'es': 'Próximos', 'fr': 'À Venir', 'de': 'Anstehend', 'ar': 'القادمة'},
    'Overdue': {'es': 'Vencidos', 'fr': 'En Retard', 'de': 'Überfällig', 'ar': 'متأخرة'},
    'Completed': {'es': 'Completados', 'fr': 'Terminés', 'de': 'Abgeschlossen', 'ar': 'مكتملة'},
    'No upcoming reminders': {'es': 'No hay recordatorios próximos', 'fr': 'Aucun rappel à venir', 'de': 'Keine anstehenden Erinnerungen', 'ar': 'لا توجد تذكيرات قادمة'},
    'No overdue reminders': {'es': 'No hay recordatorios vencidos', 'fr': 'Aucun rappel en retard', 'de': 'Keine überfälligen Erinnerungen', 'ar': 'لا توجد تذكيرات متأخرة'},
    'No completed reminders': {'es': 'No hay recordatorios completados', 'fr': 'Aucun rappel terminé', 'de': 'Keine abgeschlossenen Erinnerungen', 'ar': 'لا توجد تذكيرات مكتملة'},
    'Time': {'es': 'Tiempo', 'fr': 'Heure', 'de': 'Zeit', 'ar': 'الوقت'},
    'Description': {'es': 'Descripción', 'fr': 'Description', 'de': 'Beschreibung', 'ar': 'الوصف'},
    'Pause': {'es': 'Pausar', 'fr': 'Pause', 'de': 'Pausieren', 'ar': 'إيقاف مؤقت'},
    'Activate': {'es': 'Activar', 'fr': 'Activer', 'de': 'Aktivieren', 'ar': 'تفعيل'},
    'Reminder deleted': {'es': 'Recordatorio eliminado', 'fr': 'Rappel supprimé', 'de': 'Erinnerung gelöscht', 'ar': 'تم حذف التذكير'},
    'Loading': {'es': 'Cargando', 'fr': 'Chargement', 'de': 'Laden', 'ar': 'جاري التحميل'},
    'Show Password': {'es': 'Mostrar Contraseña', 'fr': 'Afficher le Mot de Passe', 'de': 'Passwort Anzeigen', 'ar': 'إظهار كلمة المرور'},
    'Hide Password': {'es': 'Ocultar Contraseña', 'fr': 'Masquer le Mot de Passe', 'de': 'Passwort Verbergen', 'ar': 'إخفاء كلمة المرور'},
}

def get_translation(en_text, key_name=''):
    """Get translation for English text"""
    if en_text in TRANSLATIONS:
        return TRANSLATIONS[en_text]
    
    # Try to find similar key
    if key_name:
        # Try common patterns
        if 'reminder' in key_name.lower():
            if 'empty' in key_name.lower():
                if 'upcoming' in key_name.lower():
                    return {'es': 'No hay recordatorios próximos', 'fr': 'Aucun rappel à venir', 'de': 'Keine anstehenden Erinnerungen', 'ar': 'لا توجد تذكيرات قادمة'}
        if 'password' in key_name.lower():
            if 'show' in key_name.lower():
                return {'es': 'Mostrar Contraseña', 'fr': 'Afficher le Mot de Passe', 'de': 'Passwort Anzeigen', 'ar': 'إظهار كلمة المرور'}
            if 'hide' in key_name.lower():
                return {'es': 'Ocultar Contraseña', 'fr': 'Masquer le Mot de Passe', 'de': 'Passwort Verbergen', 'ar': 'إخفاء كلمة المرور'}
    
    # Fallback: use English (can be improved with translation API)
    return {'es': en_text, 'fr': en_text, 'de': en_text, 'ar': en_text}

def add_missing_translations(file_path):
    """Add missing translations to localization file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to find keys with only tr and en
    pattern = r"('([^']+)':\s*\{\s*'tr':\s*'[^']*',\s*'en':\s*'([^']*)',\s*)(\},)"
    
    def replace_match(match):
        key_name = match.group(2)
        en_text = match.group(3)
        prefix = match.group(1)
        suffix = match.group(4)
        
        # Check if already has other languages
        if "'es':" in match.group(0) or "'fr':" in match.group(0):
            return match.group(0)
        
        # Get translations
        translations = get_translation(en_text, key_name)
        
        # Build new string
        new_content = prefix + f"\n      'es': '{translations['es']}',\n      'fr': '{translations['fr']}',\n      'de': '{translations['de']}',\n      'ar': '{translations['ar']}',\n" + suffix
        
        return new_content
    
    # Replace all matches
    new_content = re.sub(pattern, replace_match, content)
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"✓ Translations added successfully!")

if __name__ == '__main__':
    file_path = 'lib/services/localization_service.dart'
    try:
        add_missing_translations(file_path)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

