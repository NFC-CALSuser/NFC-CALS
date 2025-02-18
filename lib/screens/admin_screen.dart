import 'package:flutter/material.dart';
import '../nfc_service.dart';
import 'login_screen.dart';

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

  void _handleSignOut(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

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
    String? content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write to Tag'),
        content: TextField(
          controller: _writeController,
          maxLength: 540,
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
        title: const Text('Admin NFC Management'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleSignOut(context),
        ),
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
              SizedBox(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isReading ? null : _handleReadTag,
                        icon: const Icon(Icons.nfc, color: Colors.white),
                        label: Text(
                          _isReading ? 'Reading...' : 'Read Tag',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _handleWriteTag,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          _isWriting ? 'Writing...' : 'Write Tag',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
