class DietMenuService {
  // Returns a map of slot -> items for a given riskTag and day (0=Sun..6=Sat)
  Map<String, List<String>> buildMenu({required String riskTag, required int dayIndex}) {
    List<String> breakfast(String tag) {
      switch (tag) {
        case 'hemoglobin':
        case 'iron':
          return [
            'diet_item_oatmeal_molasses',
            'diet_item_boiled_egg',
            'diet_item_orange_or_kiwi',
            'diet_item_walnuts_handful',
          ];
        case 'white_blood_cells':
          return [
            'diet_item_yogurt_kefir',
            'diet_item_mixed_berries',
            'diet_item_chia_tbsp',
          ];
        default:
          return [
            'diet_item_omelette_veggies',
            'diet_item_wholegrain_toast',
            'diet_item_seasonal_fruit',
          ];
      }
    }

    List<String> lunch(String tag) {
      switch (tag) {
        case 'hemoglobin':
        case 'iron':
          return [
            'diet_item_grilled_lean_meat_or_liver',
            'diet_item_green_salad_lemon',
            'diet_item_quinoa_or_bulgur',
          ];
        case 'white_blood_cells':
          return [
            'diet_item_salmon_or_legumes',
            'diet_item_olive_oil_salad',
            'diet_item_brown_rice',
          ];
        default:
          return [
            'diet_item_chicken_or_legumes',
            'diet_item_mixed_salad',
            'diet_item_wholegrain_pasta_or_bulgur',
          ];
      }
    }

    List<String> snack(String tag) {
      switch (tag) {
        case 'hemoglobin':
        case 'iron':
          return [
            'diet_item_dried_apricots_pumpkin_seeds',
            'diet_item_molasses_milk',
          ];
        case 'white_blood_cells':
          return [
            'diet_item_apple_almonds',
            'diet_item_probiotic_yogurt',
          ];
        default:
          return [
            'diet_item_fruit_nuts',
            'diet_item_dark_chocolate_70',
          ];
      }
    }

    List<String> dinner(String tag) {
      switch (tag) {
        case 'hemoglobin':
        case 'iron':
          return [
            'diet_item_legume_stew',
            'diet_item_beet_or_spinach_salad',
            'diet_item_wholegrain_bread_slice',
          ];
        case 'white_blood_cells':
          return [
            'diet_item_turkey_or_tofu_stirfry',
            'diet_item_steamed_veg_broccoli_cauliflower',
            'diet_item_sweet_potato',
          ];
        default:
          return [
            'diet_item_grilled_fish_or_egg_dish',
            'diet_item_seasonal_salad',
            'diet_item_whole_grains_small_portion',
          ];
      }
    }

    List<T> rotate<T>(List<T> base, int shift) {
      if (base.isEmpty) return base;
      final s = shift % base.length;
      return [...base.sublist(s), ...base.sublist(0, s)];
    }

    final shift = dayIndex;
    return {
      'breakfast': rotate(breakfast(riskTag), shift),
      'lunch': rotate(lunch(riskTag), shift),
      'snack': rotate(snack(riskTag), shift),
      'dinner': rotate(dinner(riskTag), shift),
    };
  }
}
