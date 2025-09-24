import 'package:flutter/material.dart';

class AnalysisScreen extends StatelessWidget {
  final Map<String, double> exampleValues = {
    'Demir (mcg/dL)': 50,
    'Hemoglobin (g/dL)': 11.5,
    'Lökosit (K/uL)': 8.0,
    'Eritrosit (M/uL)': 5.0,
    'Hematokrit (%)': 40.0,
    'Trombosit (K/uL)': 200.0,
    'MCV (fL)': 85.0,
    'MCH (pg)': 29.0,
    'MCHC (g/dL)': 34.0,
    'RDW (%)': 13.0,
    'Nötrofil (%)': 60.0,
    'Lenfosit (%)': 30.0,
    'Monosit (%)': 5.0,
    'Eozinofil (%)': 2.0,
    'Bazofil (%)': 1.0,
  };

  // Detaylı tavsiye sistemi - Anormal değerler için
  final Map<String, Map<String, dynamic>> detailedAdvice = {
    'Demir (mcg/dL)': {
      'low_symptoms': 'Yorgunluk, solgun cilt, nefes darlığı, saç dökülmesi',
      'high_symptoms': 'Karın ağrısı, kalp ritmi bozukluğu, eklem ağrıları',
      'herbal_remedies': 'Kuru üzüm, pekmez, ısırgan otu çayı, bitkisel demir takviyeleri, kekik çayı',
      'foods_increase': 'Kırmızı et, karaciğer, ıspanak, nohut, mercimek, susam, kabak çekirdeği',
      'foods_avoid': 'Çay, kahve (yemekten sonra), süt ürünleri (demir ile birlikte)',
      'lifestyle': 'C vitamini ile birlikte alım, demir tava kullanımı, düzenli egzersiz',
      'warning': 'Düşük demir anemiye, yüksek demir organ hasarına yol açabilir',
    },
    'Hemoglobin (g/dL)': {
      'low_symptoms': 'Şiddetli yorgunluk, baş dönmesi, kalp çarpıntısı, solgun görünüm',
      'high_symptoms': 'Baş ağrısı, görme bulanıklığı, kırmızı cilt, tromboz riski',
      'herbal_remedies': 'Isırgan otu, keçiboynuzu, nar suyu, bitkisel karışımlar, defne yaprağı',
      'foods_increase': 'Kırmızı et, tavuk ciğeri, balık, yumurta, koyu yeşil sebzeler',
      'foods_avoid': 'Alkol, aşırı kafein, işlenmiş gıdalar',
      'lifestyle': 'Yeterli uyku, stres yönetimi, düzenli kan kontrolü',
      'warning': 'Anemi veya polisitemi belirtisi olabilir, doktor kontrolü şart',
    },
    'Lökosit (K/uL)': {
      'low_symptoms': 'Sık enfeksiyon, yavaş iyileşme, ateş, halsizlik',
      'high_symptoms': 'Ateş, enfeksiyon belirtileri, yorgunluk, gece terlemesi',
      'herbal_remedies': 'Propolis, ekinezya, zencefil, sarımsak, yeşil çay',
      'foods_increase': 'Probiyotik yoğurt, sarımsak, zencefil, zerdeçal, mantar',
      'foods_avoid': 'Şeker, işlenmiş gıdalar, aşırı alkol',
      'lifestyle': 'El hijyeni, yeterli uyku, stresten kaçınma, düzenli egzersiz',
      'warning': 'Enfeksiyon veya immün sistem sorunu işareti olabilir',
    },
    'Trombosit (K/uL)': {
      'low_symptoms': 'Kolay morarma, sık burun kanaması, diş eti kanaması',
      'high_symptoms': 'Tromboz riski, baş ağrısı, göğüs ağrısı',
      'herbal_remedies': 'C vitamini, papaya yaprağı çayı, nar suyu, ginkgo biloba',
      'foods_increase': 'Papaya, kiwi, portakal, brokkoli, yeşil sebzeler',
      'foods_avoid': 'Alkol, çiğ balık, aşırı E vitamini',
      'lifestyle': 'Yaralanmalardan kaçınma, düzenli kontrol',
      'warning': 'Kanama bozukluğu veya tromboz riski, acil doktor kontrolü',
    },
  };

