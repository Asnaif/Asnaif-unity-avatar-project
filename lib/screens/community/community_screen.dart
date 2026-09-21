import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/social_service.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';
import 'package:interprep/common/resources/widgets/refresh/enhanced_refresh_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final SocialService _socialService = SocialService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _studyGroups = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String _selectedTab = 'leaderboard'; // 'leaderboard', 'groups', 'friends', 'share'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final leaderboard = await _socialService.getPublicLeaderboard(limit: 20);
      final groups = await _socialService.getStudyGroups();
      final friends = await _socialService.getFriends();
      final pendingRequests = await _getPendingFriendRequests();
      
      setState(() {
        _leaderboard = leaderboard;
        _studyGroups = groups;
        _friends = friends;
        _pendingRequests = pendingRequests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading community data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Get pending friend requests
  Future<List<Map<String, dynamic>>> _getPendingFriendRequests() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('friendships')
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'friendshipId': doc.id,
          'userId': data['userId'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _selectedTab == 'leaderboard'
                    ? EnhancedRefreshIndicator(
                        onRefresh: _loadData,
                        child: _buildLeaderboardTab(),
                      )
                    : _selectedTab == 'groups'
                        ? EnhancedRefreshIndicator(
                            onRefresh: _loadData,
                            child: _buildGroupsTab(),
                          )
                        : _selectedTab == 'friends'
                            ? EnhancedRefreshIndicator(
                                onRefresh: _loadData,
                                child: _buildFriendsTab(),
                              )
                            : _buildShareTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _buildTab('leaderboard', 'Leaderboard', Icons.leaderboard),
          _buildTab('groups', 'Groups', Icons.groups),
          _buildTab('friends', 'Friends', Icons.people),
          _buildTab('share', 'Share', Icons.share),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final isSelected = _selectedTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Styles.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SkeletonLoader(
          width: double.infinity,
          height: 80,
          borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_leaderboard.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.leaderboard,
        title: 'No leaderboard data available',
        message: 'Complete practice sessions to appear on the leaderboard',
        iconColor: Colors.grey,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        final rank = index + 1;
        final currentUserId = _auth.currentUser?.uid;
        final isCurrentUser = entry['userId'] == currentUserId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              entry['displayName'] ?? 'Anonymous User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Level ${entry['currentLevel']} • ${entry['totalSessions']} sessions',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry['totalXP']} XP',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (rank <= 3)
                        Text(
                          _getRankEmoji(rank),
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),
                if (!isCurrentUser) ...[
                  // Show different button based on friendship status
                  Builder(
                    builder: (context) {
                      final friendshipStatus = entry['friendshipStatus'] as String?;
                      
                      if (friendshipStatus == 'friends') {
                        return IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: null, // Disabled
                          tooltip: 'Already Friends',
                        );
                      } else if (friendshipStatus == 'pending_sent') {
                        return IconButton(
                          icon: const Icon(Icons.hourglass_empty, color: Colors.orange),
                          onPressed: null, // Disabled
                          tooltip: 'Request Pending',
                        );
                      } else if (friendshipStatus == 'pending_received') {
                        return IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () {
                            // Show accept/decline dialog or navigate to friends tab
                            _showPendingRequestDialog(entry['userId'], entry['displayName'] ?? 'User');
                          },
                          tooltip: 'Accept Request',
                        );
                      } else {
                        // No friendship - show add friend button
                        return IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () => _addFriend(entry['userId'], entry['displayName'] ?? 'User'),
                          tooltip: 'Add Friend',
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Study Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _studyGroups.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.groups,
                  title: 'No study groups yet',
                  message: 'Create or join a study group to practice together and share your progress',
                  actionLabel: 'Create Group',
                  onAction: _showCreateGroupDialog,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _studyGroups.length,
                  itemBuilder: (context, index) {
                    final group = _studyGroups[index];
                    final currentUserId = _auth.currentUser?.uid;
                    final isMember = (group['members'] as List?)?.contains(currentUserId) ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Styles.primaryColor,
                          child: const Icon(Icons.groups, color: Colors.white),
                        ),
                        title: Text(
                          group['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          group['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${group['memberCount']} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!isMember)
                              IconButton(
                                icon: const Icon(Icons.group_add),
                                onPressed: () => _joinStudyGroup(group['groupId'], group['name']),
                                tooltip: 'Join Group',
                              ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to group details
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        // Pending friend requests section
        if (_pendingRequests.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Friend Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._pendingRequests.map((request) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('User ${request['userId']}'),
                      subtitle: const Text('Wants to be your friend'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptFriendRequest(request['friendshipId']),
                            tooltip: 'Accept',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _declineFriendRequest(request['friendshipId']),
                            tooltip: 'Decline',
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
        // Friends list
        Expanded(
          child: _friends.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.people,
                  title: 'No friends yet',
                  message: 'Add friends from the leaderboard to connect and compete',
                  iconColor: Colors.grey,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text('Friend ${friend['friendId']}'),
                        subtitle: const Text('Active friend'),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat),
                          onPressed: () {
                            // Navigate to chat or friend profile
                          },
                          tooltip: 'Message',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildShareTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, size: 64, color: Styles.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Share Your Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your practice sessions and achievements with friends',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _socialService.shareSession('latest');
                  CustomToast.showSuccess('Session shared successfully!');
                } catch (e) {
                  CustomToast.showError('Error sharing: $e');
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Latest Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    return Styles.primaryColor;
  }

  String _getRankEmoji(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '';
  }

  Future<void> _addFriend(String friendUserId, String friendName) async {
    try {
      await _socialService.addFriend(friendUserId);
      CustomToast.showSuccess('Friend request sent to $friendName');
      _loadData();
    } catch (e) {
      CustomToast.showError('Error adding friend: $e');
    }
  }

  Future<void> _acceptFriendRequest(String friendshipId) async {
    try {
      await _socialService.acceptFriendRequest(friendshipId);
      CustomToast.showSuccess('Friend request accepted');
      _loadData();
    } catch (e) {
      CustomToast.showError('Error accepting request: $e');
    }
  }

  Future<void> _declineFriendRequest(String friendshipId) async {
    try {
      await _firestore.collection('friendships').doc(friendshipId).delete();
      CustomToast.showSuccess('Friend request declined');
      _loadData();
    } catch (e) {
      CustomToast.showError('Error declining request: $e');
    }
  }

  Future<void> _joinStudyGroup(String groupId, String groupName) async {
    try {
      await _socialService.joinStudyGroup(groupId);
      CustomToast.showSuccess('Joined $groupName');
      _loadData();
    } catch (e) {
      CustomToast.showError('Error joining group: $e');
    }
  }
    void _showPendingRequestDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Friend Request from $userName'),
        content: const Text('You have a pending friend request from this user. Go to Friends tab to accept or decline.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedTab = 'friends');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Go to Friends'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Study Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _socialService.createStudyGroup(
                    nameController.text,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                  _loadData();
                  CustomToast.showSuccess('Study group created!');
                } catch (e) {
                  CustomToast.showError('Error: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}