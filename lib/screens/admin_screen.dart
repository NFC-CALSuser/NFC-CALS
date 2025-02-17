import 'package:flutter/material.dart';
import '../nfc_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _tagContent = '';
  bool _isReading = false;
  bool _isWriting = false;
  final TextEditingController _writeController = TextEditingController();

  Future<void> _handleReadTag() async {
    setState(() {
      _isReading = true;
      _tagContent = '';
    });

    bool isAvailable = await NFCService.isAvailable();
    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      setState(() => _isReading = false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hold your device near any NFC tag')),
    );

    try {
      String result = await NFCService.readNFCTag();
      if (!mounted) return;

      setState(() {
        _tagContent = result;
        _isReading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tagContent = 'Error: ${e.toString()}';
        _isReading = false;
      });
    }
  }

  Future<void> _handleWriteTag() async {
    // Show dialog to input content
    String? content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write to Tag'),
        content: TextField(
          controller: _writeController,
          maxLength: 540, // Limit to 540 bytes
          decoration: const InputDecoration(
            hintText: 'Enter content to write',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_writeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter some content')),
                );
                return;
              }
              Navigator.pop(context, _writeController.text);
            },
            child: const Text('Write'),
          ),
        ],
      ),
    );

    if (content == null || content.isEmpty) return;

    setState(() => _isWriting = true);

    bool isAvailable = await NFCService.isAvailable();
    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      setState(() => _isWriting = false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hold your device near the NFC tag')),
    );

    try {
      bool success = await NFCService.writeNFCTag(content);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Content written successfully'
              : 'Failed to write content'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isWriting = false);
    }
  }

  @override
  void dispose() {
    _writeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KSU-Attendance System'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ksu_shieldlogo_colour_rgb.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 45),
              if (_tagContent.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tag Content:\n$_tagContent',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Container(
                width: 300, // Match the width of student dashboard card
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isReading ? null : _handleReadTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.nfc, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              _isReading ? 'Reading...' : 'Read Tag',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isWriting ? null : _handleWriteTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              _isWriting ? 'Writing...' : 'Write Tag',
                              style: TextStyle(color: Colors.white),
                            ),
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
      ),
    );
  }
}
