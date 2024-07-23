import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final videoUrl =
        'https://storage.googleapis.com/bb-videos/Demo3%20-%20Made%20with%20Clipchamp.mp4';

    try {
      _controller = VideoPlayerController.network(videoUrl)
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
    } catch (e) {
      print('Error loading video: $e');
    }
  }

  Future<void> _downloadVideo() async {
    final videoUrl =
        'https://storage.googleapis.com/bb-videos/Demo3%20-%20Made%20with%20Clipchamp.mp4';
    final dio = Dio();

    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final mediaPath = Directory('${directory.path}/Android/media');
        if (!await mediaPath.exists()) {
          await mediaPath.create(recursive: true);
        }
        final filePath = '${mediaPath.path}/Demo3.mp4';

        await dio.download(videoUrl, filePath,
            onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video downloaded to $filePath'),
            duration: Duration(seconds: 20),
          ),
        );
        setState(() {
          _downloadProgress = 0.0;
        });
      } else {
        throw Exception('External storage directory not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download video: $e')),
      );
      setState(() {
        _downloadProgress = 0.0;
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
      _isPlaying = !_isPlaying;
    });
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
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
        title: Text('Video Player'),
      ),
      body: Center(
        child: _initialized
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
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: _playPauseVideo,
                      ),
                      Text(
                        '${_position.toString().split('.').first} / ${_duration.toString().split('.').first}',
                      ),
                      IconButton(
                        icon: Icon(Icons.download),
                        onPressed: _downloadVideo,
                      ),
                    ],
                  ),
                  if (_downloadProgress > 0)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress,
                          ),
                          Text('Downloading...'),
                        ],
                      ),
                    ),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
