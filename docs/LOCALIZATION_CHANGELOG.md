# Localization Changelog

## 2025-10-04
- Completed final i18n sweep for remaining screens and resolved validator findings.
- Added generic/simple UI keys used across multiple screens:
  - good, risk, value
- Guest and onboarding-related additions:
  - continue_as_guest, guest_mode_description, personal_info, age_label, gender, male, female,
    weight_kg, height_cm, calculate_bmi, bmi, continue
- Water tracking and notifications copy:
  - water_goal_progress, water_intake_logged, log_one_glass, keep_going
- Register flow:
  - register_appbar_title, phone_number_label, register, phone_required, register_success (with {phone} param)
- Fixed malformed i18n map structure and flattened accidentally nested keys; removed duplicates.
- Refactored screens to remove Turkish literals and use LocalizationService:
  - diet_program_screen.dart, family_panel_screen.dart, guest_screen.dart,
    notification_screen.dart, personal_info_screen.dart, register_screen.dart
- Validator now passes with zero issues. Analyzer down to non-blocking infos/warnings.

## 2025-10-03
- Added keys for Full Results screen and section titles:
  - full_results_title, no_results_available, view_full_results
- Added comprehensive blood test parameter labels for Full Results screen:
  - CBC parameters: hemoglobin, hematocrit, red_blood_cells, white_blood_cells, platelets, mcv, mch, mchc, rdw, mpv
  - WBC differential: neutrophils, lymphocytes, monocytes, eosinophils, basophils
  - Iron studies: iron, ferritin, transferrin, tibc, transferrin_saturation
  - Liver function: alt, ast, alp, ggt, bilirubin, direct_bilirubin, albumin, total_protein
  - Kidney function: creatinine, urea, uric_acid, gfr
  - Lipid profile: total_cholesterol, ldl_cholesterol, hdl_cholesterol, triglycerides, non_hdl_cholesterol
  - Diabetes markers: glucose, hba1c, fructosamine
  - Thyroid function: tsh, t3, t4, free_t3, free_t4
  - Electrolytes: sodium, potassium, chloride, calcium, magnesium, phosphorus
  - Vitamins: vitamin_b12, vitamin_d, folate, vitamin_a, vitamin_e, vitamin_c
  - Tumor markers: cea, afp, ca125, ca199, ca153, psa
  - Cardiac markers: troponin, ck_mb, ldh, bnp
  - Inflammatory markers: crp, esr, procalcitonin
  - Hormones: insulin, cortisol, testosterone, estradiol, progesterone, prolactin, fsh, lh
- Added Full Results screen UI keys: test_results_summary, import_test_results, share_results, share_feature_coming_soon, test_date, laboratory_name, doctor_name, test_type
  - cbc, wbc_differential, iron_studies, liver_function, kidney_function,
    lipid_profile, diabetes_markers, thyroid_function, electrolytes,
    vitamins, tumor_markers, cardiac_markers, inflammatory_markers, hormones

# Localization Changelog (HemoAI)

This document tracks all localization-related work performed so far.

## Overview
Goal: Remove all hard-coded Turkish UI strings, centralize text in `LocalizationService`, and prepare the codebase for scalable multi-language support.

## Completed Screen/Module Localizations

### 1. Family Panel (`family_panel_screen.dart`)
- Replaced all Turkish literals with localization keys (family_* set).
- Added confirmation dialogs, invitation handling, member management strings.
- Injected `localizationService` where previously unavailable in helper methods.

### 2. Personal Info Screen (`personal_info_screen.dart`)
- Localized labels, validation messages, BMI calculation button, BMI status outputs, navigation buttons.
- Added keys: `go_to_hemogram_entry`, `go_to_main_panel`, and reused existing ones where possible.
- Fixed a malformed map issue in `localization_service.dart` (missing closing brace after `calculate_bmi`).

