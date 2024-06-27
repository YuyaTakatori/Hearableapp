import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'nine_axis_sensor.dart';
import 'dart:async';

class DozePreventionApp extends StatefulWidget {
  @override
  _DozePreventionAppState createState() => _DozePreventionAppState();
}

class _DozePreventionAppState extends State<DozePreventionApp> {
  final NineAxisSensor _sensor = NineAxisSensor();
  bool _isMonitoring = false;
  int _negativeCount = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _sensor.addListener(_sensorDataReceived);
  }

  @override
  void dispose() {
    _sensor.removeListener(_sensorDataReceived);
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sensorDataReceived() {
    String result = _sensor.getResultString();
    List<String> accValues = result.split('\n');
    String accXStr = accValues.firstWhere((element) => element.startsWith('accX:')).split(':')[1].split(',').last;
    String accYStr = accValues.firstWhere((element) => element.startsWith('accY:')).split(':')[1].split(',').last;
    
    int accX = int.parse(accXStr, radix: 16);
    int accY = int.parse(accYStr, radix: 16);

    if (accX < 0 && accY < 0) {
      if (_timer == null) {
        _startTimer();
      } else if (_isMonitoring) {
        _negativeCount++;
      }
    }
  }

  void _startTimer() {
    setState(() {
      _isMonitoring = true;
      _negativeCount = 0;
    });

    _timer = Timer(Duration(seconds: 30), () {
      _isMonitoring = false;
      if (_negativeCount >= 3 && _negativeCount <= 10) {
        _playWarning();
      } else {
        _reset();
      }
    });
  }

  void _reset() {
    setState(() {
      _isMonitoring = false;
      _negativeCount = 0;
      _timer = null;
    });
  }

  void _playWarning() async {
    await _audioPlayer.play(AssetSource('assets/Warning.mp3'));
  }

  void _stopMonitoring() {
    _audioPlayer.stop();
    _reset();
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      _stopMonitoring();
    } else {
      _sensor.addNineAxisSensorNotificationListener();
      setState(() {
        _isMonitoring = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Doze Prevention'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _toggleMonitoring,
                child: Text(_isMonitoring ? 'Stop' : 'Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() => runApp(DozePreventionApp());
