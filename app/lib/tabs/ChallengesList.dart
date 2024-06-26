import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:staked_steps/constants.dart';
import 'package:staked_steps/structs.dart';
import 'package:staked_steps/utils/api_utils.dart';
import 'package:staked_steps/utils/common_utils.dart';
import 'package:staked_steps/utils/transactions.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChallengesList extends StatefulWidget {
  const ChallengesList({
    super.key,
    required this.w3mService,
    required this.challengesType,
  });

  final W3MService w3mService;
  final ChallengesType challengesType;
  @override
  State<ChallengesList> createState() => _ChallengesListState();
}

class _ChallengesListState extends State<ChallengesList> {
  late Future<void> futureChallenges;
  late List<ChallengeData> challengesList;

  int _steps = 0;

  Future<void> _initChallenges() async {
    switch (widget.challengesType) {
      case ChallengesType.PUBLIC:
        {
          final challenges =
              await fetchPublicChallenges(widget.w3mService, currentChain);
          challengesList = challenges;
        }
        break;

      case ChallengesType.USER_ONGOING:
        {
          final challenges = await fetchUserChallenges(
              widget.w3mService, currentChain, ChallengesFilter.ONGOING);
          challengesList = challenges;
        }
        break;

      case ChallengesType.USER_COMPLETED:
        {
          final challenges = await fetchUserChallenges(
              widget.w3mService, currentChain, ChallengesFilter.COMPLETED);
          challengesList = challenges;
        }
        break;
    }
  }

  Future<void> _refreshChallenges() async {
    await fetchSteps();

    switch (widget.challengesType) {
      case ChallengesType.PUBLIC:
        {
          final challenges =
              await fetchPublicChallenges(widget.w3mService, currentChain);
          setState(() {
            challengesList = challenges;
          });
        }
        break;

      case ChallengesType.USER_ONGOING:
        {
          final challenges = await fetchUserChallenges(
              widget.w3mService, currentChain, ChallengesFilter.ONGOING);
          setState(() {
            challengesList = challenges;
          });
        }
        break;
      case ChallengesType.USER_COMPLETED:
        {
          final challenges = await fetchUserChallenges(
              widget.w3mService, currentChain, ChallengesFilter.COMPLETED);
          setState(() {
            challengesList = challenges;
          });
        }
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    kPrint('updating data');
    futureChallenges = _initChallenges();
    Health().configure(useHealthConnectIfAvailable: true);
    authorize();
    fetchSteps();
  }

  static final types = [
    HealthDataType.STEPS,
    // HealthDataType.HEIGHT,
  ];

  List<HealthDataAccess> get permissions =>
      types.map((e) => HealthDataAccess.READ).toList();

  /// Authorize, i.e. get permissions to access relevant health data.
  Future<void> authorize() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if we have health permissions
    bool? hasPermissions =
        await Health().hasPermissions(types, permissions: permissions);

    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      // requesting access to the data types before reading them
      try {
        authorized = await Health()
            .requestAuthorization(types, permissions: permissions);
      } catch (error) {
        debugPrint("Exception in authorize: $error");
      }
    }
    debugPrint('Healthkit authorized: $authorized');

