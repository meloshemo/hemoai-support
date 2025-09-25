import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

class AlternativeMedicineScreen extends StatefulWidget {
  const AlternativeMedicineScreen({Key? key}) : super(key: key);

  @override
  State<AlternativeMedicineScreen> createState() => _AlternativeMedicineScreenState();
}

class _AlternativeMedicineScreenState extends State<AlternativeMedicineScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final PreferencesService _preferencesService = PreferencesService();
  
  Map<String, double> userValues = {};
  List<String> recommendedCategories = [];
  bool isLoading = true;

  // Bitkisel çözümler verisi
  final Map<String, Map<String, dynamic>> herbalSolutions = {
    'Demir Eksikliği': {
      'icon': '🩸',
      'color': Colors.red,
      'herbs': [
        {
          'name': 'Isırgan Otu',
          'usage': 'Günde 2 kez çay olarak',
          'benefits': 'Doğal demir kaynağı, kan yapımını destekler',
          'preparation': '1 çay kaşığı kurutulmuş yaprak, 1 bardak sıcak su ile demleyin',
          'warning': 'Hamilelikte doktor kontrolü gerekli',
        },
        {
          'name': 'Pekmez (Üzüm/Dut)',
          'usage': 'Günde 1 yemek kaşığı',
          'benefits': 'Yüksek demir içeriği, kolay emilim',
          'preparation': 'Kahvaltıda veya ara öğünde tüketin',
          'warning': 'Şeker hastalığında dikkatli kullanın',
        },
        {
          'name': 'Kekik Çayı',
          'usage': 'Günde 2-3 fincan',
          'benefits': 'Demir emilimini artırır, bağışıklığı güçlendirir',
          'preparation': '1 tatlı kaşığı kekik, 5 dakika demleyin',
          'warning': 'Tansiyon hastaları dikkat etsin',
        },
      ]
    },
    'Anemi': {
      'icon': '🌿',
      'color': Colors.green,
      'herbs': [
        {
          'name': 'Keçiboynuzu',
          'usage': 'Günde 1 bardak çay',
          'benefits': 'B12 ve folik asit içerir, kan yapımını destekler',
          'preparation': 'Tozunu süt veya suyla karıştırın',
          'warning': 'Alerji durumunda kullanmayın',
        },
        {
          'name': 'Nar Suyu',
          'usage': 'Günde 1 bardak taze sıkılmış',
          'benefits': 'Antioksidan, hemoglobin artırıcı',
          'preparation': 'Taze sıkılmış tercih edin, aç karnına için',
          'warning': 'İlaç etkileşimi olabilir',
        },
        {
          'name': 'Kırmızı Pancar',
          'usage': 'Haftada 3-4 kez salata olarak',
          'benefits': 'Nitrat içeriği yüksek, kan dolaşımını iyileştirir',
          'preparation': 'Çiğ rendeleyin veya haşlayın',
          'warning': 'Böbrek taşı riski olanlar dikkat etsin',
        },
      ]
    },
    'Bağışıklık': {
      'icon': '🛡️',
      'color': Colors.blue,
      'herbs': [
        {
          'name': 'Propolis',
          'usage': 'Günde 10-15 damla',
          'benefits': 'Doğal antibiyotik, bağışıklık güçlendirici',
          'preparation': 'Su veya bal ile karıştırarak alın',
          'warning': 'Arı ürünlerine alerjisi olanlarda dikkat',
        },
        {
          'name': 'Ekinezya',
          'usage': 'Günde 2-3 fincan çay',
          'benefits': 'Viral enfeksiyonlara karşı korur',
          'preparation': 'Kurutulmuş kökü kaynatın',
          'warning': 'Otoimmün hastalıklarda kullanmayın',
        },
        {
          'name': 'Zencefil',
          'usage': 'Günde 2-3 dilim taze',
          'benefits': 'Anti-enflamatuar, sindirim destekleyici',
          'preparation': 'Çay olarak demleyin veya yemeğe ekleyin',
          'warning': 'Kan sulandırıcı kullanıyorsanız dikkat',
        },
      ]
    },
    'Trombosit': {
      'icon': '🩹',
      'color': Colors.orange,
      'herbs': [
        {
          'name': 'Papaya Yaprağı',
          'usage': 'Günde 2 kez çay olarak',
          'benefits': 'Trombosit sayısını artırır',
          'preparation': 'Taze yaprakları kaynatın, soğutarak için',
          'warning': 'Hamilelikte kullanmayın',
        },
        {
          'name': 'Ginkgo Biloba',
          'usage': 'Günde 1-2 fincan çay',
          'benefits': 'Kan dolaşımını iyileştirir',
          'preparation': 'Kurutulmuş yaprakları demleyin',
          'warning': 'Ameliyat öncesi bırakın',
        },
      ]
    },
  };

  // Yöresel tedavi yöntemleri
  final List<Map<String, dynamic>> traditionalMethods = [
    {
      'title': 'Hacamat Tedavisi',
      'icon': '🩸',
      'description': 'Kan dolaşımını iyileştiren geleneksel yöntem',
      'benefits': 'Kirli kanın çıkarılması, dolaşım iyileşmesi',
      'procedure': 'Uzman tarafından steril ortamda uygulanmalı',
      'frequency': 'Ayda 1-2 kez',
      'warning': 'Kan hastalığı varsa doktor onayı şart',
      'color': Colors.red,
    },
    {
      'title': 'Sülük Tedavisi',
      'icon': '🐛',
      'description': 'Doğal kan inceltici ve detoks yöntemi',
      'benefits': 'Kan pıhtılaşmasını önler, toksin atılımı',
      'procedure': 'Tıbbi sülüklerle uzman gözetiminde',
      'frequency': '3 ayda 1 kez',
      'warning': 'Enfeksiyon riski, steril ortam şart',
      'color': Colors.green,
    },
    {
      'title': 'Kuru Kupa',
      'icon': '🥤',
      'description': 'Vakum ile kan dolaşımını hızlandırma',
      'benefits': 'Kas gevşemesi, dolaşım artışı',
      'procedure': 'Cam kupa ile vakum oluşturulur',
      'frequency': 'Haftada 1-2 kez',
      'warning': 'Deri hassasiyeti olanlarda dikkat',
      'color': Colors.blue,
    },
    {
      'title': 'Refleksoloji',
      'icon': '🦶',
      'description': 'Ayak masajı ile organ uyarımı',
      'benefits': 'Dolaşımı artırır, organları uyarır',
      'procedure': 'Ayak tabanında belirli noktalara baskı',
      'frequency': 'Haftada 2-3 kez',
      'warning': 'Ayak yaraları varsa yapmayın',
      'color': Colors.purple,
    },
    {
      'title': 'Aromaterapi',
      'icon': '🌸',
      'description': 'Uçucu yağlarla tedavi',
      'benefits': 'Stres azalması, hormon dengelenmesi',
      'procedure': 'Diffüzer ile soluma veya masaj yağı',
      'frequency': 'Günlük kullanım',
      'warning': 'Hamilelikte bazı yağlar tehlikeli',
      'color': Colors.pink,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildHerbalCard(String category, Map<String, dynamic> categoryData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryData['color'].withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryData['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            categoryData['icon'],
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          category,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: categoryData['color'],
          ),
        ),
        subtitle: Text(
          '${categoryData['herbs'].length} bitkisel çözüm',
          style: const TextStyle(color: Colors.grey),
        ),
        children: categoryData['herbs'].map<Widget>((herb) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryData['color'].withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  herb['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildInfoRow('Kullanım', herb['usage'], Icons.schedule),
                _buildInfoRow('Faydaları', herb['benefits'], Icons.favorite),
                _buildInfoRow('Hazırlanış', herb['preparation'], Icons.build),
                
                if (herb['warning'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Uyarı: ${herb['warning']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionalCard(Map<String, dynamic> method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: method['color'].withOpacity(0.3)),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: method['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  method['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: method['color'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['description'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: method['color'].withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildMethodInfo('Faydaları', method['benefits'], Icons.check_circle),
                _buildMethodInfo('Uygulama', method['procedure'], Icons.build),
                _buildMethodInfo('Sıklık', method['frequency'], Icons.schedule),
              ],
            ),
          ),
          
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
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uyarı: ${method['warning']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAdvice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Genel uyarı
          Container(
            padding: const EdgeInsets.all(16),
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
                Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Önemli Hatırlatma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Alternatif tıp yöntemleri tamamlayıcı tedavi amacıyla kullanılmalıdır. Ana tedavinizin yerini alamaz. Mutlaka doktorunuzla görüşerek uygulayın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Genel kurallar
          const Text(
            'Temel Kurallar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          
          ...[
            'Herhangi bir bitkisel ürünü kullanmadan önce doktorunuza danışın',
            'İlaçlarınızla etkileşim olup olmadığını kontrol ettirin',
            'Hamilelik, emzirme döneminde extra dikkatli olun',
            'Alerjik reaksiyonlara karşı dikkatli olun, küçük dozlarla başlayın',
            'Kaliteli, güvenilir kaynaklardan temin edin',
            'Belirtilen dozları aşmayın',
            'Yan etki görürseniz hemen bırakın ve doktora başvurun',
          ].map((rule) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 24),
          
          // Uzman tavsiyeleri
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Uzman Desteği',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Alternatif tıp yöntemlerini uygulamadan önce:\n\n'
                  '• Fitoterapist veya geleneksel tıp uzmanına danışın\n'
                  '• Hematoloji uzmanınızın onayını alın\n'
                  '• Düzenli kan takibinizi aksatmayın\n'
                  '• Tedavi sürecinizi doktorunuzla paylaşın',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Alternatif Tıp & Yöresel Yöntemler'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: const [
            Tab(icon: Icon(Icons.local_florist), text: 'Bitkisel'),
            Tab(icon: Icon(Icons.healing), text: 'Yöresel'),
            Tab(icon: Icon(Icons.info), text: 'Genel Bilgi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bitkisel Çözümler
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hemogram Sorunları İçin Bitkisel Çözümler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Doğal bitkisel ürünlerle kan değerlerinizi destekleyin',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                ...herbalSolutions.entries.map((entry) => 
                  _buildHerbalCard(entry.key, entry.value)
                ).toList(),
              ],
            ),
          ),
          
          // Yöresel Tedaviler
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Geleneksel Tedavi Yöntemleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Asırlar boyunca kullanılan geleneksel iyileştirme yöntemleri',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                ...traditionalMethods.map((method) => 
                  _buildTraditionalCard(method)
                ).toList(),
              ],
            ),
          ),
          
          // Genel Bilgi
          _buildGeneralAdvice(),
        ],
      ),
    );
  }
}