  final Map<String, String> altTipAdvice = {
    'Demir (mcg/dL)': 'Kuru üzüm, pekmez, ısırgan otu çayı, bitkisel demir takviyeleri.',
    'Hemoglobin (g/dL)': 'Isırgan otu, keçiboynuzu, nar suyu, bitkisel karışımlar.',
    'Lökosit (K/uL)': 'Propolis, ekinezya, zencefil, sarımsak.',
    'Trombosit (K/uL)': 'C vitamini, papaya yaprağı çayı, nar suyu.',
    'MCV (fL)': 'B12 ve folik asit içeren bitkisel takviyeler.',
    'MCH (pg)': 'Kırmızı pancar, ısırgan otu.',
    'MCHC (g/dL)': 'C vitamini ve demir içeren bitkisel karışımlar.',
    'RDW (%)': 'Demir ve B12 takviyeli bitkisel ürünler.',
    'Nötrofil (%)': 'Zencefil, sarımsak, ekinezya.',
    'Lenfosit (%)': 'Propolis, zerdeçal.',
    'Monosit (%)': 'Dengeli bitkisel beslenme.',
    'Eozinofil (%)': 'Alerjiye karşı bitkisel çaylar.',
    'Bazofil (%)': 'Alerjiye karşı bitkisel karışımlar.',
  };

  final Map<String, String> dietPrograms = {
    'Demir (mcg/dL)': 'Demir diyeti: Kırmızı et, yumurta, baklagil, yeşil sebze ağırlıklı beslenme.',
    'Hemoglobin (g/dL)': 'Hemoglobin diyeti: Demir ve B12 içeren gıdalar, nar, ıspanak.',
    'Lökosit (K/uL)': 'Bağışıklık diyeti: C vitamini, probiyotik, zencefil, sarımsak.',
    'Trombosit (K/uL)': 'Trombosit diyeti: Folik asit, B12, nar, papaya.',
    'MCV (fL)': 'B12 ve folik asit diyeti: Yumurta, süt, yeşil yapraklı sebzeler.',
    'MCH (pg)': 'Demir ve protein diyeti: Kırmızı et, balık, baklagil.',
    'MCHC (g/dL)': 'Demir ve C vitamini diyeti: Portakal, kırmızı et.',
    'RDW (%)': 'Demir ve B12 diyeti: Yumurta, kırmızı et, süt.',
    'Nötrofil (%)': 'Protein ve vitamin diyeti: Tavuk, balık, yumurta.',
    'Lenfosit (%)': 'Bağışıklık diyeti: Yoğurt, kefir, zerdeçal.',
    'Monosit (%)': 'Dengeli diyet: Sebze, meyve, tam tahıl.',
    'Eozinofil (%)': 'Alerjiye uygun diyet: Gluten ve süt ürünlerinden kaçınma.',
    'Bazofil (%)': 'Alerjiye uygun diyet: Bitkisel ağırlıklı beslenme.',
  };

  final Map<String, List<double>> referenceRanges = {
    'Demir (mcg/dL)': [60, 170],
    'Hemoglobin (g/dL)': [12, 17],
    'Lökosit (K/uL)': [4, 10],
    'Eritrosit (M/uL)': [4.5, 6],
    'Hematokrit (%)': [38, 50],
    'Trombosit (K/uL)': [150, 400],
    'MCV (fL)': [80, 100],
    'MCH (pg)': [27, 33],
    'MCHC (g/dL)': [32, 36],
    'RDW (%)': [11.5, 14.5],
    'Nötrofil (%)': [40, 75],
    'Lenfosit (%)': [20, 45],
    'Monosit (%)': [2, 10],
    'Eozinofil (%)': [1, 6],
    'Bazofil (%)': [0, 2],
  };

