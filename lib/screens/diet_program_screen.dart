import 'package:flutter/material.dart';

class DietProgramScreen extends StatefulWidget {
  const DietProgramScreen({Key? key}) : super(key: key);

  @override
  State<DietProgramScreen> createState() => _DietProgramScreenState();
}

class _DietProgramScreenState extends State<DietProgramScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Örnek hemogram değerleri (gerçek uygulamada önceki ekrandan gelecek)
  final Map<String, double> userValues = {
    'Demir (mcg/dL)': 50.0,  // Düşük
    'Hemoglobin (g/dL)': 11.5,  // Düşük
    'Lökosit (K/uL)': 8.0,
    'Trombosit (K/uL)': 200.0,
    'B12': 250.0,  // Normal alt sınır
    'Folik Asit': 3.0,  // Düşük
  };

  // AI analiz sonuçlarına göre kişiselleştirilmiş öneriler
  final Map<String, Map<String, dynamic>> nutritionNeeds = {
    'Demir': {
      'status': 'Düşük',
      'color': Colors.red,
      'foods': ['Kırmızı et', 'Karaciğer', 'Ispanak', 'Kuru üzüm', 'Kuru kayısı', 'Kuru fasulye', 'Mercimek'],
      'avoid': ['Çay (yemekle)', 'Kahve (yemekle)', 'Süt ürünleri (demir ile)'],
      'supplements': ['Demir tablet (boş mideyle)', 'C vitamini (emilimi artırır)'],
      'tips': ['Demir kaynaklarını C vitamini ile tüketin', 'Yemekten 1 saat sonra çay/kahve için']
    },
    'Hemoglobin': {
      'status': 'Düşük',
      'color': Colors.red,
      'foods': ['Et', 'Tavuk', 'Balık', 'Yumurta', 'Koyu yeşil yapraklar', 'Kuruyemiş'],
      'avoid': ['İşlenmiş gıdalar', 'Aşırı şekerli besinler'],
      'supplements': ['B12', 'Folik asit', 'Demir'],
      'tips': ['Protein alımını artırın', 'B vitaminlerini eksik etmeyin']
    },
    'B12': {
      'status': 'Normal',
      'color': Colors.orange,
      'foods': ['Balık', 'Et', 'Süt ürünleri', 'Yumurta', 'Tahıllar (zenginleştirilmiş)'],
      'avoid': ['Aşırı alkol'],
      'supplements': ['B-kompleks vitamin'],
      'tips': ['Düzenli hayvansal protein tüketin']
    },
    'Folik Asit': {
      'status': 'Düşük',
      'color': Colors.red,
      'foods': ['Koyu yeşil yapraklar', 'Brokoli', 'Asparagus', 'Baklagiller', 'Turunçgiller'],
      'avoid': ['Aşırı pişirme (vitaminleri yok eder)'],
      'supplements': ['Folik asit tablet'],
      'tips': ['Sebzeleri buharda pişirin', 'Çiğ salata tüketin']
    }
  };

  // Haftalık diyet planı
  final Map<String, Map<String, List<String>>> weeklyPlan = {
    'Pazartesi': {
      'Kahvaltı': ['2 yumurta omlet', 'Tam tahıllı ekmek', 'Portakal suyu', 'Ceviz (5-6 adet)'],
      'Öğle': ['Kırmızı et (150g)', 'Pilav', 'Ispanak salatası', 'Ayran'],
      'Akşam': ['Somon balığı', 'Buharda brokoli', 'Bulgur pilavı', 'Yeşil salata'],
      'Ara': ['Kuru üzüm (1 avuç)', 'Badem (10 adet)', 'Yeşil çay (yemekten 2 saat sonra)']
    },
    'Salı': {
      'Kahvaltı': ['Yoğurt', 'Bal', 'Kuru kayısı (5 adet)', 'Tam tahıllı müsli'],
      'Öğle': ['Tavuk göğsü', 'Mercimek çorbası', 'Yeşil salata', 'Ayran'],
      'Akşam': ['Dana eti', 'Pırasa yemeği', 'Pirinç pilavı', 'Cacık'],
      'Ara': ['Nar (1 kase)', 'Kuruyemiş karışımı', 'Bitki çayı']
    },
    'Çarşamba': {
      'Kahvaltı': ['Peynir omlet', 'Domates', 'Salatalık', 'Tam tahıllı ekmek'],
      'Öğle': ['Kuru fasulye', 'Pilav', 'Turşu', 'Ayran'],
      'Akşam': ['Levrek balığı', 'Ispanak (sade)', 'Bulgur', 'Semizotu salatası'],
      'Ara': ['Elma', 'Fındık', 'Ihlamur çayı']
    }
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildNutritionCard(String nutrient, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data['color'], width: 2),
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
            children: [
              Icon(Icons.circle, color: data['color'], size: 12),
              const SizedBox(width: 8),
              Text(
                nutrient,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53E3E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['status'],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Önerilen Gıdalar
          _buildSection('🥗 Tüketmeniz Gerekenler', data['foods'], Colors.green),
          const SizedBox(height: 12),
          
          // Kaçınılacaklar
          if (data['avoid'].isNotEmpty) ...[
            _buildSection('⚠️ Kaçınmanız Gerekenler', data['avoid'], Colors.red),
            const SizedBox(height: 12),
          ],
          
          // Takviyeler
          _buildSection('💊 Takviye Önerileri', data['supplements'], Colors.blue),
          const SizedBox(height: 12),
          
          // İpuçları
          _buildTipsSection('💡 AI Tavsiyeleri', data['tips']),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              item,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTipsSection(String title, List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE53E3E),
          ),
        ),
        const SizedBox(height: 8),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDayPlan(String day, Map<String, List<String>> meals) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53E3E).withOpacity(0.3)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          ...meals.entries.map((mealEntry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealEntry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 4),
                ...mealEntry.value.map((food) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 6, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(food, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )).toList(),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kişisel Diyet Programınız'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'AI Analiz'),
            Tab(icon: Icon(Icons.restaurant), text: 'Beslenme'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Haftalık Plan'),
            Tab(icon: Icon(Icons.trending_up), text: 'Takip'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // AI Analiz Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Başlık
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.psychology, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'AI Beslenme Analizi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hemogram sonuçlarınıza özel diyet önerileri',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Beslenme İhtiyaçları
                ...nutritionNeeds.entries.map(
                  (entry) => _buildNutritionCard(entry.key, entry.value),
                ).toList(),
              ],
            ),
          ),
          
          // Beslenme Tab - Gıda kategorileri
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Hemogram Sonuçlarınıza Göre\nGıda Önerileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Burada gıda kategorileri olacak
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Text(
                    'Bu bölümde kategori bazında gıda önerileri, porsiyonlar ve günlük alım miktarları yer alacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          
          // Haftalık Plan Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Size Özel Haftalık\nBeslenme Planı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                ...weeklyPlan.entries.map(
                  (dayEntry) => _buildDayPlan(dayEntry.key, dayEntry.value),
                ).toList(),
              ],
            ),
          ),
          
          // Takip Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'İlerleme Takibi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Text(
                    'Bu bölümde diyet uyumunuz, kilo değişimi ve kan değerlerindeki iyileşme takip edilecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
