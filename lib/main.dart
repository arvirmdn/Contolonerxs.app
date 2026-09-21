import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nyalain notifikasi media sistem (lockscreen/notification shade) buat
  // player musik di MusicScreen — sekali dipanggil di sini, otomatis kepakai
  // tiap kali AudioSource yang dimuat punya tag MediaItem.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.arvirmdn.contolonerxs.channel.audio',
    androidNotificationChannelName: 'Pemutaran Musik',
    androidNotificationOngoing: true,
  );
  runApp(const ContolonerxsApp());
}