  final Map<String, String> doctorAdvice = {
    'Demir (mcg/dL)': 'Düşükse: Kırmızı et, deniz ürünleri, yumurta tüketin.',
    'Hemoglobin (g/dL)': 'Düşükse: Demir takviyesi ve yeşil yapraklı sebzeler önerilir.',
    'Lökosit (K/uL)': 'Düşükse: Bağışıklık güçlendirici besinler alın.',
    'Trombosit (K/uL)': 'Düşükse: Folik asit ve B12 içeren gıdalar tüketin.',
    'MCV (fL)': 'Düşükse: B12 ve folik asit takviyesi alın.',
    'MCH (pg)': 'Düşükse: Demir ve protein ağırlıklı beslenin.',
    'MCHC (g/dL)': 'Düşükse: Demir ve C vitamini alın.',
    'RDW (%)': 'Yüksekse: Demir eksikliği araştırılmalı.',
    'Nötrofil (%)': 'Düşükse: Protein ve vitamin desteği alın.',
    'Lenfosit (%)': 'Düşükse: Bağışıklık sistemini destekleyin.',
    'Monosit (%)': 'Düşükse: Dengeli beslenme önerilir.',
    'Eozinofil (%)': 'Yüksekse: Alerji ve enfeksiyon kontrolü.',
    'Bazofil (%)': 'Yüksekse: Alerjiye dikkat edin.',
  };

  Color getScaleColor(double value, double low, double high) {
    if (value < low) return Colors.red;
    if (value > high) return Colors.green;
    return Colors.yellow;
  }

