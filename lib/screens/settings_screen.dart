import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/update_service.dart';
import '../services/app_webserver.dart';
import '../utils/responsive_extension.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final Client client;

  const SettingsScreen({super.key, required this.client});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AppWebserver _webserver = AppWebserver();
  String _appVersion = 'Loading...';
  String _updateStatus = '';
  bool _isCheckingUpdate = false;
  bool _isServerToggling = false;
  bool _autoStartOnLogin = true;
  static const MethodChannel _nativeNotificationChannel = MethodChannel('com.example.tv/notifications');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadAppVersion();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoStartOnLogin = prefs.getBool('autostart_on_login') ?? true;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _handleCheckForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = 'Checking GitHub releases...';
    });

    await UpdateService.checkForUpdates(
      onStatusUpdate: (status) {
        if (mounted) {
          setState(() {
            _updateStatus = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  Future<void> _handleToggleServer(bool value) async {
    setState(() => _isServerToggling = true);
    try {
      if (value) {
        await _webserver.start();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server started on port 8086!')),
          );
        }
      } else {
        await _webserver.stop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server stopped.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isServerToggling = false;
        });
      }
    }
  }

  Future<void> _toggleAutoStartOnLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autostart_on_login', value);
    setState(() {
      _autoStartOnLogin = value;
    });
  }

  Future<void> _requestOverlayPermission() async {
    try {
      await _nativeNotificationChannel.invokeMethod('openOverlaySettings');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening overlay permissions settings...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open settings: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tvMode = context.isTv;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: tvMode ? 24 : 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tvMode ? 64.0 : 24.0,
          vertical: tvMode ? 24.0 : 16.0,
        ),
        child: ListView(
          children: [
            Text(
              'Application Settings',
              style: TextStyle(
                fontSize: tvMode ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: tvMode ? 24 : 16),
            
            // 1. Web Server Control Tile
            Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  
                  final String subtitleText = _webserver.isRunning 
                      ? 'Running on port ${_webserver.port} (0.0.0.0)' 
                      : (_webserver.lastError != null 
                          ? 'Error: ${_webserver.lastError}' 
                          : 'Server is currently offline');

                  return Card(
                    color: hasFocus ? const Color(0xFF03DAC6) : const Color(0xFF2C2C2C),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tvMode ? 24.0 : 16.0,
                        vertical: tvMode ? 8.0 : 4.0,
                      ),
                      title: Text(
                        'Local Web Control Panel (Port 8086)',
                        style: TextStyle(
                          color: hasFocus ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.bodyTextSize,
                        ),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(
                          color: hasFocus 
                              ? Colors.black54 
                              : (_webserver.lastError != null ? Colors.redAccent : Colors.white70),
                          fontSize: context.bodyTextSize - 2,
                        ),
                      ),
                      secondary: _isServerToggling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.dns,
                              color: hasFocus ? Colors.black : const Color(0xFF03DAC6),
                              size: tvMode ? 32 : 24,
                            ),
                      value: _webserver.isRunning,
                      onChanged: _isServerToggling 
                          ? null 
                          : (bool value) => _handleToggleServer(value),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: tvMode ? 16 : 12),

            // 2. Start on Login Toggle Tile
            Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return Card(
                    color: hasFocus ? const Color(0xFF03DAC6) : const Color(0xFF2C2C2C),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tvMode ? 24.0 : 16.0,
                        vertical: tvMode ? 8.0 : 4.0,
                      ),
                      title: Text(
                        'Start Web Server on App Login',
                        style: TextStyle(
                          color: hasFocus ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.bodyTextSize,
                        ),
                      ),
                      subtitle: Text(
                        _autoStartOnLogin 
                            ? 'Automatically boots port 8086 upon login' 
                            : 'Manual start only',
                        style: TextStyle(
                          color: hasFocus ? Colors.black54 : Colors.white70,
                          fontSize: context.bodyTextSize - 2,
                        ),
                      ),
                      secondary: Icon(
                        Icons.login,
                        color: hasFocus ? Colors.black : const Color(0xFF03DAC6),
                        size: tvMode ? 32 : 24,
                      ),
                      value: _autoStartOnLogin,
                      onChanged: (val) => _toggleAutoStartOnLogin(val),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: tvMode ? 16 : 12),

            // 3. Display Over Other Apps Permission Tile (Overlay Fallback)
            Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return Card(
                    color: hasFocus ? const Color(0xFF03DAC6) : const Color(0xFF2C2C2C),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tvMode ? 24.0 : 16.0,
                        vertical: tvMode ? 8.0 : 4.0,
                      ),
                      title: Text(
                        'Display Over Other Apps Permission',
                        style: TextStyle(
                          color: hasFocus ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.bodyTextSize,
                        ),
                      ),
                      subtitle: Text(
                        'Grant system overlay permission for fallback popups',
                        style: TextStyle(
                          color: hasFocus ? Colors.black54 : Colors.white70,
                          fontSize: context.bodyTextSize - 2,
                        ),
                      ),
                      trailing: Icon(
                        Icons.layers,
                        color: hasFocus ? Colors.black : const Color(0xFF03DAC6),
                        size: tvMode ? 32 : 24,
                      ),
                      onTap: _requestOverlayPermission,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: tvMode ? 16 : 12),

            // 4. Check for Updates Tile
            Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return Card(
                    color: hasFocus ? const Color(0xFF03DAC6) : const Color(0xFF2C2C2C),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tvMode ? 24.0 : 16.0,
                        vertical: tvMode ? 8.0 : 4.0,
                      ),
                      title: Text(
                        _isCheckingUpdate ? 'Updating...' : 'Check for Updates',
                        style: TextStyle(
                          color: hasFocus ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.bodyTextSize,
                        ),
                      ),
                      subtitle: Text(
                        _updateStatus.isNotEmpty ? _updateStatus : 'Current version: $_appVersion',
                        style: TextStyle(
                          color: hasFocus ? Colors.black54 : Colors.white70,
                          fontSize: context.bodyTextSize - 2,
                        ),
                      ),
                      trailing: _isCheckingUpdate
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.system_update,
                              color: hasFocus ? Colors.black : const Color(0xFF03DAC6),
                              size: tvMode ? 32 : 24,
                            ),
                      onTap: _isCheckingUpdate ? null : _handleCheckForUpdates,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: tvMode ? 16 : 12),

            // 5. Logout / Sign Out Tile
            Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return Card(
                    color: hasFocus ? Colors.redAccent : const Color(0xFF2C2C2C),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tvMode ? 24.0 : 16.0,
                        vertical: tvMode ? 8.0 : 4.0,
                      ),
                      title: Text(
                        'Log Out',
                        style: TextStyle(
                          color: hasFocus ? Colors.white : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: context.bodyTextSize,
                        ),
                      ),
                      subtitle: Text(
                        'Disconnect session from homeserver (${widget.client.userID ?? ""})',
                        style: TextStyle(
                          color: hasFocus ? Colors.white70 : Colors.white54,
                          fontSize: context.bodyTextSize - 2,
                        ),
                      ),
                      trailing: Icon(
                        Icons.logout,
                        color: hasFocus ? Colors.white : Colors.redAccent,
                        size: tvMode ? 32 : 24,
                      ),
                      onTap: () async {
                        await _webserver.stop();
                        await widget.client.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen(client: widget.client)),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
