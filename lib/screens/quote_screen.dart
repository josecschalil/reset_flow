import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  String _quote = "The secret of getting ahead is getting started.";
  String _author = "Mark Twain";

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quote = prefs.getString('custom_quote_text') ?? _quote;
      _author = prefs.getString('custom_quote_author') ?? _author;
    });
  }

  Future<void> _saveQuote(String quote, String author) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_quote_text', quote);
    await prefs.setString('custom_quote_author', author);
    setState(() {
      _quote = quote;
      _author = author;
    });
  }

  void _showEditDialog() {
    final quoteCtrl = TextEditingController(text: _quote);
    final authorCtrl = TextEditingController(text: _author);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Motivation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quoteCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Quote',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF1E3A5F), width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorCtrl,
                decoration: InputDecoration(
                  labelText: 'Author / Note',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF1E3A5F), width: 1.5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveQuote(quoteCtrl.text.trim(), authorCtrl.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // A deeply elegant atmospheric background
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient Base
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF14202E), // Deep navy
                    Color(0xFF0E1825), // Very dark slate
                  ],
                ),
              ),
            ),

            // Glowing Brand Orbs (Animated/Ambient feel)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E3A5F).withOpacity(0.4),
                      const Color(0xFF1E3A5F).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -200,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A6A94).withOpacity(0.25),
                      const Color(0xFF4A6A94).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Glassmorphism Blur Layer
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),

            // Content Layer
            SafeArea(
              child: Column(
                children: [
                  // Top Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(), // Empty space to push edit button right
                        // Edit Button
                        IconButton(
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.more_vert_rounded),
                          color: Colors.white.withOpacity(0.8),
                          splashRadius: 24,
                        )
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quote Icon
                          Icon(
                            Icons.format_quote_rounded,
                            size: 64,
                            color: const Color(0xFF4A6A94).withOpacity(0.9),
                          ),
                          const SizedBox(height: 16),

                          // Main Quote Text
                          Text(
                            _quote,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Author container
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A6A94),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _author.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60), // Visual balance
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
