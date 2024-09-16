import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cassandra_native/theme/theme_provider.dart';
import 'package:cassandra_native/data/app_data.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InfoItem extends StatefulWidget {
  const InfoItem({super.key});

  @override
  State<InfoItem> createState() => _InfoItemState();
}

class _InfoItemState extends State<InfoItem> {
  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: 200,
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Find the latest informations and updates on ',
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'GitHub',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _launchURL('https://github.com/EinEinfach/CaSSAndRA');
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            Text(
              'App version: $appVersion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Required server version: $requiredServerVersion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "dark mode",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                CupertinoSwitch(
                  value: Provider.of<ThemeProvider>(context, listen: false)
                      .isDarkMode,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme();
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
