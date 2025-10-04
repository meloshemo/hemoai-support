
/// Comprehensive blood test model supporting all major test categories
class BloodTestResult {
  final int? id;
  final int userId;
  final String testDate;
  final String? laboratoryName;
  final String? doctorName;
  final String? testType;
  final String? importSource; // 'manual', 'e-devlet', 'qr-scan', 'file-import'
  
  // Hemogram (Complete Blood Count)
  final double? hemoglobin;
  final double? hematocrit;
  final double? redBloodCells;
  final double? whiteBloodCells;
  final double? platelets;
  final double? mcv; // Mean Corpuscular Volume
  final double? mch; // Mean Corpuscular Hemoglobin
  final double? mchc; // Mean Corpuscular Hemoglobin Concentration
  final double? rdw; // Red Cell Distribution Width
  final double? mpv; // Mean Platelet Volume
  
  // White Blood Cell Differential
  final double? neutrophils;
  final double? lymphocytes;
  final double? monocytes;
  final double? eosinophils;
  final double? basophils;
  
  // Iron Studies
  final double? iron;
  final double? ferritin;
  final double? transferrin;
  final double? tibc; // Total Iron Binding Capacity
  final double? transferrinSaturation;
  
  // Liver Function Tests
  final double? alt; // Alanine Aminotransferase
  final double? ast; // Aspartate Aminotransferase
  final double? alp; // Alkaline Phosphatase
  final double? ggt; // Gamma-Glutamyl Transferase
  final double? bilirubin;
  final double? directBilirubin;
  final double? albumin;
  final double? totalProtein;
  
  // Kidney Function Tests
  final double? creatinine;
  final double? urea;
  final double? uricAcid;
  final double? gfr; // Glomerular Filtration Rate
  
  // Lipid Profile
  final double? totalCholesterol;
  final double? ldlCholesterol;
  final double? hdlCholesterol;
  final double? triglycerides;
  final double? nonHdlCholesterol;
  
  // Diabetes Markers
  final double? glucose;
  final double? hba1c; // Hemoglobin A1c
  final double? fructosamine;
  
  // Thyroid Function Tests
  final double? tsh; // Thyroid Stimulating Hormone
  final double? t3; // Triiodothyronine
  final double? t4; // Thyroxine
  final double? freeT3;
  final double? freeT4;
  
  // Electrolytes
  final double? sodium;
  final double? potassium;
  final double? chloride;
  final double? calcium;
  final double? magnesium;
  final double? phosphorus;
  
  // Vitamins
  final double? vitaminB12;
  final double? vitaminD;
  final double? folate;
  final double? vitaminA;
  final double? vitaminE;
  final double? vitaminC;
  
  // Tumor Markers (Cancer Screening)
  final double? cea; // Carcinoembryonic Antigen
  final double? afp; // Alpha-Fetoprotein
  final double? ca125;
  final double? ca199;
  final double? ca153;
  final double? psa; // Prostate Specific Antigen
  
  // Cardiac Markers
  final double? troponin;
  final double? ckMb; // Creatine Kinase-MB
  final double? ldh; // Lactate Dehydrogenase
  final double? bnp; // Brain Natriuretic Peptide
  
  // Inflammatory Markers
  final double? crp; // C-Reactive Protein
  final double? esr; // Erythrocyte Sedimentation Rate
  final double? procalcitonin;
  
  // Hormones
  final double? insulin;
  final double? cortisol;
  final double? testosterone;
  final double? estradiol;
  final double? progesterone;
  final double? prolactin;
  final double? fsh; // Follicle Stimulating Hormone
  final double? lh; // Luteinizing Hormone
  
