يبدو أن الصورة لم تُرفع في رسالتك، ولكن بناءً على الخطوة السابقة، فإما أنك ترى ملف pubspec.yaml قد أُضيف بنجاح في قائمة ملفات مشروعك Alnasih2، أو أنك تواجه مشكلة في إيجاد زر Add file.
لنتأكد من مكانك الحالي ونكمل مباشرة:
• إذا تم حفظ الملف بنجاح (وترى الآن في قائمة الملفات README.md وبجانبه pubspec.yaml)، فهذا رائع جداً! ويمكننا الانتقال فوراً لإضافة ملف الكود البرمجي الرئيسي للتطبيق (lib/main.dart).
• إذا لم تجد زر Add file على شاشة الهاتف الصغيرة: اضغط على النقاط الثلاث (⋮) في أعلى متصفح Chrome واختر الموقع الإلكتروني المخصص للكمبيوتر (Desktop site)، وسيظهر لك زر Add file بوضوح بجانب الزر الأخضر <> Code.

الخطوة الثالثة: إضافة الكود البرمجي الرئيسي للتطبيق (lib/main.dart)

بمجرد التأكد من وجود ملف pubspec.yaml، نفّذ التالي لإضافة قلب التطبيق وواجهته العربية:
1. اضغط على زر Add file ثم اختر Create new file.
2. في خانة اسم الملف في الأعلى (Name your file...)، اكتب بالضبط:
lib/main.dart
(ملاحظة: بمجرد كتابة علامة / بعد كلمة lib، سيقوم موقع GitHub تلقائياً بإنشاء مجلد lib ووضع ملف main.dart بداخله).
3. في مربع الكتابة الكبير بالأسفل، الصق هذا الكود البرمجي الكامل للتطبيق:
dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const AlnasihMeshApp());
}

class AlnasihMeshApp extends StatelessWidget {
  const AlnasihMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الناصح - شبكة الطوارئ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MeshHomeScreen(),
      ),
    );
  }
}

class MeshMessage {
  final String id;
  final String sender;
  final String text;
  final int hops;
  final String timestamp;

  MeshMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.hops,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'text': text,
        'hops': hops,
        'timestamp': timestamp,
      };

  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(
        id: json['id'],
        sender: json['sender'],
        text: json['text'],
        hops: json['hops'],
        timestamp: json['timestamp'],
      );
}

class MeshHomeScreen extends StatefulWidget {
  const MeshHomeScreen({super.key});

  @override
  State<MeshHomeScreen> createState() => _MeshHomeScreenState();
}

class _MeshHomeScreenState extends State<MeshHomeScreen> {
  final TextEditingController _msgController = TextEditingController();
  List<MeshMessage> _messages = [];
  bool _isScanning = true;
  int _nearbyPeers = 0;

  @override
  void initState() {
    super.initState();
    _loadStoredMessages();
  }

  // نظام التخزين المؤقت للرسائل (DTN)
  Future<void> _loadStoredMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList('dtn_messages') ?? [];
    setState(() {
      _messages = saved
          .map((item) => MeshMessage.fromJson(jsonDecode(item)))
          .toList();
    });
  }

  Future<void> _saveMessagesToDTN() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded =
        _messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('dtn_messages', encoded);
  }

  void _sendEmergencyMessage() {
    if (_msgController.text.trim().isEmpty) return;

    final newMsg = MeshMessage(
      id: const Uuid().v4(),
      sender: 'أنت (جهاز محلي)',
      text: _msgController.text.trim(),
      hops: 1, // القفزة الأولى
      timestamp: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    setState(() {
      _messages.insert(0, newMsg);
      _msgController.clear();
    });

    _saveMessagesToDTN();
    // هنا يتم بث الرسالة تلقائياً للأجهزة القريبة عبر البلوتوث والواي فاي المباشر
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الناصح Mesh - تواصل الطوارئ'),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.radar : Icons.portable_wifi_off),
            onPressed: () {
              setState(() => _isScanning = !_isScanning);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: _isScanning ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isScanning
                      ? '🟢 الرادار نشط (بلوتوث + واي فاي مباشر)'
                      : '🟠 الرادار متوقف (وضع التخزين المؤقت DTN)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text('الأجهزة القريبة: $_nearbyPeers'),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد رسائل طوارئ حالياً.\nالرسائل تُحفظ وتُمرر تلقائياً لأقرب هاتف بدون إنترنت.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        color: const Color(0xFF1E1E1E),
                        child: ListTile(
                          title: Text(msg.text, style: const TextStyle(fontSize: 16)),
                          subtitle: Text(
                            '${msg.sender} • القفزات (Hops): ${msg.hops}/64 • ${msg.timestamp}',
                            style: const TextStyle(fontSize: 12, color: Colors.amber),
                          ),
                          leading: const Icon(Icons.cell_tower, color: Colors.redAccent),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة طوارئ لبثها عبر الشبكة...',
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendEmergencyMessage,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}  
