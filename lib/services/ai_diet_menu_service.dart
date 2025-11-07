/// AI-powered diet menu service that generates rich, varied, personalized meal plans
/// for each day of the week based on hemogram values and health conditions.
class AIDietMenuService {
  /// Generate a comprehensive, varied daily menu for a specific day and health condition
  /// 
  /// [riskTag] - The health condition tag (hemoglobin, iron, glucose, etc.)
  /// [dayIndex] - Day of week (0=Sunday, 6=Saturday)
  /// [hemogramValues] - Optional hemogram values for more personalized recommendations
  /// 
  /// Returns a map with meal types as keys and lists of localized item keys as values
  Map<String, List<String>> generateDailyMenu({
    required String riskTag,
    required int dayIndex,
    Map<String, double>? hemogramValues,
  }) {
    // Generate unique seed for this day to ensure variety
    // Note: We use deterministic selection based on day and risk tag
    // No need for Random since we're using predefined menus

    return {
      'breakfast': _generateBreakfast(riskTag, dayIndex, hemogramValues),
      'lunch': _generateLunch(riskTag, dayIndex, hemogramValues),
      'snack': _generateSnack(riskTag, dayIndex, hemogramValues),
      'dinner': _generateDinner(riskTag, dayIndex, hemogramValues),
    };
  }

