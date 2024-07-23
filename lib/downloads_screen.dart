import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class DownloadsScreen extends StatefulWidget {
  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _checkFileAndLoadVideo();
  }

  Future<void> _checkFileAndLoadVideo() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/Demo3.mp4';
    final file = File(filePath);

    if (await file.exists()) {
      setState(() {
        _fileExists = true;
      });
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {
            _initialized = true;
            _duration = _controller.value.duration;
          });
          _controller.addListener(() {
            if (_controller.value.isPlaying) {
              setState(() {
                _position = _controller.value.position;
              });
            }
          });
        }).catchError((error) {
          print('Error initializing video: $error');
        });
    } else {
      setState(() {
        _fileExists = false;
      });
    }
  }

  void _playPauseVideo() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downloaded Videos'),
      ),
      body: Center(
        child: !_fileExists
            ? Text('No files downloaded.')
            : _initialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.all(8.0),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            onPressed: _playPauseVideo,
                          ),
                          Text(
                            '${_position.toString().split('.').first} / ${_duration.toString().split('.').first}',
                          ),
                        ],
                      ),
                    ],
                  )
                : CircularProgressIndicator(),
      ),
    );
  }
}
