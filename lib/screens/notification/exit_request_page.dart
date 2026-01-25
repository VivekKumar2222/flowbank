import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../notification/notification-outlook.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';
import '../home/profile.dart';
import '../notification/exit_request_outlook.dart';

class ExitRequestPage extends StatefulWidget {
  final String? dashboardId;

  const ExitRequestPage({super.key, required this.dashboardId});

  @override
  State<ExitRequestPage> createState() => _ExitRequestPageState();
}

class _ExitRequestPageState extends State<ExitRequestPage> {

  
  String? userEmail;
  List<ExitRequest> _exitRequests = [];
  bool _loadingRequests = false;
  

  
  bool _pageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _fetchExitRequests();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      userEmail = prefs.getString('userEmail');
      _pageLoading = true;
    });
    
    

    if (!mounted) return;

  setState(() {
    _pageLoading = false;
  }); 
  }

  Future<void> _fetchExitRequests() async {
  setState(() => _loadingRequests = true);
  

  final response = await ApiService.get(
    "/api/collab/exit-requests-by-dashboard-data?dashboardId=${widget.dashboardId}",
    context,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List list = data['exitRequests'];

    setState(() {
      _exitRequests =
          list.map((e) => ExitRequest.fromJson(e)).toList();
    });
  }

  setState(() => _loadingRequests = false);
}


  

  Widget _loadingScreen() {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.blue.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF217BFF)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Loading content",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF217BFF),
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    if (_pageLoading) {
    return _loadingScreen();
  }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(120),
  child: AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: const Color.fromARGB(0, 255, 255, 255).withOpacity(0.0),
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    titleSpacing: 0,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 18,
              right: 26,
              bottom: 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Exit Requests",
                      style: TextStyle(
                        color: Color(0xFF0179FE),
                        fontSize: 28,
                        fontFamily: "Manrope",
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(
                            "https://i.pravatar.cc/150?img=3",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
),


      body: _loadingRequests
    ? Center(child: CircularProgressIndicator())
    : _exitRequests.isEmpty
        ? Center(
            child: Text(
              "No exit requests",
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _exitRequests.length,
            itemBuilder: (context, index) {
              final req = _exitRequests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExitRequestOutlook(
                  titleText: req.title,
                  bodyText: req.body,
                  requestId: req.id, // ✅ MongoDB _id
                ),
              );
            },
          ),

    );
  }
}

class ExitRequest {
  final String id;
  final String title;
  final String body;

  ExitRequest({
    required this.id,
    required this.title,
    required this.body,
  });

  factory ExitRequest.fromJson(Map<String, dynamic> json) {
    return ExitRequest(
      id: json['_id'],
      title: json['title'],
      body: json['body'],
    );
  }
}