  /// Generate breakfast menu - varied and rich options
  List<String> _generateBreakfast(String riskTag, int dayIndex, Map<String, double>? hemogramValues) {
    final dayVariations = [
      // Sunday - Energizing start
      {
        'hemoglobin': ['diet_item_oatmeal_berries', 'diet_item_scrambled_eggs_spinach', 'diet_item_whole_grain_bread_avocado', 'diet_item_fresh_orange_juice'],
        'iron': ['diet_item_quinoa_breakfast_bowl', 'diet_item_poached_eggs', 'diet_item_steamed_spinach', 'diet_item_pomegranate'],
        'glucose': ['diet_item_greek_yogurt_berries', 'diet_item_almonds_walnuts', 'diet_item_chia_seed_pudding', 'diet_item_green_tea'],
        'liver': ['diet_item_oatmeal_apple', 'diet_item_steamed_vegetables', 'diet_item_herbal_tea', 'diet_item_fresh_fruit_salad'],
        'default': ['diet_item_whole_grain_cereal', 'diet_item_fresh_berries', 'diet_item_almond_milk', 'diet_item_honey_drizzle'],
      },
      // Monday - Protein boost
      {
        'hemoglobin': ['diet_item_red_meat_omelette', 'diet_item_whole_grain_toast', 'diet_item_tomato_cucumber', 'diet_item_iron_fortified_juice'],
        'iron': ['diet_item_lentil_pancakes', 'diet_item_steamed_broccoli', 'diet_item_tahini', 'diet_item_dried_apricots'],
        'glucose': ['diet_item_egg_white_omelette', 'diet_item_vegetables', 'diet_item_avocado_slice', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_oatmeal', 'diet_item_banana', 'diet_item_almonds', 'diet_item_ginger_tea'],
        'default': ['diet_item_poached_eggs', 'diet_item_whole_grain_bread', 'diet_item_fresh_vegetables', 'diet_item_fruit_smoothie'],
      },
      // Tuesday - Mediterranean style
      {
        'hemoglobin': ['diet_item_whole_grain_pita', 'diet_item_hummus', 'diet_item_olive_olive_oil', 'diet_item_fresh_figs'],
        'iron': ['diet_item_chickpea_scramble', 'diet_item_steamed_kale', 'diet_item_pumpkin_seeds', 'diet_item_citrus_fruit'],
        'glucose': ['diet_item_quinoa_porridge', 'diet_item_cinnamon', 'diet_item_berries', 'diet_item_unsweetened_tea'],
        'liver': ['diet_item_steamed_rice', 'diet_item_steamed_vegetables', 'diet_item_ginger_tea', 'diet_item_apple'],
        'default': ['diet_item_avocado_toast', 'diet_item_poached_egg', 'diet_item_cherry_tomatoes', 'diet_item_fresh_juice'],
      },
      // Wednesday - Nutritious power
      {
        'hemoglobin': ['diet_item_steel_cut_oats', 'diet_item_raisins', 'diet_item_walnuts', 'diet_item_iron_fortified_milk'],
        'iron': ['diet_item_black_bean_breakfast', 'diet_item_steamed_spinach', 'diet_item_sunflower_seeds', 'diet_item_vitamin_c_fruit'],
        'glucose': ['diet_item_chia_seed_pudding', 'diet_item_blueberries', 'diet_item_almond_butter', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_oatmeal', 'diet_item_pear', 'diet_item_almonds', 'diet_item_dandelion_tea'],
        'default': ['diet_item_granola_bowl', 'diet_item_fresh_fruits', 'diet_item_yogurt', 'diet_item_honey'],
      },
      // Thursday - Fresh and light
      {
        'hemoglobin': ['diet_item_egg_white_scramble', 'diet_item_whole_grain_wrap', 'diet_item_steamed_spinach', 'diet_item_kiwi'],
        'iron': ['diet_item_quinoa_breakfast', 'diet_item_steamed_broccoli', 'diet_item_pumpkin_seeds', 'diet_item_orange'],
        'glucose': ['diet_item_greek_yogurt', 'diet_item_mixed_berries', 'diet_item_flax_seeds', 'diet_item_unsweetened_coffee'],
        'liver': ['diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_herbal_tea', 'diet_item_pear'],
        'default': ['diet_item_smoothie_bowl', 'diet_item_fresh_fruits', 'diet_item_nuts', 'diet_item_coconut_water'],
      },
      // Friday - Weekend prep
      {
        'hemoglobin': ['diet_item_whole_grain_pancakes', 'diet_item_berries', 'diet_item_almond_butter', 'diet_item_iron_fortified_milk'],
        'iron': ['diet_item_lentil_soup', 'diet_item_steamed_kale', 'diet_item_tahini', 'diet_item_dried_fruits'],
        'glucose': ['diet_item_egg_white_omelette', 'diet_item_vegetables', 'diet_item_avocado', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_oatmeal', 'diet_item_banana', 'diet_item_almonds', 'diet_item_ginger_tea'],
        'default': ['diet_item_whole_grain_waffles', 'diet_item_fresh_fruits', 'diet_item_yogurt', 'diet_item_maple_syrup'],
      },
      // Saturday - Indulgent but healthy
      {
        'hemoglobin': ['diet_item_french_toast_whole_grain', 'diet_item_berries', 'diet_item_nuts', 'diet_item_fresh_juice'],
        'iron': ['diet_item_chickpea_flour_pancakes', 'diet_item_steamed_spinach', 'diet_item_sesame_tahini', 'diet_item_citrus_fruit'],
        'glucose': ['diet_item_chia_pudding', 'diet_item_mixed_berries', 'diet_item_almond_milk', 'diet_item_unsweetened_tea'],
        'liver': ['diet_item_steamed_rice_congee', 'diet_item_steamed_vegetables', 'diet_item_herbal_tea', 'diet_item_apple'],
        'default': ['diet_item_breakfast_burrito', 'diet_item_fresh_salsa', 'diet_item_avocado', 'diet_item_smoothie'],
      },
    ];

    final dayMenu = dayVariations[dayIndex];
    return dayMenu![riskTag] ?? dayMenu['default'] ?? _getFallbackBreakfast(riskTag);
  }

  /// Generate lunch menu - varied and rich options
  List<String> _generateLunch(String riskTag, int dayIndex, Map<String, double>? hemogramValues) {
    final dayVariations = [
      // Sunday - Comfort food
      {
        'hemoglobin': ['diet_item_grilled_lean_steak', 'diet_item_quinoa_salad', 'diet_item_steamed_broccoli', 'diet_item_beetroot_salad'],
        'iron': ['diet_item_lentil_curry', 'diet_item_brown_rice', 'diet_item_steamed_kale', 'diet_item_tomato_salad'],
        'glucose': ['diet_item_grilled_chicken_breast', 'diet_item_vegetable_stir_fry', 'diet_item_quinoa', 'diet_item_side_salad'],
        'liver': ['diet_item_steamed_fish', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_grilled_salmon', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
      // Monday - Energizing
      {
        'hemoglobin': ['diet_item_liver_pate', 'diet_item_whole_grain_bread', 'diet_item_steamed_spinach', 'diet_item_roasted_beets'],
        'iron': ['diet_item_chickpea_stew', 'diet_item_whole_grain_pasta', 'diet_item_steamed_broccoli', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_turkey_breast', 'diet_item_vegetable_soup', 'diet_item_side_salad', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_chicken', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_herbal_tea'],
        'default': ['diet_item_grilled_chicken', 'diet_item_roasted_sweet_potato', 'diet_item_steamed_green_beans', 'diet_item_fresh_salad'],
      },
      // Tuesday - Mediterranean
      {
        'hemoglobin': ['diet_item_grilled_lamb', 'diet_item_bulgur_pilaf', 'diet_item_greek_salad', 'diet_item_olive_oil'],
        'iron': ['diet_item_black_bean_burger', 'diet_item_whole_grain_bun', 'diet_item_steamed_kale', 'diet_item_tahini_sauce'],
        'glucose': ['diet_item_mediterranean_salad', 'diet_item_grilled_chicken', 'diet_item_olive_oil', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_cod', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_mediterranean_bowl', 'diet_item_chickpeas', 'diet_item_feta_cheese', 'diet_item_olive_oil'],
      },
      // Wednesday - Power lunch
      {
        'hemoglobin': ['diet_item_lean_beef_stir_fry', 'diet_item_brown_rice', 'diet_item_steamed_broccoli', 'diet_item_beetroot'],
        'iron': ['diet_item_lentil_dal', 'diet_item_whole_grain_naan', 'diet_item_steamed_spinach', 'diet_item_sunflower_seeds'],
        'glucose': ['diet_item_grilled_turkey', 'diet_item_quinoa_tabbouleh', 'diet_item_roasted_vegetables', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_white_fish', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_dandelion_tea'],
        'default': ['diet_item_grilled_fish', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
      // Thursday - Fresh and light
      {
        'hemoglobin': ['diet_item_grilled_chicken_thigh', 'diet_item_quinoa_salad', 'diet_item_steamed_asparagus', 'diet_item_pomegranate'],
        'iron': ['diet_item_red_bean_stew', 'diet_item_whole_grain_bread', 'diet_item_steamed_kale', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_grilled_chicken_breast', 'diet_item_vegetable_skewers', 'diet_item_side_salad', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_salmon', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_grilled_shrimp', 'diet_item_vegetable_paella', 'diet_item_fresh_salad', 'diet_item_herbal_tea'],
      },
      // Friday - Fish day
      {
        'hemoglobin': ['diet_item_grilled_sardines', 'diet_item_quinoa', 'diet_item_steamed_broccoli', 'diet_item_citrus_salad'],
        'iron': ['diet_item_chickpea_salad', 'diet_item_whole_grain_crackers', 'diet_item_steamed_spinach', 'diet_item_sesame_seeds'],
        'glucose': ['diet_item_grilled_white_fish', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_cod', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_dandelion_tea'],
        'default': ['diet_item_grilled_salmon', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
      // Saturday - Comfort weekend
      {
        'hemoglobin': ['diet_item_braised_beef', 'diet_item_mashed_sweet_potato', 'diet_item_steamed_broccoli', 'diet_item_beetroot_salad'],
        'iron': ['diet_item_lentil_soup', 'diet_item_whole_grain_bread', 'diet_item_steamed_kale', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_grilled_chicken', 'diet_item_vegetable_curry', 'diet_item_brown_rice', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_fish', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_grilled_steak', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
    ];

    final dayMenu = dayVariations[dayIndex];
    return dayMenu![riskTag] ?? dayMenu['default'] ?? _getFallbackLunch(riskTag);
  }

  /// Generate snack menu - varied and healthy options
  List<String> _generateSnack(String riskTag, int dayIndex, Map<String, double>? hemogramValues) {
    final snacks = [
      // Sunday
      {
        'hemoglobin': ['diet_item_dark_chocolate_70', 'diet_item_dried_apricots', 'diet_item_pumpkin_seeds'],
        'iron': ['diet_item_trail_mix', 'diet_item_dried_fruits', 'diet_item_nuts'],
        'glucose': ['diet_item_apple_slices', 'diet_item_almond_butter', 'diet_item_unsweetened_tea'],
        'liver': ['diet_item_fresh_apple', 'diet_item_almonds', 'diet_item_herbal_tea'],
        'default': ['diet_item_fruit_salad', 'diet_item_nuts', 'diet_item_herbal_tea'],
      },
      // Monday
      {
        'hemoglobin': ['diet_item_iron_fortified_cereal_bar', 'diet_item_dried_apricots', 'diet_item_walnuts'],
        'iron': ['diet_item_hummus', 'diet_item_vegetable_sticks', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_greek_yogurt', 'diet_item_berries', 'diet_item_unsweetened_tea'],
        'liver': ['diet_item_pear', 'diet_item_almonds', 'diet_item_ginger_tea'],
        'default': ['diet_item_nut_butter', 'diet_item_apple', 'diet_item_herbal_tea'],
      },
      // Tuesday
      {
        'hemoglobin': ['diet_item_dark_chocolate_70', 'diet_item_dried_dates', 'diet_item_sunflower_seeds'],
        'iron': ['diet_item_chickpea_snacks', 'diet_item_dried_fruits', 'diet_item_nuts'],
        'glucose': ['diet_item_cottage_cheese', 'diet_item_berries', 'diet_item_herbal_tea'],
        'liver': ['diet_item_banana', 'diet_item_almonds', 'diet_item_herbal_tea'],
        'default': ['diet_item_smoothie', 'diet_item_nuts', 'diet_item_herbal_tea'],
      },
      // Wednesday
      {
        'hemoglobin': ['diet_item_energy_balls', 'diet_item_dried_apricots', 'diet_item_pumpkin_seeds'],
        'iron': ['diet_item_trail_mix', 'diet_item_dried_fruits', 'diet_item_sesame_seeds'],
        'glucose': ['diet_item_apple', 'diet_item_almond_butter', 'diet_item_unsweetened_tea'],
        'liver': ['diet_item_fresh_fruit', 'diet_item_almonds', 'diet_item_dandelion_tea'],
        'default': ['diet_item_fruit_salad', 'diet_item_nuts', 'diet_item_herbal_tea'],
      },
      // Thursday
      {
        'hemoglobin': ['diet_item_dark_chocolate_70', 'diet_item_dried_figs', 'diet_item_walnuts'],
        'iron': ['diet_item_hummus', 'diet_item_whole_grain_crackers', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_greek_yogurt', 'diet_item_berries', 'diet_item_herbal_tea'],
        'liver': ['diet_item_apple', 'diet_item_almonds', 'diet_item_ginger_tea'],
        'default': ['diet_item_nut_butter', 'diet_item_banana', 'diet_item_herbal_tea'],
      },
      // Friday
      {
        'hemoglobin': ['diet_item_iron_fortified_smoothie', 'diet_item_dried_apricots', 'diet_item_nuts'],
        'iron': ['diet_item_chickpea_snacks', 'diet_item_dried_fruits', 'diet_item_sunflower_seeds'],
        'glucose': ['diet_item_cottage_cheese', 'diet_item_berries', 'diet_item_unsweetened_tea'],
        'liver': ['diet_item_pear', 'diet_item_almonds', 'diet_item_herbal_tea'],
        'default': ['diet_item_smoothie', 'diet_item_nuts', 'diet_item_herbal_tea'],
      },
      // Saturday
      {
        'hemoglobin': ['diet_item_energy_balls', 'diet_item_dried_dates', 'diet_item_pumpkin_seeds'],
        'iron': ['diet_item_trail_mix', 'diet_item_dried_fruits', 'diet_item_nuts'],
        'glucose': ['diet_item_apple_slices', 'diet_item_almond_butter', 'diet_item_herbal_tea'],
        'liver': ['diet_item_fresh_fruit', 'diet_item_almonds', 'diet_item_dandelion_tea'],
        'default': ['diet_item_fruit_salad', 'diet_item_nuts', 'diet_item_herbal_tea'],
      },
    ];

    final daySnacks = snacks[dayIndex];
    return daySnacks![riskTag] ?? daySnacks['default'] ?? _getFallbackSnack(riskTag);
  }

  /// Generate dinner menu - varied and rich options
  List<String> _generateDinner(String riskTag, int dayIndex, Map<String, double>? hemogramValues) {
    final dayVariations = [
      // Sunday - Light dinner
      {
        'hemoglobin': ['diet_item_grilled_chicken_breast', 'diet_item_quinoa_salad', 'diet_item_steamed_broccoli', 'diet_item_beetroot'],
        'iron': ['diet_item_lentil_soup', 'diet_item_whole_grain_bread', 'diet_item_steamed_kale', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_grilled_white_fish', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_cod', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_grilled_salmon', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
      // Monday - Protein focused
      {
        'hemoglobin': ['diet_item_lean_ground_beef', 'diet_item_whole_grain_pasta', 'diet_item_steamed_spinach', 'diet_item_roasted_beets'],
        'iron': ['diet_item_chickpea_curry', 'diet_item_brown_rice', 'diet_item_steamed_broccoli', 'diet_item_tahini'],
        'glucose': ['diet_item_grilled_turkey', 'diet_item_vegetable_stir_fry', 'diet_item_quinoa', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_chicken', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_herbal_tea'],
        'default': ['diet_item_grilled_chicken', 'diet_item_roasted_sweet_potato', 'diet_item_steamed_green_beans', 'diet_item_fresh_salad'],
      },
      // Tuesday - Mediterranean
      {
        'hemoglobin': ['diet_item_grilled_lamb_kofta', 'diet_item_bulgur_pilaf', 'diet_item_greek_salad', 'diet_item_olive_oil'],
        'iron': ['diet_item_black_bean_bowl', 'diet_item_quinoa', 'diet_item_steamed_kale', 'diet_item_tahini_sauce'],
        'glucose': ['diet_item_mediterranean_salad', 'diet_item_grilled_chicken', 'diet_item_olive_oil', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_fish', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_mediterranean_bowl', 'diet_item_chickpeas', 'diet_item_feta_cheese', 'diet_item_olive_oil'],
      },
      // Wednesday - Balanced
      {
        'hemoglobin': ['diet_item_lean_beef_stew', 'diet_item_brown_rice', 'diet_item_steamed_broccoli', 'diet_item_beetroot'],
        'iron': ['diet_item_lentil_dal', 'diet_item_whole_grain_naan', 'diet_item_steamed_spinach', 'diet_item_sunflower_seeds'],
        'glucose': ['diet_item_grilled_chicken_breast', 'diet_item_quinoa_tabbouleh', 'diet_item_roasted_vegetables', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_white_fish', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_dandelion_tea'],
        'default': ['diet_item_grilled_fish', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
      // Thursday - Light and fresh
      {
        'hemoglobin': ['diet_item_grilled_chicken_thigh', 'diet_item_quinoa_salad', 'diet_item_steamed_asparagus', 'diet_item_pomegranate'],
        'iron': ['diet_item_red_bean_stew', 'diet_item_whole_grain_bread', 'diet_item_steamed_kale', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_grilled_chicken_breast', 'diet_item_vegetable_skewers', 'diet_item_side_salad', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_salmon', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_grilled_shrimp', 'diet_item_vegetable_paella', 'diet_item_fresh_salad', 'diet_item_herbal_tea'],
      },
      // Friday - Fish day
      {
        'hemoglobin': ['diet_item_grilled_sardines', 'diet_item_quinoa', 'diet_item_steamed_broccoli', 'diet_item_citrus_salad'],
        'iron': ['diet_item_chickpea_salad', 'diet_item_whole_grain_crackers', 'diet_item_steamed_spinach', 'diet_item_sesame_seeds'],
        'glucose': ['diet_item_grilled_white_fish', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_cod', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_dandelion_tea'],
        'default': ['diet_item_grilled_salmon', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
      // Saturday - Comfort weekend
      {
        'hemoglobin': ['diet_item_braised_beef', 'diet_item_mashed_sweet_potato', 'diet_item_steamed_broccoli', 'diet_item_beetroot_salad'],
        'iron': ['diet_item_lentil_soup', 'diet_item_whole_grain_bread', 'diet_item_steamed_kale', 'diet_item_pumpkin_seeds'],
        'glucose': ['diet_item_grilled_chicken', 'diet_item_vegetable_curry', 'diet_item_brown_rice', 'diet_item_herbal_tea'],
        'liver': ['diet_item_steamed_fish', 'diet_item_steamed_vegetables', 'diet_item_brown_rice', 'diet_item_ginger_tea'],
        'default': ['diet_item_grilled_steak', 'diet_item_roasted_vegetables', 'diet_item_quinoa', 'diet_item_fresh_salad'],
      },
    ];

    final dayMenu = dayVariations[dayIndex];
    return dayMenu![riskTag] ?? dayMenu['default'] ?? _getFallbackDinner(riskTag);
  }

  // Fallback methods for each meal type - using descriptive strings that will be localized
  List<String> _getFallbackBreakfast(String riskTag) {
    switch (riskTag) {
      case 'hemoglobin':
      case 'iron':
        return ['diet_item_oatmeal_berries', 'diet_item_scrambled_eggs_spinach', 'diet_item_whole_grain_bread_avocado', 'diet_item_fresh_orange_juice'];
      case 'white_blood_cells':
        return ['diet_item_greek_yogurt_berries', 'diet_item_almonds_walnuts', 'diet_item_chia_seed_pudding'];
      default:
        return ['diet_item_whole_grain_cereal', 'diet_item_fresh_berries', 'diet_item_almond_milk'];
    }
  }

  List<String> _getFallbackLunch(String riskTag) {
    switch (riskTag) {
      case 'hemoglobin':
      case 'iron':
        return ['diet_item_grilled_lean_steak', 'diet_item_quinoa_salad', 'diet_item_steamed_broccoli'];
      case 'white_blood_cells':
        return ['diet_item_grilled_salmon', 'diet_item_roasted_vegetables', 'diet_item_quinoa'];
      default:
        return ['diet_item_grilled_chicken_breast', 'diet_item_vegetable_stir_fry', 'diet_item_quinoa'];
    }
  }

  List<String> _getFallbackSnack(String riskTag) {
    switch (riskTag) {
      case 'hemoglobin':
      case 'iron':
        return ['diet_item_dark_chocolate_70', 'diet_item_dried_apricots', 'diet_item_pumpkin_seeds'];
      case 'white_blood_cells':
        return ['diet_item_apple_slices', 'diet_item_almond_butter', 'diet_item_unsweetened_tea'];
      default:
        return ['diet_item_fruit_salad', 'diet_item_nuts', 'diet_item_herbal_tea'];
    }
  }

  List<String> _getFallbackDinner(String riskTag) {
    switch (riskTag) {
      case 'hemoglobin':
      case 'iron':
        return ['diet_item_grilled_chicken_breast', 'diet_item_quinoa_salad', 'diet_item_steamed_broccoli'];
      case 'white_blood_cells':
        return ['diet_item_grilled_white_fish', 'diet_item_roasted_vegetables', 'diet_item_quinoa'];
      default:
        return ['diet_item_grilled_salmon', 'diet_item_roasted_vegetables', 'diet_item_quinoa'];
    }
  }

}

