#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script to add missing translations (it, pt, ru) to all localization keys
This script reads the localization_service.dart file and adds Italian, Portuguese, and Russian translations
"""

import re
import sys

# Translation dictionary for common food items and phrases
TRANSLATIONS = {
    # Diet items
    'Apple': {'it': 'Mela', 'pt': 'Maçã', 'ru': 'Яблоко'},
    'Apple Slices': {'it': 'Fette di Mela', 'pt': 'Fatias de Maçã', 'ru': 'Дольки яблока'},
    'Avocado Toast': {'it': 'Toast all\'Avocado', 'pt': 'Torrada com Abacate', 'ru': 'Тост с авокадо'},
    'Banana': {'it': 'Banana', 'pt': 'Banana', 'ru': 'Банан'},
    'Black Bean Breakfast': {'it': 'Colazione con Fagioli Neri', 'pt': 'Café da Manhã com Feijão Preto', 'ru': 'Завтрак с черной фасолью'},
    'Black Bean Burger': {'it': 'Burger di Fagioli Neri', 'pt': 'Hambúrguer de Feijão Preto', 'ru': 'Бургер с черной фасолью'},
    'Braised Beef': {'it': 'Manzo Brasato', 'pt': 'Carne de Vaca Refogada', 'ru': 'Тушеная говядина'},
    'Breakfast Burrito': {'it': 'Burrito della Colazione', 'pt': 'Burrito de Café da Manhã', 'ru': 'Буррито на завтрак'},
    'Chia Pudding': {'it': 'Budino di Chia', 'pt': 'Pudim de Chia', 'ru': 'Пудинг из чиа'},
    'Chia Seed Pudding': {'it': 'Budino ai Semi di Chia', 'pt': 'Pudim de Sementes de Chia', 'ru': 'Пудинг из семян чиа'},
    'Chickpea Flour Pancakes': {'it': 'Frittelle di Farina di Ceci', 'pt': 'Panquecas de Farinha de Grão-de-Bico', 'ru': 'Оладьи из нутовой муки'},
    'Chickpea Salad': {'it': 'Insalata di Ceci', 'pt': 'Salada de Grão-de-Bico', 'ru': 'Салат из нута'},
    'Chickpea Scramble': {'it': 'Uova Stracciate con Ceci', 'pt': 'Ovos Mexidos com Grão-de-Bico', 'ru': 'Яичница с нутом'},
    'Chickpea Snacks': {'it': 'Snack di Ceci', 'pt': 'Lanches de Grão-de-Bico', 'ru': 'Закуски из нута'},
    'Chickpea Stew': {'it': 'Stufato di Ceci', 'pt': 'Ensopado de Grão-de-Bico', 'ru': 'Рагу из нута'},
    'Cottage Cheese': {'it': 'Ricotta', 'pt': 'Queijo Cottage', 'ru': 'Творог'},
    'Dark Chocolate 70%': {'it': 'Cioccolato Fondente 70%', 'pt': 'Chocolate Amargo 70%', 'ru': 'Темный шоколад 70%'},
    'Egg White Omelette': {'it': 'Frittata con Solo Albumi', 'pt': 'Omelete de Clara de Ovo', 'ru': 'Омлет из белков'},
    'Egg White Scramble': {'it': 'Uova Stracciate con Solo Albumi', 'pt': 'Ovos Mexidos com Clara de Ovo', 'ru': 'Яичница из белков'},
    'Energy Balls': {'it': 'Palle Energetiche', 'pt': 'Bolinhas Energéticas', 'ru': 'Энергетические шарики'},
    'French Toast Whole Grain': {'it': 'Pain Perdu Integrale', 'pt': 'Rabanada Integral', 'ru': 'Французский тост из цельного зерна'},
    'Fresh Apple': {'it': 'Mela Fresca', 'pt': 'Maçã Fresca', 'ru': 'Свежее яблоко'},
    'Fresh Fruit': {'it': 'Frutta Fresca', 'pt': 'Fruta Fresca', 'ru': 'Свежие фрукты'},
    'Fruit Salad': {'it': 'Macedonia', 'pt': 'Salada de Frutas', 'ru': 'Фруктовый салат'},
    'Granola Bowl': {'it': 'Ciotola di Granola', 'pt': 'Tigela de Granola', 'ru': 'Чаша с гранолой'},
    'Greek Yogurt': {'it': 'Yogurt Greco', 'pt': 'Iogurte Grego', 'ru': 'Греческий йогурт'},
    'Greek Yogurt with Berries': {'it': 'Yogurt Greco con Bacche', 'pt': 'Iogurte Grego com Frutas Vermelhas', 'ru': 'Греческий йогурт с ягодами'},
    'Grilled Chicken': {'it': 'Pollo alla Griglia', 'pt': 'Frango Grelhado', 'ru': 'Жареный цыпленок'},
    'Grilled Chicken Breast': {'it': 'Petto di Pollo alla Griglia', 'pt': 'Peito de Frango Grelhado', 'ru': 'Жареная куриная грудка'},
    'Grilled Chicken Thigh': {'it': 'Coscia di Pollo alla Griglia', 'pt': 'Coxa de Frango Grelhada', 'ru': 'Жареное куриное бедро'},
    'Grilled Fish': {'it': 'Pesce alla Griglia', 'pt': 'Peixe Grelhado', 'ru': 'Жареная рыба'},
    'Grilled Lamb': {'it': 'Agnello alla Griglia', 'pt': 'Cordeiro Grelhado', 'ru': 'Жареный барашек'},
    'Grilled Lean Steak': {'it': 'Bistecca Magra alla Griglia', 'pt': 'Bife Magro Grelhado', 'ru': 'Жареный постный стейк'},
    'Grilled Salmon': {'it': 'Salmone alla Griglia', 'pt': 'Salmão Grelhado', 'ru': 'Жареный лосось'},
    'Grilled Sardines': {'it': 'Sardine alla Griglia', 'pt': 'Sardinhas Grelhadas', 'ru': 'Жареные сардины'},
    'Grilled Shrimp': {'it': 'Gamberi alla Griglia', 'pt': 'Camarão Grelhado', 'ru': 'Жареные креветки'},
    'Grilled Steak': {'it': 'Bistecca alla Griglia', 'pt': 'Bife Grelhado', 'ru': 'Жареный стейк'},
    'Grilled Turkey': {'it': 'Tacchino alla Griglia', 'pt': 'Peru Grelhado', 'ru': 'Жареная индейка'},
    'Grilled White Fish': {'it': 'Pesce Bianco alla Griglia', 'pt': 'Peixe Branco Grelhado', 'ru': 'Жареная белая рыба'},
    'Hummus': {'it': 'Hummus', 'pt': 'Homus', 'ru': 'Хумус'},
    'Iron Fortified Cereal Bar': {'it': 'Barretta di Cereali Fortificata con Ferro', 'pt': 'Barra de Cereais Fortificada com Ferro', 'ru': 'Зерновой батончик, обогащенный железом'},
    'Iron Fortified Smoothie': {'it': 'Frullato Fortificato con Ferro', 'pt': 'Smoothie Fortificado com Ferro', 'ru': 'Смузи, обогащенный железом'},
    'Lean Beef Stir Fry': {'it': 'Manzo Magro Saltato', 'pt': 'Carne de Vaca Magra Salteada', 'ru': 'Жаркое из постной говядины'},
    'Lentil Curry': {'it': 'Curry di Lenticchie', 'pt': 'Caril de Lentilhas', 'ru': 'Карри из чечевицы'},
    'Lentil Dal': {'it': 'Dal di Lenticchie', 'pt': 'Dal de Lentilhas', 'ru': 'Дал из чечевицы'},
    'Lentil Pancakes': {'it': 'Frittelle di Lenticchie', 'pt': 'Panquecas de Lentilhas', 'ru': 'Оладьи из чечевицы'},
    'Lentil Soup': {'it': 'Zuppa di Lenticchie', 'pt': 'Sopa de Lentilhas', 'ru': 'Суп из чечевицы'},
    'Liver Pate': {'it': 'Paté di Fegato', 'pt': 'Patê de Fígado', 'ru': 'Печеночный паштет'},
    'Mediterranean Bowl': {'it': 'Ciotola Mediterranea', 'pt': 'Tigela Mediterrânea', 'ru': 'Средиземноморская чаша'},
    'Mediterranean Salad': {'it': 'Insalata Mediterranea', 'pt': 'Salada Mediterrânea', 'ru': 'Средиземноморский салат'},
    'Nut Butter': {'it': 'Burro di Noci', 'pt': 'Manteiga de Nozes', 'ru': 'Ореховое масло'},
    'Oatmeal with Apple': {'it': 'Fiocchi d\'Avena con Mela', 'pt': 'Aveia com Maçã', 'ru': 'Овсянка с яблоком'},
    'Oatmeal with Berries': {'it': 'Fiocchi d\'Avena con Bacche', 'pt': 'Aveia com Frutas Vermelhas', 'ru': 'Овсянка с ягодами'},
    'Pear': {'it': 'Pera', 'pt': 'Pêra', 'ru': 'Груша'},
    'Poached Eggs': {'it': 'Uova in Camicia', 'pt': 'Ovos Escalfados', 'ru': 'Яйца-пашот'},
    'Quinoa Breakfast': {'it': 'Colazione con Quinoa', 'pt': 'Café da Manhã com Quinoa', 'ru': 'Завтрак с киноа'},
    'Quinoa Breakfast Bowl': {'it': 'Ciotola di Colazione con Quinoa', 'pt': 'Tigela de Café da Manhã com Quinoa', 'ru': 'Чаша с киноа на завтрак'},
    'Quinoa Porridge': {'it': 'Porridge di Quinoa', 'pt': 'Mingau de Quinoa', 'ru': 'Каша из киноа'},
    'Red Bean Stew': {'it': 'Stufato di Fagioli Rossi', 'pt': 'Ensopado de Feijão Vermelho', 'ru': 'Рагу из красной фасоли'},
    'Red Meat Omelette': {'it': 'Frittata con Carne Rossa', 'pt': 'Omelete com Carne Vermelha', 'ru': 'Омлет с красным мясом'},
    'Smoothie': {'it': 'Frullato', 'pt': 'Smoothie', 'ru': 'Смузи'},
    'Smoothie Bowl': {'it': 'Ciotola di Frullato', 'pt': 'Tigela de Smoothie', 'ru': 'Чаша смузи'},
    'Steamed Chicken': {'it': 'Pollo al Vapore', 'pt': 'Frango ao Vapor', 'ru': 'Курица на пару'},
    'Steamed Cod': {'it': 'Merluzzo al Vapore', 'pt': 'Bacalhau ao Vapor', 'ru': 'Треска на пару'},
    'Steamed Fish': {'it': 'Pesce al Vapore', 'pt': 'Peixe ao Vapor', 'ru': 'Рыба на пару'},
    'Steamed Oatmeal': {'it': 'Fiocchi d\'Avena al Vapore', 'pt': 'Aveia ao Vapor', 'ru': 'Овсянка на пару'},
    'Steamed Rice': {'it': 'Riso al Vapore', 'pt': 'Arroz ao Vapor', 'ru': 'Рис на пару'},
    'Steamed Rice Congee': {'it': 'Congee di Riso al Vapore', 'pt': 'Congee de Arroz ao Vapor', 'ru': 'Рисовая каша на пару'},
    'Steamed Salmon': {'it': 'Salmone al Vapore', 'pt': 'Salmão ao Vapor', 'ru': 'Лосось на пару'},
    'Steamed Vegetables': {'it': 'Verdure al Vapore', 'pt': 'Legumes ao Vapor', 'ru': 'Овощи на пару'},
    'Steamed White Fish': {'it': 'Pesce Bianco al Vapore', 'pt': 'Peixe Branco ao Vapor', 'ru': 'Белая рыба на пару'},
    'Steel Cut Oats': {'it': 'Fiocchi d\'Avena Tagliati all\'Acciaio', 'pt': 'Aveia Cortada em Aço', 'ru': 'Овсянка стального помола'},
    'Trail Mix': {'it': 'Mix di Frutta Secca', 'pt': 'Mistura de Frutas Secas', 'ru': 'Смесь сухофруктов'},
    'Turkey Breast': {'it': 'Petto di Tacchino', 'pt': 'Peito de Peru', 'ru': 'Грудка индейки'},
    'Whole Grain Cereal': {'it': 'Cereali Integrali', 'pt': 'Cereal Integral', 'ru': 'Цельнозерновые хлопья'},
    'Whole Grain Pancakes': {'it': 'Frittelle Integrali', 'pt': 'Panquecas Integrais', 'ru': 'Цельнозерновые оладьи'},
    'Whole Grain Pita': {'it': 'Pita Integrale', 'pt': 'Pão Pita Integral', 'ru': 'Цельнозерновая пита'},
    'Whole Grain Waffles': {'it': 'Waffle Integrali', 'pt': 'Waffles Integrais', 'ru': 'Цельнозерновые вафли'},
}

def get_translation(en_text, key_name=''):
    """Get translation for English text"""
    if en_text in TRANSLATIONS:
        return TRANSLATIONS[en_text]
    
    # Try to generate translation from key name
    if 'diet_item_' in key_name:
        # Remove prefix and convert to readable
        clean = key_name.replace('diet_item_', '').replace('_', ' ')
        # For now, return English as fallback
        return {'it': en_text, 'pt': en_text, 'ru': en_text}
    
    return {'it': en_text, 'pt': en_text, 'ru': en_text}

def add_missing_translations(file_path):
    """Add missing translations to localization file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to find keys that have tr, en, es, fr, de, ar but missing it, pt, ru
    pattern = r"('([^']+)':\s*\{[^}]*'tr':\s*'[^']*',\s*'en':\s*'([^']*)',[^}]*'ar':\s*'[^']*',\s*)(\},)"
    
    def replace_match(match):
        key_name = match.group(2)
        en_text = match.group(3)
        prefix = match.group(1)
        suffix = match.group(4)
        
        # Check if already has it, pt, ru
        if "'it':" in match.group(0) and "'pt':" in match.group(0) and "'ru':" in match.group(0):
            return match.group(0)
        
        # Get translations
        translations = get_translation(en_text, key_name)
        
        # Build new string
        new_content = prefix + f"\n      'it': '{translations['it']}',\n      'pt': '{translations['pt']}',\n      'ru': '{translations['ru']}',\n" + suffix
        
        return new_content
    
    # Replace all matches
    new_content = re.sub(pattern, replace_match, content, flags=re.MULTILINE | re.DOTALL)
    
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
        import traceback
        traceback.print_exc()
        sys.exit(1)

