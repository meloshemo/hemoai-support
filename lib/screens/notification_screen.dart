import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Aktif bildirimler
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': '🩸 Tahlil Hatırlatıcısı',
      'subtitle': 'Ayşe için aylık kontrol zamanı',
      'description': 'Ayşe Yılmaz\'ın hemogram kontrolü bugün yapılmalı. Son tahlil değerleri düşük çıktığı için düzenli takip önemli.',
      'time': '09:00',
      'date': '24 Eylül 2025',
      'type': 'test_reminder',
      'priority': 'high',
      'icon': Icons.bloodtype,
      'color': Colors.red,
      'isRead': false,
    },
    {
      'id': '2',
      'title': '🚨 Kritik Değer Uyarısı',
      'subtitle': 'Hemoglobin seviyesi düşük',
      'description': 'Ayşe\'nin hemoglobin değeri (10.8 g/dL) normal seviyenin altında. Doktora danışmanız önerilir.',
      'time': '14:30',
      'date': '23 Eylül 2025',
      'type': 'critical_alert',
      'priority': 'high',
      'icon': Icons.warning,
      'color': Colors.red,
      'isRead': false,
    },
    {
      'id': '3',
      'title': '💊 İlaç Hatırlatıcısı',
      'subtitle': 'Demir takviyesi zamanı',
      'description': 'Ayşe için reçetelenen demir takviyesi alınmalı. Günde 1 tablet, öğünden sonra.',
      'time': '20:00',
      'date': '24 Eylül 2025',
      'type': 'medication',
      'priority': 'medium',
      'icon': Icons.medication,
      'color': Colors.orange,
      'isRead': true,
    },
    {
      'id': '4',
      'title': '🥗 Beslenme Önerisi',
      'subtitle': 'Demir içeriği yüksek yiyecekler',
      'description': 'Hemoglobin seviyesini artırmak için kırmızı et, ıspanak ve kuruyemiş tüketimi artırılmalı.',
      'time': '12:00',
      'date': '24 Eylül 2025',
      'type': 'nutrition',
      'priority': 'medium',
      'icon': Icons.restaurant,
      'color': Colors.green,
      'isRead': true,
    },
    {
      'id': '5',
      'title': '📅 Randevu Hatırlatıcısı',
      'subtitle': 'Dr. Mehmet Kaya - Hematoloji',
      'description': 'Yarın saat 10:00\'da hematoloji uzmanı ile randevunuz bulunmaktadır.',
      'time': '16:00',
      'date': '23 Eylül 2025',
      'type': 'appointment',
      'priority': 'medium',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
      'isRead': false,
    },
  ];

  // Hatırlatıcı ayarları
  final Map<String, bool> reminderSettings = {
    'test_reminders': true,
    'critical_alerts': true,
    'medication_reminders': true,
    'nutrition_tips': false,
    'appointment_reminders': true,
    'water_reminders': true,
    'exercise_reminders': false,
  };

  // Su içme takibi
  int waterCount = 5;
  final int waterGoal = 8;

  // İlaç takibi
  final List<Map<String, dynamic>> medications = [
    {
      'name': 'Demir Takviyesi',
      'dosage': '1 tablet',
      'frequency': 'Günde 1 kez',
      'time': '20:00',
      'taken_today': true,
      'total_days': 30,
      'completed_days': 15,
    },
    {
      'name': 'B12 Vitamini',
      'dosage': '1 kapsül',
      'frequency': 'Haftada 2 kez',
      'time': '09:00',
      'taken_today': false,
      'total_days': 60,
      'completed_days': 8,
    },
    {
      'name': 'Folik Asit',
      'dosage': '1 tablet',
      'frequency': 'Günde 1 kez',
      'time': '08:00',
      'taken_today': true,
      'total_days': 30,
      'completed_days': 22,
    },
  ];

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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: notification['color'],
            width: 4,
          ),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                              color: const Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                        if (!notification['isRead'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53E3E),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notification['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${notification['date']} • ${notification['time']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Row(
                children: [
                  if (!notification['isRead'])
                    TextButton(
                      onPressed: () => _markAsRead(notification['id']),
                      child: const Text('Okundu', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [Icon(Icons.info, size: 16), SizedBox(width: 8), Text('Detaylar')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [Icon(Icons.delete, size: 16), SizedBox(width: 8), Text('Sil')],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'details') _showNotificationDetails(notification);
                      if (value == 'delete') _deleteNotification(notification['id']);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker() {
    double progress = waterCount / waterGoal;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Günlük Su Takibi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Circular Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$waterCount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ $waterGoal',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: waterCount > 0 ? () => setState(() => waterCount--) : null,
                icon: const Icon(Icons.remove, size: 16),
                label: const Text('Azalt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: waterCount < waterGoal ? () => setState(() => waterCount++) : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Artır'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          
          if (waterCount >= waterGoal) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tebrikler! Günlük su hedefinizi tamamladınız! 🎉',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    double progress = medication['completed_days'] / medication['total_days'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
          width: 1,
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: medication['taken_today'] ? Colors.green.withOpacity(0.1) : const Color(0xFFE53E3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  medication['taken_today'] ? Icons.check : Icons.medication,
                  color: medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    Text(
                      '${medication['dosage']} • ${medication['frequency']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'Saat: ${medication['time']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: medication['taken_today'],
                onChanged: (value) {
                  setState(() {
                    medication['taken_today'] = value;
                    if (value && medication['completed_days'] < medication['total_days']) {
                      medication['completed_days']++;
                    }
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'İlerleme: ${medication['completed_days']}/${medication['total_days']} gün',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  medication['taken_today'] ? Colors.green : const Color(0xFFE53E3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bildirim Ayarları',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 24),
          
          ...reminderSettings.entries.map((entry) {
            String title = _getSettingTitle(entry.key);
            String subtitle = _getSettingSubtitle(entry.key);
            IconData icon = _getSettingIcon(entry.key);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFFE53E3E), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: entry.value,
                    onChanged: (value) {
                      setState(() {
                        reminderSettings[entry.key] = value;
                      });
                    },
                    activeColor: const Color(0xFFE53E3E),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bildirim ayarları kaydedildi!'),
                  backgroundColor: Color(0xFFE53E3E),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Ayarları Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _getSettingTitle(String key) {
    switch (key) {
      case 'test_reminders': return 'Tahlil Hatırlatıcıları';
      case 'critical_alerts': return 'Kritik Değer Uyarıları';
      case 'medication_reminders': return 'İlaç Hatırlatıcıları';
      case 'nutrition_tips': return 'Beslenme Önerileri';
      case 'appointment_reminders': return 'Randevu Hatırlatıcıları';
      case 'water_reminders': return 'Su İçme Hatırlatıcıları';
      case 'exercise_reminders': return 'Egzersiz Hatırlatıcıları';
      default: return key;
    }
  }

  String _getSettingSubtitle(String key) {
    switch (key) {
      case 'test_reminders': return 'Düzenli tahlil zamanlarını hatırlat';
      case 'critical_alerts': return 'Anormal değerler için acil uyarılar';
      case 'medication_reminders': return 'İlaç alma zamanlarını hatırlat';
      case 'nutrition_tips': return 'Günlük beslenme önerileri';
      case 'appointment_reminders': return 'Doktor randevularını hatırlat';
      case 'water_reminders': return 'Su içme zamanlarını hatırlat';
      case 'exercise_reminders': return 'Günlük aktivite hatırlatıcıları';
      default: return '';
    }
  }

  IconData _getSettingIcon(String key) {
    switch (key) {
      case 'test_reminders': return Icons.bloodtype;
      case 'critical_alerts': return Icons.warning;
      case 'medication_reminders': return Icons.medication;
      case 'nutrition_tips': return Icons.restaurant;
      case 'appointment_reminders': return Icons.calendar_today;
      case 'water_reminders': return Icons.water_drop;
      case 'exercise_reminders': return Icons.fitness_center;
      default: return Icons.notifications;
    }
  }

  void _markAsRead(String id) {
    setState(() {
      notifications.firstWhere((n) => n['id'] == id)['isRead'] = true;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((n) => n['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim silindi')),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['description']),
            const SizedBox(height: 16),
            Text(
              'Tarih: ${notification['date']} ${notification['time']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (!notification['isRead'])
            ElevatedButton(
              onPressed: () {
                _markAsRead(notification['id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
              child: const Text('Okundu Olarak İşaretle', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int unreadCount = notifications.where((n) => !n['isRead']).length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Bildirimler & Takip'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53E3E),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Bildirimler'),
            Tab(icon: Icon(Icons.water_drop), text: 'Su Takibi'),
            Tab(icon: Icon(Icons.medication), text: 'İlaçlar'),
            Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bildirimler Tab
          notifications.isEmpty 
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Henüz bildirim yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (unreadCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$unreadCount okunmamış bildirim',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              for (var notification in notifications) {
                                notification['isRead'] = true;
                              }
                            });
                          },
                          child: const Text('Tümünü Okundu İşaretle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...notifications.map((notification) => _buildNotificationCard(notification)).toList(),
                ],
              ),
          
          // Su Takibi Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildWaterTracker(),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '💧 Su İçmenin Faydaları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• Kan dolaşımını iyileştirir\n• Hemoglobin taşınmasına yardımcı olur\n• Demir emilimini artırır\n• Toksinleri vücuttan atar\n• Enerji seviyesini yükseltir',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // İlaçlar Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Günlük İlaç Takibi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                ...medications.map((medication) => _buildMedicationCard(medication)).toList(),
                
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: () {
                    // Yeni ilaç ekleme dialogu
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Yeni İlaç Ekle'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'İlaç Adı',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Dozaj',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Sıklık',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('İlaç başarıyla eklendi!'),
                                  backgroundColor: Color(0xFFE53E3E),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
                            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni İlaç Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          
          // Ayarlar Tab
          _buildSettingsTab(),
        ],
      ),
    );
  }
}
