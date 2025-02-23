import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PreparednessScreen extends StatefulWidget {
  final String location;
  const PreparednessScreen({Key? key, required this.location}) : super(key: key);

  @override
  State<PreparednessScreen> createState() => _PreparednessScreenState();
}

class _PreparednessScreenState extends State<PreparednessScreen> {
  late List<DisasterInfo> disasters;

  @override
  void initState() {
    super.initState();
    disasters = getDisastersForLocation(widget.location);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: ListView.builder(
        itemCount: disasters.length,
        itemBuilder: (context, index) {
          return DisasterCard(
            disaster: disasters[index],
            index: index,
          ).animate()
            .fadeIn(duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100 * index))
            .slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Color _getRiskColor(String riskLevel, bool isDarkMode) {
    if (isDarkMode) {
      switch (riskLevel) {
        case 'High':
          return Colors.red[900]!;
        case 'Medium':
          return Colors.amber[900]!;
        case 'Low':
          return Colors.green[900]!;
        default:
          return Colors.grey[900]!;
      }
    } else {
      switch (riskLevel) {
        case 'High':
          return Colors.red[100]!;
        case 'Medium':
          return Colors.amber[100]!;
        case 'Low':
          return Colors.green[100]!;
        default:
          return Colors.grey[100]!;
      }
    }
  }

  List<DisasterInfo> getDisastersForLocation(String location) {
    switch (location) {
      case "Thrissur":
        return [
          DisasterInfo(
            type: 'Floods',
            riskLevel: 'High',
            description: 'Thrissur is prone to flooding during monsoon season, particularly in low-lying areas and near rivers.',
            preparednessPoints: [
              'Keep emergency kit with essential supplies',
              'Know your evacuation routes to higher ground',
              'Store important documents in waterproof containers',
              'Keep emergency contact numbers handy',
              'Monitor local weather updates regularly',
            ],
            tips: [
              'Move to higher ground immediately when warned',
              'Avoid walking through moving water',
              'Don\'t drive through flooded areas',
              'Follow instructions from local authorities',
            ],
            videoIds: ['8pdeaaA9Md8', 'lEf5d3X-fbA'],
          ),
          DisasterInfo(
            type: 'Landslides',
            riskLevel: 'Medium',
            description: 'Risk of landslides in hilly areas, especially during heavy rainfall.',
            preparednessPoints: [
              'Identify safe zones in your area',
              'Watch for warning signs like cracks in ground',
              'Have an emergency evacuation plan',
              'Keep emergency supplies ready',
            ],
            tips: [
              'Evacuate immediately if warned',
              'Move to pre-identified safe locations',
              'Stay alert during heavy rains',
            ],
            videoIds: ['9j_StYqR_Pg', 'zwmdJQu8m-c'],
          ),
          DisasterInfo(
            type: 'Lightning',
            riskLevel: 'High',
            description: 'Frequent lightning strikes during pre-monsoon and monsoon seasons.',
            preparednessPoints: [
              'Install lightning arresters',
              'Unplug electronic devices during storms',
              'Identify safe indoor locations',
              'Monitor weather warnings',
            ],
            tips: [
              'Stay indoors during thunderstorms',
              'Avoid open areas and tall objects',
              'Stay away from windows and electrical equipment',
            ],
            videoIds: ['eNxDgd3D_bU', 'p6k5gGVPNnA'],
          ),
          DisasterInfo(
            type: 'Earthquakes',
            riskLevel: 'Low',
            description: 'Occasional mild seismic activity in the region.',
            preparednessPoints: [
              'Secure heavy furniture to walls',
              'Identify safe spots in each room',
              'Keep emergency supplies accessible',
              'Know how to shut off utilities',
            ],
            tips: [
              'Drop, cover, and hold on',
              'Stay away from windows',
              'Be prepared for aftershocks',
            ],
            videoIds: ['r5EbbrVXoQw', 'MllUVQM3KVk'],
          ),
          DisasterInfo(
            type: 'Cyclones',
            riskLevel: 'Medium',
            description: 'Seasonal cyclonic activity affecting coastal areas.',
            preparednessPoints: [
              'Strengthen house structure',
              'Keep emergency supplies ready',
              'Know evacuation routes',
              'Have battery-powered radio',
            ],
            tips: [
              'Stay updated with weather alerts',
              'Secure loose objects outside',
              'Follow evacuation orders promptly',
            ],
            videoIds: ['HDJSj-cpRnM', 'XqRyhpg-mKU'],
          ),
          DisasterInfo(
            type: 'Disease Outbreaks',
            riskLevel: 'Medium',
            description: 'Risk of waterborne diseases during floods and epidemics.',
            preparednessPoints: [
              'Maintain hygiene supplies',
              'Know local health facilities',
              'Keep vaccination records updated',
              'Store essential medicines',
            ],
            tips: [
              'Practice good hygiene',
              'Boil drinking water',
              'Seek medical help promptly',
            ],
            videoIds: ['P_VjnxHUoDY', 'xuJ9uz5ax80'],
          ),
        ];

      case "Palakkad":
        return [
          DisasterInfo(
            type: 'Heat Waves',
            riskLevel: 'High',
            description: 'Palakkad is known for extreme heat conditions due to the Palakkad Gap.',
            preparednessPoints: [
              'Install proper ventilation systems',
              'Keep hydration supplies ready',
              'Have backup power for cooling',
              'Create cool zones in home',
            ],
            tips: [
              'Stay hydrated',
              'Avoid outdoor activities during peak hours',
              'Use light-colored, loose clothing',
              'Check on vulnerable neighbors',
            ],
            videoIds: ['ter31IGeXzs', 'https://youtu.be/UBi2tvebStI?si=g5pY-QnOLult9bB5'],
          ),
          DisasterInfo(
            type: 'Drought',
            riskLevel: 'High',
            description: 'Regular drought conditions affecting agriculture and water supply.',
            preparednessPoints: [
              'Implement water conservation methods',
              'Install rainwater harvesting systems',
              'Maintain water storage facilities',
              'Plan for alternative water sources',
            ],
            tips: [
              'Use water efficiently',
              'Collect and store rainwater',
              'Follow water usage restrictions',
            ],
            videoIds: ['7CvUR_PissM', 'XGRN0E1fBxw'],
          ),
          DisasterInfo(
            type: 'Forest Fires',
            riskLevel: 'Medium',
            description: 'Risk of forest fires during summer months.',
            preparednessPoints: [
              'Create fire breaks around properties',
              'Keep emergency supplies ready',
              'Have evacuation plan ready',
              'Maintain communication devices',
            ],
            tips: [
              'Report fires immediately',
              'Follow evacuation orders promptly',
              'Keep surrounding areas clear of dry vegetation',
            ],
            videoIds: ['ypbPzX5eQss', 'VCbLko6Aqa8'],
          ),
          DisasterInfo(
            type: 'Agricultural Pests',
            riskLevel: 'Medium',
            description: 'Seasonal pest infestations affecting crops.',
            preparednessPoints: [
              'Monitor crop health regularly',
              'Maintain pest control supplies',
              'Have crop insurance',
              'Know agricultural experts contacts',
            ],
            tips: [
              'Implement integrated pest management',
              'Use appropriate pesticides safely',
              'Report unusual pest activity',
            ],
            videoIds: ['X5-ZZr7Ctic', 'oStxdVKhNLo'],
          ),
          DisasterInfo(
            type: 'Wind Storms',
            riskLevel: 'Medium',
            description: 'Strong winds through Palakkad Gap causing damage.',
            preparednessPoints: [
              'Secure loose structures',
              'Trim weak tree branches',
              'Install wind barriers',
              'Maintain emergency supplies',
            ],
            tips: [
              'Stay indoors during storms',
              'Keep away from windows',
              'Park vehicles in safe areas',
            ],
            videoIds: ['TqZ3M7xh8jM', '8qOJKT-S5Ns'],
          ),
          DisasterInfo(
            type: 'Soil Erosion',
            riskLevel: 'High',
            description: 'Severe soil erosion affecting agricultural lands.',
            preparednessPoints: [
              'Implement soil conservation methods',
              'Plant soil-binding vegetation',
              'Build retention walls',
              'Monitor soil health',
            ],
            tips: [
              'Practice contour farming',
              'Maintain ground cover',
              'Report severe erosion',
            ],
            videoIds: ['im4HVXMGI68', 'BoSUEIkK_Y4'],
          ),
        ];

      case "Eranakulam":
        return [
          DisasterInfo(
            type: 'Urban Floods',
            riskLevel: 'High',
            description: 'Urban flooding due to heavy rainfall and poor drainage.',
            preparednessPoints: [
              'Know your building\'s flood risk',
              'Keep emergency supplies at higher levels',
              'Have backup power arrangements',
              'Know evacuation routes and safe zones',
            ],
            tips: [
              'Move vehicles to higher ground',
              'Avoid underground parking during heavy rain',
              'Follow local authority instructions',
            ],
            videoIds: ['pi_nUPcQz_A', 'rV1iqRD9EKY'],
          ),
          DisasterInfo(
            type: 'Coastal Hazards',
            riskLevel: 'High',
            description: 'Risk of storm surges and coastal erosion.',
            preparednessPoints: [
              'Know high-tide timings',
              'Keep emergency kit ready',
              'Have evacuation plan ready',
              'Monitor weather warnings',
            ],
            tips: [
              'Move away from coastal areas during warnings',
              'Secure boats and property',
              'Follow coast guard instructions',
            ],
            videoIds: ['2AYAMJJ0Bw4', 'A1as2fClnIM'],
          ),
          DisasterInfo(
            type: 'Industrial Accidents',
            riskLevel: 'Medium',
            description: 'Risk of industrial accidents due to high concentration of industries.',
            preparednessPoints: [
              'Know nearby industrial zones',
              'Keep emergency contacts ready',
              'Have masks and protective gear',
              'Know evacuation routes',
            ],
            tips: [
              'Stay indoors during chemical leaks',
              'Follow emergency broadcast instructions',
              'Keep windows closed during incidents',
            ],
            videoIds: ['Mv25QgIJaDs', '7gHEtGY4chE'],
          ),
          DisasterInfo(
              type: 'Air Pollution',
              riskLevel: 'High',
              description: 'Health risks due to industrial emissions, vehicle exhaust, and wildfire smoke.',
              preparednessPoints: [
                'Check air quality index (AQI) regularly',
                'Wear N95 masks in high pollution areas',
                'Use air purifiers indoors',
                'Seal windows and doors during smog events',
              ],
              tips: [
                'Limit outdoor activities during high pollution levels',
                'Stay hydrated and avoid strenuous exercise',
                'Use public transport or carpool to reduce emissions',
              ],
              videoIds: ['6IKaUTYWtvg', 'aK3BWmDC0H4'],
            ),
          DisasterInfo(
            type: 'Building Collapse',
            riskLevel: 'Low',
            description: 'Risk in old buildings and construction zones.',
            preparednessPoints: [
              'Know building safety codes',
              'Identify structural weaknesses',
              'Have evacuation plan',
              'Keep emergency supplies',
            ],
            tips: [
              'Evacuate if cracks appear',
              'Report structural issues',
              'Follow safety guidelines',
            ],
            videoIds: ['FxEM0auDXU4', 'oKWGFjLXJek'],
          ),
          DisasterInfo(
            type: 'Transportation Accidents',
            riskLevel: 'Medium',
            description: 'Risks due to heavy traffic and transport hubs.',
            preparednessPoints: [
              'Know alternative routes',
              'Keep first aid kit ready',
              'Have emergency contacts',
              'Know nearby hospitals',
            ],
            tips: [
              'Follow traffic rules',
              'Stay alert in traffic',
              'Report accidents promptly',
            ],
            videoIds: ['KA0KTS5tNgk', 'Iq7J7_W0h2k'],
          ),
        ];

      default:
        return [
          DisasterInfo(
            type: 'General Emergency',
            riskLevel: 'Medium',
            description: 'Basic emergency preparedness information.',
            preparednessPoints: [
              'Keep emergency supplies ready',
              'Know emergency contact numbers',
              'Have a family emergency plan',
            ],
            tips: [
              'Stay calm during emergencies',
              'Follow official instructions',
              'Help others if safe to do so',
            ],
            videoIds: ['OCjl6tp8dnw', 'WM5tJy_x0zk'],
          ),
        ];
    }
  }
}

class DisasterCard extends StatefulWidget {
  final DisasterInfo disaster;
  final int index;
  
  const DisasterCard({
    Key? key, 
    required this.disaster,
    required this.index,
  }) : super(key: key);

  @override
  State<DisasterCard> createState() => _DisasterCardState();
}

class _DisasterCardState extends State<DisasterCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _isBookmarked = false;
  bool _showTips = true;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  final Map<String, YoutubePlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    for (String videoId in widget.disaster.videoIds) {
      if (videoId.contains('youtube.com') || videoId.contains('youtu.be')) {
        videoId = YoutubePlayer.convertUrlToId(videoId) ?? '';
      }
      if (videoId.isNotEmpty) {
        _controllers[videoId] = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            useHybridComposition: true,
            disableDragSeek: false,
            enableCaption: true,
            showLiveFullscreenButton: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

 Color _getRiskColor(String riskLevel, bool isDarkMode) {
    if (isDarkMode) {
      switch (riskLevel) {
        case 'High':
          return Colors.red[900]!;
        case 'Medium':
          return Colors.amber[900]!;
        case 'Low':
          return Colors.green[900]!;
        default:
          return Colors.grey[900]!;
      }
    } else {
      switch (riskLevel) {
        case 'High':
          return Colors.red[100]!;
        case 'Medium':
          return Colors.amber[100]!;
        case 'Low':
          return Colors.green[100]!;
        default:
          return Colors.grey[100]!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: _getRiskColor(widget.disaster.riskLevel, themeProvider.isDarkMode),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.disaster.type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.warning,
                  size: 16,
                  color: widget.disaster.riskLevel == 'High' 
                      ? Colors.red 
                      : widget.disaster.riskLevel == 'Medium'
                          ? Colors.orange
                          : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Risk Level: ${widget.disaster.riskLevel}',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    setState(() {
                      _isBookmarked = !_isBookmarked;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isBookmarked 
                              ? 'Added to bookmarks' 
                              : 'Removed from bookmarks'
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                      if (_expanded) {
                        _controller.forward();
                      } else {
                        _controller.reverse();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.disaster.description,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ).animate()
                    .fadeIn(delay: Duration(milliseconds: 200))
                    .slideX(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Preparedness Points',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showTips,
                        onChanged: (value) {
                          setState(() {
                            _showTips = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showTips) ...[
                    const SizedBox(height: 8),
                    ...widget.disaster.preparednessPoints.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: Duration(milliseconds: 100 * entry.key))
                        .slideX(begin: 0.2, end: 0);
                    }),
                  ],
                  const SizedBox(height: 16),
                  _buildSection('Safety Tips', widget.disaster.tips, themeProvider.isDarkMode),
                  const SizedBox(height: 16),
                  _buildVideoSection(widget.disaster.videoIds, themeProvider.isDarkMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_right,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: Duration(milliseconds: 100 * entry.key))
            .slideX(begin: 0.2, end: 0);
        }),
      ],
    );
  }

  Widget _buildVideoSection(List<String> videoIds, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rescue Tips Videos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videoIds.length,
            itemBuilder: (context, index) {
              String videoId = videoIds[index];
              if (videoId.contains('youtube.com') || videoId.contains('youtu.be')) {
                videoId = YoutubePlayer.convertUrlToId(videoId) ?? '';
              }
              
              if (videoId.isEmpty || !_controllers.containsKey(videoId)) {
                return const SizedBox();
              }
              
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: YoutubePlayer(
                    controller: _controllers[videoId]!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                      backgroundColor: Colors.grey,
                      bufferedColor: Colors.white,
                    ),
                    onReady: () {
                      // Pause other videos when this one becomes ready
                      _controllers.forEach((key, controller) {
                        if (key != videoId) {
                          controller.pause();
                        }
                      });
                    },
                    onEnded: (data) {
                      _controllers[videoId]?.seekTo(const Duration(seconds: 0));
                    },
                    bottomActions: [
                      CurrentPosition(),
                      ProgressBar(
                        isExpanded: true,
                        colors: const ProgressBarColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                      ),
                      RemainingDuration(),
                      const PlaybackSpeedButton(),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(delay: Duration(milliseconds: 200 * index))
                .slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }
}


class DisasterInfo {
  final String type;
  final String riskLevel;
  final String description;
  final List<String> preparednessPoints;
  final List<String> tips;
  final List<String> videoIds;

  DisasterInfo({
    required this.type,
    required this.riskLevel,
    required this.description,
    required this.preparednessPoints,
    required this.tips,
    required this.videoIds,
  });
}