    setState(() => {});
  }

  Future<int?> fetchSteps() async {
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    int? steps = await Health().getTotalStepsInInterval(todayMidnight, now);

    setState(() {
      _steps = steps ?? 0;
    });

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    int currentEpochSeconds =
        DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

    return FutureBuilder<void>(
      future: futureChallenges,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('${snapshot.error}');

        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            {
              return const CircularProgressIndicator();
            }
          case ConnectionState.done:
            {
              return RefreshIndicator(
                onRefresh: _refreshChallenges,
                child: ListView.separated(
                  // padding: const EdgeInsets.all(5),
                  itemCount: challengesList.length,
                  itemBuilder: (BuildContext context, int index) {
                    ChallengeData challenge = challengesList[index];
                    final remainingSteps = challenge.goal - _steps;

                    final percentage = _steps / challenge.goal;

                    return ListTile(
                      tileColor: Colors.green.shade50,
                      title: Text(
                        challenge.challengeName,
                        style: GoogleFonts.teko(
                          textStyle: const TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                      subtitle: widget.challengesType ==
                              ChallengesType.USER_ONGOING
                          ? Text(
                              remainingSteps > 0
                                  ? '$remainingSteps steps left to complete today\'s goal'
                                  : 'You\'ve reached your goal for today',
                              style: GoogleFonts.teko(
                                textStyle: const TextStyle(fontSize: 21.5),
                              ),
                            )
                          : widget.challengesType ==
                                  ChallengesType.USER_COMPLETED
                              ? Text(
                                  'Challenge completed on \n ${formatReadableDateTime(DateTime.fromMillisecondsSinceEpoch(int.parse('${challenge.endDate}000')))}',
                                  style: GoogleFonts.teko(
                                    textStyle: const TextStyle(fontSize: 21.5),
                                  ),
                                )
                              // PUBLIC
                              : Text(
                                  '${challenge.participantsCount} out of ${challenge.participantsLimit} slots filled',
                                  style: GoogleFonts.teko(
                                    textStyle: const TextStyle(fontSize: 22),
                                  ),
                                ),
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${toTitleCase(challenge.visibility)} ${challenge.challengeId}',
                            style: GoogleFonts.teko(
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: challenge.visibility == 'public'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${getDoubleFromBigIntETH(BigInt.from(num.parse(challenge.stakedAmount)))} $token',
                            style: GoogleFonts.teko(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      enableFeedback: true,
                      trailing: widget.challengesType ==
                              ChallengesType.USER_ONGOING
                          ? percentage < 1
                              ? TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                      begin: 0.0, end: percentage),
                                  duration: const Duration(milliseconds: 800),
                                  builder: (context, value, _) {
                                    return CircularProgressIndicator(
                                      backgroundColor: Colors.green.shade100,
                                      strokeCap: StrokeCap.round,
                                      strokeWidth: 5.5,
                                      value: value,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green.shade700,
                                      ),
                                    );
                                  },
                                )
                              : Visibility(
                                  visible: currentEpochSeconds <
                                      (int.parse(challenge.lastCheckInDay) *
                                          86400),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        Future<http.Response> dailyCheckIn(
                                            String userAddress,
                                            String challengeId,
                                            String stepCount) {
                                          return http.post(
                                            Uri.parse(
                                                '$apiUrl/challenge/dailyCheckIn'),
                                            headers: <String, String>{
                                              'Content-Type':
                                                  'application/json; charset=UTF-8',
                                            },
                                            body: jsonEncode(
                                              <String, String>{
                                                'userAddress': userAddress,
                                                "challengeId": challengeId,
                                                "stepCount": stepCount
                                              },
                                            ),
                                          );
                                        }

                                        final resp = await dailyCheckIn(
                                            widget.w3mService.session!.address!,
                                            challenge.challengeId,
                                            _steps.toString());

                                        if (resp.statusCode == 200) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(resp.body),
                                            ),
                                          );
                                        } else if (resp.statusCode == 500) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(resp.body),
                                            ),
                                          );
                                        }
                                      } catch (err) {
                                        print(err);
                                      }
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        CustomColors().PRIMARY,
                                      ),
                                      shape: MaterialStateProperty.all<
                                          OutlinedBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          // side: BorderSide(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'CheckIn',
                                      style: GoogleFonts.teko(
                                        textStyle: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                          : widget.challengesType == ChallengesType.PUBLIC
                              ? ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CustomColors().PRIMARY,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        // side: BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await customWriteContract(
                                      widget.w3mService,
                                      'joinPublicChallenge',
                                      [
                                        BigInt.from(
                                          num.parse(challenge.challengeId),
                                        ),
                                      ],
                                      EtherAmount.fromBigInt(
                                        EtherUnit.wei,
                                        BigInt.parse(challenge.stakedAmount),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Stake & Join',
                                    style: GoogleFonts.teko(
                                      textStyle: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () {},
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CustomColors().PRIMARY,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        // side: BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'View stats',
                                    style: GoogleFonts.teko(
                                      textStyle: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                      onTap: () {
                        kPrint('clicked');
                      },
                    );
                  },
                  separatorBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    return const Divider(height: 2);
                  },
                ),
              );
            }
        }
      },
    );
  }
}