### 3. Add Reminder Screen (`add_reminder_screen.dart`)
- All form labels, hints, validation, type and repeat selectors, success/error snackbars localized.
- Keys added: `reminder_header_description`, `reminder_title_label`, `reminder_title_hint`, `reminder_title_validate`, `reminder_description_label`, `reminder_description_hint`, `reminder_description_validate`, `reminder_type_label`, `reminder_type_medication`, `reminder_type_test`, `reminder_type_appointment`, `reminder_type_general_reminder`, `reminder_type_general`, `reminder_added_success`, `save_reminder_button`, `repeat_*` keys.

### 4. Reminder List Screen (`reminder_list_screen.dart`)
- Localized type names, tab captions, empty states, overdue badge, date relative labels (today/tomorrow/yesterday), action buttons, tooltips, snackbar messages.
- Keys added: `reminders_title`, `reminder_tab_upcoming`, `reminder_tab_overdue`, `reminder_tab_completed`, `reminder_empty_upcoming`, `reminder_empty_overdue`, `reminder_empty_completed`, `reminder_time_label`, `reminder_description_heading`, `reminder_action_pause`, `reminder_action_activate`, `reminder_deleted`, `reminder_badge_overdue`, `date_today`, `date_tomorrow`, `date_yesterday`.

### 5. Analysis Screen (`analysis_screen.dart`)
- Localized: status chips (Normal/Low/High), normal range template, abnormal values heading, overall assessment messages, generated recommendations, default lifestyle recommendations, detailed advice dialog, report sharing dialog, PDF/Excel export dialogs, email send dialog, dynamic text report, quick export snackbars, risk level labels.
- Keys added include (grouped):
  - Status & Ranges: `status_normal`, `status_low`, `status_high`, `normal_range_template`.
  - Evaluation Messages: `abnormal_values_heading`, `all_values_normal_message`, `overall_assessment_normal`, `overall_assessment_some_abnormal`, `overall_assessment_many_abnormal`.
  - Recommendations: `hemoglobin_low_recommendation`, `iron_low_recommendation`, `wbc_high_recommendation`, `recommendation_default_1/2/3`, `recommendation_follow_up_doctor`.
  - Dialogs/UI: `share_report_button`, `detailed_health_advice_title`, `general_health_tips_heading`, `tip_water_intake`, `tip_exercise`, `tip_balanced_diet`, `tip_sleep`, `tip_stress_management`, `checks_heading`, `check_semiannual_hemogram`, `check_annual_general`, `check_follow_abnormal`.
  - Report Generation: `report_share_dialog_title`, `report_copied`, `copy`, `report_header`, `report_section_values`, `report_section_evaluation`.
  - PDF Export: `pdf_report_dialog_title`, `pdf_report_intro`, `report_content_heading`, `report_content_item_values`, `report_content_item_ai_analysis`, `report_content_item_health_tips`, `report_content_item_risk_assessment`, `report_content_item_date`, `create_pdf_button`, `pdf_generating`, `pdf_generated_success`, `pdf_download_success`, `pdf_export_error_prefix`.
  - Excel Export: `excel_export_title`, `excel_export_intro`, `excel_content_heading`, `excel_content_item_all_params`, `excel_content_item_normal_ranges`, `excel_content_item_status_analysis`, `excel_content_item_test_history`, `excel_content_item_charts`, `create_excel_button`, `excel_generating`, `excel_generated_success`, `excel_download_success`, `excel_export_error_prefix`.
  - Email: `email_send_title`, `email_send_intro`, `email_address_label`, `email_address_hint`, `email_content_heading`, `email_content_item_pdf`, `email_content_item_analysis_summary`, `email_content_item_health_tips`, `email_invalid`, `email_send_button`, `email_sending`, `email_sent_success`.
  - Misc: `patient_placeholder`, `doctor_notes_generated_by_hemoai`, risk levels: `risk_level_low`, `risk_level_medium`, `risk_level_high`.