  String getScaleText(Color color) {
    if (color == Colors.green) return 'İyi';
    if (color == Colors.yellow) return 'Normal';
    return 'Risk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Hemogram Analizi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // AI Analiz Başlık
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Destekli Hemogram Analizi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Yapay zeka ile kan değerlerinizi analiz ediyoruz',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Analiz Sonuçları
              ...exampleValues.keys.map((param) {
                double value = exampleValues[param]!;
                double low = referenceRanges[param]![0];
                double high = referenceRanges[param]![1];
                Color color = getScaleColor(value, low, high);
                String advice = '';
                String altTip = '';
                String diet = '';
                if ((color == Colors.red || color == Colors.yellow) && doctorAdvice[param] != null) {
                  advice = doctorAdvice[param]!;
                  altTip = altTipAdvice[param] ?? '';
                  diet = dietPrograms[param] ?? '';
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color == Colors.red ? Colors.red[300]! : 
                             color == Colors.yellow ? Colors.orange[300]! : 
                             Colors.green[300]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              param,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE53E3E),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getScaleText(color),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Değer: ${value.toStringAsFixed(1)} (Normal: ${low.toStringAsFixed(1)}-${high.toStringAsFixed(1)})',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      
                      if (advice.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medical_services, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Doktor Tavsiyesi: $advice',
                                  style: const TextStyle(color: Colors.blue, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (altTip.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_florist, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bitkisel Çözüm: $altTip',
                                  style: const TextStyle(color: Colors.green, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (diet.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant, color: Colors.deepOrange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Beslenme: $diet',
                                  style: const TextStyle(color: Colors.deepOrange, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              
              // Alt Butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detaylı Tavsiyeler'),
                      onPressed: () {
                        _showDetailedAdvice(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Diyet Programı'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/diet_program');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE53E3E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE53E3E), width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.family_restroom),
                      label: const Text('Aile Paneli'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/family_panel');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE53E3E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE53E3E), width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // AI Özet
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[100]!, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE53E3E), width: 1),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.summarize, color: Color(0xFFE53E3E), size: 30),
                    const SizedBox(height: 12),
                    const Text(
                      'AI Genel Değerlendirme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hemogram sonuçlarınız genel olarak dikkat gerektiren bazı değerler içermektedir. Özellikle demir ve hemoglobin seviyeleriniz normalin altında. Kişiselleştirilmiş diyet programınızı inceleyerek beslenme düzeninizi iyileştirebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.notifications),
                      label: const Text('Hatırlatıcıları Ayarla'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedAdvice(BuildContext context) {
    List<String> abnormalParams = _getAbnormalParameters();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Color(0xFFE53E3E), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detaylı Sağlık Tavsiyeleri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              if (abnormalParams.isEmpty) 
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Tebrikler! Tüm değerleriniz normal aralıkta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sağlıklı yaşam tarzınızı sürdürmeye devam edin.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: abnormalParams.length,
                    itemBuilder: (context, index) {
                      String param = abnormalParams[index];
                      Map<String, dynamic>? advice = detailedAdvice[param];
                      
                      if (advice == null) return const SizedBox.shrink();
                      
                      double value = exampleValues[param] ?? 0;
                      String status = _getParameterStatus(param, value);
                      Color statusColor = _getStatusColor(param, value);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Parametre başlığı
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    status == 'Düşük' ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        param,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$status - ${value.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Semptomlar
                            _buildAdviceSection(
                              'Belirtiler',
                              status == 'Düşük' ? advice['low_symptoms'] : advice['high_symptoms'],
                              Icons.warning,
                              Colors.orange,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Bitkisel çözümler
                            _buildAdviceSection(
                              'Bitkisel Çözümler',
                              advice['herbal_remedies'],
                              Icons.local_florist,
                              Colors.green,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Beslenme önerileri
                            _buildAdviceSection(
                              'Önerilen Gıdalar',
                              advice['foods_increase'],
                              Icons.restaurant,
                              Colors.blue,
                            ),
                            
                            if (advice['foods_avoid'] != null) ...[
                              const SizedBox(height: 12),
                              _buildAdviceSection(
                                'Kaçınılacak Gıdalar',
                                advice['foods_avoid'],
                                Icons.block,
                                Colors.red,
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            
                            // Yaşam tarzı
                            _buildAdviceSection(
                              'Yaşam Tarzı Önerileri',
                              advice['lifestyle'],
                              Icons.fitness_center,
                              Colors.purple,
                            ),
                            
                            if (advice['warning'] != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.priority_high, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '⚠️ Uyarı: ${advice['warning']}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              // Alt butonlar
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/diet_program');
                      },
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Kişisel Diyet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/notifications');
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Hatırlatıcı'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE53E3E),
                        side: const BorderSide(color: Color(0xFFE53E3E)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceSection(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  List<String> _getAbnormalParameters() {
    List<String> abnormal = [];
    
    final Map<String, List<double>> normalRanges = {
      'Demir (mcg/dL)': [60, 170],
      'Hemoglobin (g/dL)': [12.0, 17.0],
      'Lökosit (K/uL)': [4.0, 10.0],
      'Trombosit (K/uL)': [150, 400],
    };
    
    normalRanges.forEach((param, range) {
      double? value = exampleValues[param];
      if (value != null && (value < range[0] || value > range[1])) {
        abnormal.add(param);
      }
    });
    
    return abnormal;
  }

  String _getParameterStatus(String param, double value) {
    final Map<String, List<double>> normalRanges = {
      'Demir (mcg/dL)': [60, 170],
      'Hemoglobin (g/dL)': [12.0, 17.0],
      'Lökosit (K/uL)': [4.0, 10.0],
      'Trombosit (K/uL)': [150, 400],
    };
    
    List<double>? range = normalRanges[param];
    if (range == null) return 'Normal';
    
    if (value < range[0]) return 'Düşük';
    if (value > range[1]) return 'Yüksek';
    return 'Normal';
  }

  Color _getStatusColor(String param, double value) {
    String status = _getParameterStatus(param, value);
    switch (status) {
      case 'Düşük': return Colors.blue;
      case 'Yüksek': return Colors.red;
      default: return Colors.green;
    }
  }
}