  final String? notes;
  final String? riskLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BloodTestResult({
    this.id,
    required this.userId,
    required this.testDate,
    this.laboratoryName,
    this.doctorName,
    this.testType,
    this.importSource,
    
    // Hemogram
    this.hemoglobin,
    this.hematocrit,
    this.redBloodCells,
    this.whiteBloodCells,
    this.platelets,
    this.mcv,
    this.mch,
    this.mchc,
    this.rdw,
    this.mpv,
    
    // WBC Differential
    this.neutrophils,
    this.lymphocytes,
    this.monocytes,
    this.eosinophils,
    this.basophils,
    
    // Iron Studies
    this.iron,
    this.ferritin,
    this.transferrin,
    this.tibc,
    this.transferrinSaturation,
    
    // Liver Function
    this.alt,
    this.ast,
    this.alp,
    this.ggt,
    this.bilirubin,
    this.directBilirubin,
    this.albumin,
    this.totalProtein,
    
    // Kidney Function
    this.creatinine,
    this.urea,
    this.uricAcid,
    this.gfr,
    
    // Lipid Profile
    this.totalCholesterol,
    this.ldlCholesterol,
    this.hdlCholesterol,
    this.triglycerides,
    this.nonHdlCholesterol,
    
    // Diabetes
    this.glucose,
    this.hba1c,
    this.fructosamine,
    
    // Thyroid
    this.tsh,
    this.t3,
    this.t4,
    this.freeT3,
    this.freeT4,
    
    // Electrolytes
    this.sodium,
    this.potassium,
    this.chloride,
    this.calcium,
    this.magnesium,
    this.phosphorus,
    
    // Vitamins
    this.vitaminB12,
    this.vitaminD,
    this.folate,
    this.vitaminA,
    this.vitaminE,
    this.vitaminC,
    
    // Tumor Markers
    this.cea,
    this.afp,
    this.ca125,
    this.ca199,
    this.ca153,
    this.psa,
    
    // Cardiac
    this.troponin,
    this.ckMb,
    this.ldh,
    this.bnp,
    
    // Inflammatory
    this.crp,
    this.esr,
    this.procalcitonin,
    
    // Hormones
    this.insulin,
    this.cortisol,
    this.testosterone,
    this.estradiol,
    this.progesterone,
    this.prolactin,
    this.fsh,
    this.lh,
    
    this.notes,
    this.riskLevel,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'test_date': testDate,
      'laboratory_name': laboratoryName,
      'doctor_name': doctorName,
      'test_type': testType,
      'import_source': importSource,
      
      // Hemogram
      'hemoglobin': hemoglobin,
      'hematocrit': hematocrit,
      'red_blood_cells': redBloodCells,
      'white_blood_cells': whiteBloodCells,
      'platelets': platelets,
      'mcv': mcv,
      'mch': mch,
      'mchc': mchc,
      'rdw': rdw,
      'mpv': mpv,
      
      // WBC Differential
      'neutrophils': neutrophils,
      'lymphocytes': lymphocytes,
      'monocytes': monocytes,
      'eosinophils': eosinophils,
      'basophils': basophils,
      
      // Iron Studies
      'iron': iron,
      'ferritin': ferritin,
      'transferrin': transferrin,
      'tibc': tibc,
      'transferrin_saturation': transferrinSaturation,
      
      // Liver Function
      'alt': alt,
      'ast': ast,
      'alp': alp,
      'ggt': ggt,
      'bilirubin': bilirubin,
      'direct_bilirubin': directBilirubin,
      'albumin': albumin,
      'total_protein': totalProtein,
      
      // Kidney Function
      'creatinine': creatinine,
      'urea': urea,
      'uric_acid': uricAcid,
      'gfr': gfr,
      
      // Lipid Profile
      'total_cholesterol': totalCholesterol,
      'ldl_cholesterol': ldlCholesterol,
      'hdl_cholesterol': hdlCholesterol,
      'triglycerides': triglycerides,
      'non_hdl_cholesterol': nonHdlCholesterol,
      
      // Diabetes
      'glucose': glucose,
      'hba1c': hba1c,
      'fructosamine': fructosamine,
      
      // Thyroid
      'tsh': tsh,
      't3': t3,
      't4': t4,
      'free_t3': freeT3,
      'free_t4': freeT4,
      
      // Electrolytes
      'sodium': sodium,
      'potassium': potassium,
      'chloride': chloride,
      'calcium': calcium,
      'magnesium': magnesium,
      'phosphorus': phosphorus,
      
      // Vitamins
      'vitamin_b12': vitaminB12,
      'vitamin_d': vitaminD,
      'folate': folate,
      'vitamin_a': vitaminA,
      'vitamin_e': vitaminE,
      'vitamin_c': vitaminC,
      
      // Tumor Markers
      'cea': cea,
      'afp': afp,
      'ca125': ca125,
      'ca199': ca199,
      'ca153': ca153,
      'psa': psa,
      
      // Cardiac
      'troponin': troponin,
      'ck_mb': ckMb,
      'ldh': ldh,
      'bnp': bnp,
      
      // Inflammatory
      'crp': crp,
      'esr': esr,
      'procalcitonin': procalcitonin,
      
      // Hormones
      'insulin': insulin,
      'cortisol': cortisol,
      'testosterone': testosterone,
      'estradiol': estradiol,
      'progesterone': progesterone,
      'prolactin': prolactin,
      'fsh': fsh,
      'lh': lh,
      
      'notes': notes,
      'risk_level': riskLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BloodTestResult.fromMap(Map<String, dynamic> map) {
    return BloodTestResult(
      id: map['id'],
      userId: map['user_id'],
      testDate: map['test_date'],
      laboratoryName: map['laboratory_name'],
      doctorName: map['doctor_name'],
      testType: map['test_type'],
      importSource: map['import_source'],
      
      // Hemogram
      hemoglobin: map['hemoglobin']?.toDouble(),
      hematocrit: map['hematocrit']?.toDouble(),
      redBloodCells: map['red_blood_cells']?.toDouble(),
      whiteBloodCells: map['white_blood_cells']?.toDouble(),
      platelets: map['platelets']?.toDouble(),
      mcv: map['mcv']?.toDouble(),
      mch: map['mch']?.toDouble(),
      mchc: map['mchc']?.toDouble(),
      rdw: map['rdw']?.toDouble(),
      mpv: map['mpv']?.toDouble(),
      
      // WBC Differential
      neutrophils: map['neutrophils']?.toDouble(),
      lymphocytes: map['lymphocytes']?.toDouble(),
      monocytes: map['monocytes']?.toDouble(),
      eosinophils: map['eosinophils']?.toDouble(),
      basophils: map['basophils']?.toDouble(),
      
      // Iron Studies
      iron: map['iron']?.toDouble(),
      ferritin: map['ferritin']?.toDouble(),
      transferrin: map['transferrin']?.toDouble(),
      tibc: map['tibc']?.toDouble(),
      transferrinSaturation: map['transferrin_saturation']?.toDouble(),
      
      // Liver Function
      alt: map['alt']?.toDouble(),
      ast: map['ast']?.toDouble(),
      alp: map['alp']?.toDouble(),
      ggt: map['ggt']?.toDouble(),
      bilirubin: map['bilirubin']?.toDouble(),
      directBilirubin: map['direct_bilirubin']?.toDouble(),
      albumin: map['albumin']?.toDouble(),
      totalProtein: map['total_protein']?.toDouble(),
      
      // Kidney Function
      creatinine: map['creatinine']?.toDouble(),
      urea: map['urea']?.toDouble(),
      uricAcid: map['uric_acid']?.toDouble(),
      gfr: map['gfr']?.toDouble(),
      
      // Lipid Profile
      totalCholesterol: map['total_cholesterol']?.toDouble(),
      ldlCholesterol: map['ldl_cholesterol']?.toDouble(),
      hdlCholesterol: map['hdl_cholesterol']?.toDouble(),
      triglycerides: map['triglycerides']?.toDouble(),
      nonHdlCholesterol: map['non_hdl_cholesterol']?.toDouble(),
      
      // Diabetes
      glucose: map['glucose']?.toDouble(),
      hba1c: map['hba1c']?.toDouble(),
      fructosamine: map['fructosamine']?.toDouble(),
      
      // Thyroid
      tsh: map['tsh']?.toDouble(),
      t3: map['t3']?.toDouble(),
      t4: map['t4']?.toDouble(),
      freeT3: map['free_t3']?.toDouble(),
      freeT4: map['free_t4']?.toDouble(),
      
      // Electrolytes
      sodium: map['sodium']?.toDouble(),
      potassium: map['potassium']?.toDouble(),
      chloride: map['chloride']?.toDouble(),
      calcium: map['calcium']?.toDouble(),
      magnesium: map['magnesium']?.toDouble(),
      phosphorus: map['phosphorus']?.toDouble(),
      
      // Vitamins
      vitaminB12: map['vitamin_b12']?.toDouble(),
      vitaminD: map['vitamin_d']?.toDouble(),
      folate: map['folate']?.toDouble(),
      vitaminA: map['vitamin_a']?.toDouble(),
      vitaminE: map['vitamin_e']?.toDouble(),
      vitaminC: map['vitamin_c']?.toDouble(),
      
      // Tumor Markers
      cea: map['cea']?.toDouble(),
      afp: map['afp']?.toDouble(),
      ca125: map['ca125']?.toDouble(),
      ca199: map['ca199']?.toDouble(),
      ca153: map['ca153']?.toDouble(),
      psa: map['psa']?.toDouble(),
      
      // Cardiac
      troponin: map['troponin']?.toDouble(),
      ckMb: map['ck_mb']?.toDouble(),
      ldh: map['ldh']?.toDouble(),
      bnp: map['bnp']?.toDouble(),
      
      // Inflammatory
      crp: map['crp']?.toDouble(),
      esr: map['esr']?.toDouble(),
      procalcitonin: map['procalcitonin']?.toDouble(),
      
      // Hormones
      insulin: map['insulin']?.toDouble(),
      cortisol: map['cortisol']?.toDouble(),
      testosterone: map['testosterone']?.toDouble(),
      estradiol: map['estradiol']?.toDouble(),
      progesterone: map['progesterone']?.toDouble(),
      prolactin: map['prolactin']?.toDouble(),
      fsh: map['fsh']?.toDouble(),
      lh: map['lh']?.toDouble(),
      
      notes: map['notes'],
      riskLevel: map['risk_level'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  BloodTestResult copyWith({
    int? id,
    int? userId,
    String? testDate,
    String? laboratoryName,
    String? doctorName,
    String? testType,
    String? importSource,
    double? hemoglobin,
    double? hematocrit,
    double? redBloodCells,
    double? whiteBloodCells,
    double? platelets,
    double? mcv,
    double? mch,
    double? mchc,
    double? rdw,
    double? mpv,
    double? neutrophils,
    double? lymphocytes,
    double? monocytes,
    double? eosinophils,
    double? basophils,
    double? iron,
    double? ferritin,
    double? transferrin,
    double? tibc,
    double? transferrinSaturation,
    double? alt,
    double? ast,
    double? alp,
    double? ggt,
    double? bilirubin,
    double? directBilirubin,
    double? albumin,
    double? totalProtein,
    double? creatinine,
    double? urea,
    double? uricAcid,
    double? gfr,
    double? totalCholesterol,
    double? ldlCholesterol,
    double? hdlCholesterol,
    double? triglycerides,
    double? nonHdlCholesterol,
    double? glucose,
    double? hba1c,
    double? fructosamine,
    double? tsh,
    double? t3,
    double? t4,
    double? freeT3,
    double? freeT4,
    double? sodium,
    double? potassium,
    double? chloride,
    double? calcium,
    double? magnesium,
    double? phosphorus,
    double? vitaminB12,
    double? vitaminD,
    double? folate,
    double? vitaminA,
    double? vitaminE,
    double? vitaminC,
    double? cea,
    double? afp,
    double? ca125,
    double? ca199,
    double? ca153,
    double? psa,
    double? troponin,
    double? ckMb,
    double? ldh,
    double? bnp,
    double? crp,
    double? esr,
    double? procalcitonin,
    double? insulin,
    double? cortisol,
    double? testosterone,
    double? estradiol,
    double? progesterone,
    double? prolactin,
    double? fsh,
    double? lh,
    String? notes,
    String? riskLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodTestResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testDate: testDate ?? this.testDate,
      laboratoryName: laboratoryName ?? this.laboratoryName,
      doctorName: doctorName ?? this.doctorName,
      testType: testType ?? this.testType,
      importSource: importSource ?? this.importSource,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      hematocrit: hematocrit ?? this.hematocrit,
      redBloodCells: redBloodCells ?? this.redBloodCells,
      whiteBloodCells: whiteBloodCells ?? this.whiteBloodCells,
      platelets: platelets ?? this.platelets,
      mcv: mcv ?? this.mcv,
      mch: mch ?? this.mch,
      mchc: mchc ?? this.mchc,
      rdw: rdw ?? this.rdw,
      mpv: mpv ?? this.mpv,
      neutrophils: neutrophils ?? this.neutrophils,
      lymphocytes: lymphocytes ?? this.lymphocytes,
      monocytes: monocytes ?? this.monocytes,
      eosinophils: eosinophils ?? this.eosinophils,
      basophils: basophils ?? this.basophils,
      iron: iron ?? this.iron,
      ferritin: ferritin ?? this.ferritin,
      transferrin: transferrin ?? this.transferrin,
      tibc: tibc ?? this.tibc,
      transferrinSaturation: transferrinSaturation ?? this.transferrinSaturation,
      alt: alt ?? this.alt,
      ast: ast ?? this.ast,
      alp: alp ?? this.alp,
      ggt: ggt ?? this.ggt,
      bilirubin: bilirubin ?? this.bilirubin,
      directBilirubin: directBilirubin ?? this.directBilirubin,
      albumin: albumin ?? this.albumin,
      totalProtein: totalProtein ?? this.totalProtein,
      creatinine: creatinine ?? this.creatinine,
      urea: urea ?? this.urea,
      uricAcid: uricAcid ?? this.uricAcid,
      gfr: gfr ?? this.gfr,
      totalCholesterol: totalCholesterol ?? this.totalCholesterol,
      ldlCholesterol: ldlCholesterol ?? this.ldlCholesterol,
      hdlCholesterol: hdlCholesterol ?? this.hdlCholesterol,
      triglycerides: triglycerides ?? this.triglycerides,
      nonHdlCholesterol: nonHdlCholesterol ?? this.nonHdlCholesterol,
      glucose: glucose ?? this.glucose,
      hba1c: hba1c ?? this.hba1c,
      fructosamine: fructosamine ?? this.fructosamine,
      tsh: tsh ?? this.tsh,
      t3: t3 ?? this.t3,
      t4: t4 ?? this.t4,
      freeT3: freeT3 ?? this.freeT3,
      freeT4: freeT4 ?? this.freeT4,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      chloride: chloride ?? this.chloride,
      calcium: calcium ?? this.calcium,
      magnesium: magnesium ?? this.magnesium,
      phosphorus: phosphorus ?? this.phosphorus,
      vitaminB12: vitaminB12 ?? this.vitaminB12,
      vitaminD: vitaminD ?? this.vitaminD,
      folate: folate ?? this.folate,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminE: vitaminE ?? this.vitaminE,
      vitaminC: vitaminC ?? this.vitaminC,
      cea: cea ?? this.cea,
      afp: afp ?? this.afp,
      ca125: ca125 ?? this.ca125,
      ca199: ca199 ?? this.ca199,
      ca153: ca153 ?? this.ca153,
      psa: psa ?? this.psa,
      troponin: troponin ?? this.troponin,
      ckMb: ckMb ?? this.ckMb,
      ldh: ldh ?? this.ldh,
      bnp: bnp ?? this.bnp,
      crp: crp ?? this.crp,
      esr: esr ?? this.esr,
      procalcitonin: procalcitonin ?? this.procalcitonin,
      insulin: insulin ?? this.insulin,
      cortisol: cortisol ?? this.cortisol,
      testosterone: testosterone ?? this.testosterone,
      estradiol: estradiol ?? this.estradiol,
      progesterone: progesterone ?? this.progesterone,
      prolactin: prolactin ?? this.prolactin,
      fsh: fsh ?? this.fsh,
      lh: lh ?? this.lh,
      notes: notes ?? this.notes,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodTestResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BloodTestResult(id: $id, userId: $userId, testDate: $testDate, importSource: $importSource)';
  }
}

/// Reference ranges for blood test parameters
class BloodTestReferenceRanges {
  static const Map<String, Map<String, double>> ranges = {
    // Hemogram
    'hemoglobin_male': {'min': 13.0, 'max': 17.0},
    'hemoglobin_female': {'min': 12.0, 'max': 15.0},
    'hematocrit_male': {'min': 40.0, 'max': 52.0},
    'hematocrit_female': {'min': 36.0, 'max': 46.0},
    'red_blood_cells_male': {'min': 4.5, 'max': 5.5},
    'red_blood_cells_female': {'min': 4.0, 'max': 5.0},
    'white_blood_cells': {'min': 4.0, 'max': 11.0},
    'platelets': {'min': 150.0, 'max': 400.0},
    'mcv': {'min': 80.0, 'max': 100.0},
    'mch': {'min': 27.0, 'max': 32.0},
    'mchc': {'min': 32.0, 'max': 36.0},
    'rdw': {'min': 11.5, 'max': 14.5},
    
    // Iron Studies
    'iron_male': {'min': 60.0, 'max': 170.0},
    'iron_female': {'min': 50.0, 'max': 150.0},
    'ferritin_male': {'min': 20.0, 'max': 300.0},
    'ferritin_female': {'min': 10.0, 'max': 120.0},
    
    // Liver Function
    'alt': {'min': 7.0, 'max': 35.0},
    'ast': {'min': 8.0, 'max': 40.0},
    'alp': {'min': 44.0, 'max': 147.0},
    'ggt_male': {'min': 15.0, 'max': 73.0},
    'ggt_female': {'min': 9.0, 'max': 32.0},
    'bilirubin': {'min': 0.2, 'max': 1.2},
    'albumin': {'min': 3.5, 'max': 5.0},
    'total_protein': {'min': 6.0, 'max': 8.3},
    
    // Kidney Function
    'creatinine_male': {'min': 0.7, 'max': 1.3},
    'creatinine_female': {'min': 0.6, 'max': 1.1},
    'urea': {'min': 2.1, 'max': 7.1},
    'uric_acid_male': {'min': 3.4, 'max': 7.0},
    'uric_acid_female': {'min': 2.4, 'max': 6.0},
    'gfr': {'min': 90.0, 'max': 120.0},
    
    // Lipid Profile
    'total_cholesterol': {'min': 0.0, 'max': 200.0},
    'ldl_cholesterol': {'min': 0.0, 'max': 100.0},
    'hdl_cholesterol_male': {'min': 40.0, 'max': 60.0},
    'hdl_cholesterol_female': {'min': 50.0, 'max': 70.0},
    'triglycerides': {'min': 0.0, 'max': 150.0},
    
    // Diabetes
    'glucose_fasting': {'min': 70.0, 'max': 100.0},
    'hba1c': {'min': 4.0, 'max': 5.6},
    
    // Thyroid
    'tsh': {'min': 0.27, 'max': 4.2},
    'free_t4': {'min': 12.0, 'max': 22.0},
    'free_t3': {'min': 3.1, 'max': 6.8},
    
    // Vitamins
    'vitamin_b12': {'min': 200.0, 'max': 900.0},
    'vitamin_d': {'min': 30.0, 'max': 100.0},
    'folate': {'min': 2.7, 'max': 17.0},
    
    // Inflammatory
    'crp': {'min': 0.0, 'max': 3.0},
    'esr_male': {'min': 0.0, 'max': 15.0},
    'esr_female': {'min': 0.0, 'max': 20.0},
  };

  static Map<String, double>? getReferenceRange(String parameter, String? gender) {
    String key = parameter;
    if (gender != null && ranges.containsKey('${parameter}_${gender.toLowerCase()}')) {
      key = '${parameter}_${gender.toLowerCase()}';
    }
    return ranges[key];
  }

  static String getStatus(String parameter, double value, String? gender) {
    final range = getReferenceRange(parameter, gender);
    if (range == null) return 'unknown';
    
    if (value < range['min']!) return 'low';
    if (value > range['max']!) return 'high';
    return 'normal';
  }
}