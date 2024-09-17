import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceChannelPage extends StatefulWidget {
  final String channelName;
  final String? token;

  VoiceChannelPage({required this.channelName, this.token});

  @override
  _VoiceChannelPageState createState() => _VoiceChannelPageState();
}

class _VoiceChannelPageState extends State<VoiceChannelPage> {
  late RtcEngine _engine;
  bool _joined = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // ขอสิทธิ์การเข้าถึงไมโครโฟน
    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required to join the channel.')),
      );
      return;
    }

    // สร้าง Agora Engine
    _engine = createAgoraRtcEngine();
    try {
      await _engine.initialize(RtcEngineContext(appId: 'c5a1364a4bc440749bcce91aafd27a35'));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int uid) {
            setState(() {
              _joined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            setState(() {
              _remoteUid = uid;
            });
          },
          onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
            setState(() {
              _remoteUid = null;
            });
          },
        ),
      );

      // ตรวจสอบชื่อช่อง (channelName) และ token ก่อนเข้าร่วม
      print('Joining channel with name: ${widget.channelName}');
      print('Using token: ${widget.token ?? 'No Token'}');

      // เข้าร่วมช่องด้วย Token และ channelName
      await _engine.joinChannel(
        token: widget.token ?? 'b09e0ddb8c794a67b14f0aa451d9a91f',
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print('Error initializing Agora engine or joining channel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join the channel. Please try again later.')),
      );
    }
  }

  @override
  void dispose() {
    // ปิดการเชื่อมต่อ Agora เมื่อออกจากหน้า
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Channel'),
      ),
      body: Center(
        child: _joined
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Joined the channel'),
                  if (_remoteUid != null)
                    Text('Remote user: $_remoteUid')
                  else
                    Text('Waiting for remote user...'),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
