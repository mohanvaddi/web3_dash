import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pedometer/pedometer.dart';
import 'package:staked_steps/theme.dart';
import 'package:staked_steps/utils/pedometer_utils.dart';
import 'package:staked_steps/utils/common_utils.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.w3mService});

  final W3MService w3mService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _status = '?', _steps = '?';

  @override
  void initState() {
    super.initState();
    initPedometer(
      (StepCount event) {
        setState(() {
          kPrint(event);
          _steps = event.steps.toString();
        });
      },
      (PedestrianStatus event) {
        setState(() {
          kPrint(event);
          _status = event.status;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: CustomColors().LIGHT,
            title: Text(
              'Staked Steps',
              style: GoogleFonts.teko(
                textStyle: TextStyle(
                  color: Colors.green.shade700,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  fontSize: 35.00,
                ),
              ),
            ),
            bottom: const TabBar(
              labelStyle: TextStyle(),
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.history),
                  // text: 'History',
                ),
                Tab(
                  icon: Icon(Icons.image),
                  // text: 'Gallery',
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 250,
                          color: CustomColors().LIGHT,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  // padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                                  child: Center(
                                    child: RichText(
                                      text: const TextSpan(
                                        text:
                                            'This number represents the total steps taken, this is calculated based on the pedometer available.\nIf the text is in green, it means you are currently moving, if It\'s red, it means you\'re idle.',
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  child: const Text('Understood'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                },
                child: Text(
                  _steps,
                  style: GoogleFonts.teko(
                    textStyle: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: _status == 'walking'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log Out',
                onPressed: () {
                  widget.w3mService.disconnect();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wallet Disconnected.'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: const TabBarView(
            children: <Widget>[
              Center(),
              Center(),
            ],
          ),
        ),
      ),
    );
  }
}