## Infrastructure & Service Adjustments
- Added missing `error_prefix` reuse for snackbar error composition.
- Ensured desktop database initialization already handled earlier (not part of current batch but critical for localization stability on Windows).
- Removed hard-coded Turkish across processed screens except for medical parameter labels (kept intentionally pending decision—can add keys later).

## Issues Resolved
- Malformed localization map (missing brace) causing build failure during personal info localization phase.
- Undefined `localizationService` references in helper methods inside `family_panel_screen.dart`.
- Duplicate conceptual keys noted (e.g., potential BMI naming variants) flagged for future deduplication.

## Pending / In Progress
- Push notification service localization (titles/bodies + dynamic placeholders).
- `BuildContext` extension planned (`context.loc` or `context.t`) for cleaner usages.
- Localization validator script to detect:
  - Hard-coded Turkish characters (ç ğ ı İ ö ş ü) outside localization service.
  - Missing param placeholder symmetry per key across languages.
  - Unused keys (optional phase 2).
- Key normalization / deduplication pass (careful to avoid breaking existing lookups).

## Recommended Next Steps
1. Localize `push_notification_service.dart` (add keys for recurring notifications, test reminders, motivational messages).
2. Implement `lib/utils/localization_extensions.dart` for concise accessors.
3. Add `tool/validate_localization.dart` script to scan `lib/` excluding `localization_service.dart`.
4. Introduce a CI step (Git hook or script invocation) to fail on newly introduced raw Turkish strings.
5. (Optional) Segment localization map into multiple smaller Dart maps combined at runtime to reduce merge risk.
6. Add unit tests for `getStringWithParams` placeholder replacement.

## Key Count Impact
A large block of new keys added; future refactor could group by domain (reminders_, analysis_, export_, email_, risk_, etc.) in separate partial maps.

## Open Questions / Decisions Needed
- Should medical parameter names (e.g., Hemoglobin, Ferritin) be localized or kept as internationally standard terms?
- Should we migrate stored localized enum values (gender, relation, risk level) to canonical codes for multi-language switching integrity?

---
Last updated: (auto-generated) on 2025-09-26.

## 2025-09-26
- Notifications
  - Replaced hard-coded Turkish titles/subtitles of settings with localization keys using dynamic lookups (`setting_title_*`, `setting_subtitle_*`).
  - Localized loading state, time label, and ensured AppBar tabs use keys.
- Alternative Medicine (`alternative_medicine_screen.dart`)
  - Localized TabBar labels: `herbal_solutions_tab`, `traditional_methods_tab`, `general_info_tab`.
  - Localized herbal card subtitle count using `herbal_solutions_count` with `{count}` placeholder.
  - Localized info rows: `usage_label`, `benefits_label`, `preparation_label`; warning prefix `warning_label`.
  - Localized traditional methods info rows: `benefits_label`, `application_label`, `frequency_label`; warning prefix `warning_label`.
  - Localized General Advice section: `important_reminder_title`, `important_reminder_body`, `basic_rules_title`, `basic_rules_list`, `expert_support_title`, `expert_support_body`.
  - Left dataset content in Turkish (domain content) by design; UI chrome fully localized.
- Utilities
  - Translated Turkish comments in `utils/responsive_helper.dart` to English to satisfy Turkish literal scans.
 - Web build fix
   - Removed `const` from three `AlertDialog` constructors in `analysis_screen.dart` where dynamic localized `Text` widgets are used. This resolves "Not a constant expression" compile errors on Web.

## 2025-10-02
- Notifications screen accessibility
  - Added tooltip text key `mark_read_long` used on notification cards.
- OCR review flow
  - Added keys: `ocr_not_available_web`, `ocr_values_populated`, `ocr_error`, `ocr_processing_error`.
  - Added OCR review UI keys: `ocr_review_title`, `view_source_image`, `ocr_review_instructions`, `ocr_review_description`, `ocr_review_warnings`, `processing`, `confirm_values`, `enter_value`, `value_outside_normal_range`.
  - Validator now passes with no missing OCR keys.
