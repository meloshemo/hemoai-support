/// Minimal FHIR R4 Observation Bundle export for a hemogram test
class FhirService {
  /// Returns a JSON-encodable Map representing a FHIR Bundle with a single Observation
  static Map<String, dynamic> buildObservationBundle({
    required Map<String, dynamic> user,
    required Map<String, dynamic> test,
  }) {
    final patientId = 'patient-${user['id'] ?? 'unknown'}';
    final observationId = 'obs-${test['id'] ?? DateTime.now().millisecondsSinceEpoch}';
    final effectiveDate = (test['test_date'] ?? test['created_at'] ?? DateTime.now().toIso8601String()).toString();

    Map<String, dynamic> observation = {
      'resourceType': 'Observation',
      'id': observationId,
      'status': 'final',
      'category': [
        {
          'coding': [
            {'system': 'http://terminology.hl7.org/CodeSystem/observation-category', 'code': 'laboratory'}
          ]
        }
      ],
      'code': {
        'text': 'Complete blood count (CBC)'
      },
      'subject': {'reference': 'Patient/$patientId'},
      'effectiveDateTime': effectiveDate,
      'component': _componentsFromTest(test),
    };

    return {
      'resourceType': 'Bundle',
      'type': 'collection',
      'entry': [
        {
          'resource': {
            'resourceType': 'Patient',
            'id': patientId,
            'name': [
              {
                'text': (user['name'] ?? 'Unknown').toString(),
              }
            ],
            'telecom': [
              if (user['phone'] != null) {'system': 'phone', 'value': user['phone']},
              if (user['email'] != null) {'system': 'email', 'value': user['email']},
            ]
          }
        },
        {'resource': observation},
      ]
    };
  }

  static List<Map<String, dynamic>> _componentsFromTest(Map<String, dynamic> t) {
    List<Map<String, dynamic>> out = [];
    void add(String text, Object? value, {String? unit}) {
      if (value == null) return;
      final v = (value is num) ? value : double.tryParse(value.toString());
      if (v == null) return;
      out.add({
        'code': {'text': text},
        'valueQuantity': {
          'value': v,
          if (unit != null) 'unit': unit,
        },
      });
    }

    add('Hemoglobin', t['hemoglobin'], unit: 'g/dL');
    add('Leukocyte', t['leukocyte'], unit: '10^9/L');
    add('Erythrocyte', t['erythrocyte'], unit: '10^12/L');
    add('Platelet', t['platelet'], unit: '10^9/L');
    add('MCH', t['mch'], unit: 'pg');
    add('MCHC', t['mchc'], unit: 'g/dL');
    add('MCV', t['mcv'], unit: 'fL');
    add('CRP', t['crp'], unit: 'mg/L');
    add('Glucose', t['glucose'], unit: 'mg/dL');
    add('ALT', t['alt'], unit: 'U/L');
    add('AST', t['ast'], unit: 'U/L');
    return out;
  }
}


