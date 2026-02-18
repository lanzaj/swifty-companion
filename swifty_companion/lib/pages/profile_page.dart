import 'package:flutter/material.dart';
import '../models.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(user.login, style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Column(
          children: [
            _buildHeader(context),
            const TabBar(
              labelColor: Colors.black,
              tabs: [
                Tab(text: 'Skills'),
                Tab(text: 'Projects'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildSkillsList(), _buildProjectsList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.imageUrl),
            onBackgroundImageError: (_, __) =>
                const Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 10),
          Text(
            user.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(user.email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Wallet', '${user.wallet} ₳'),
              _buildStatItem('Correction', '${user.correctionPoint}'),
              _buildStatItem('Location', user.location),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSkillsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: user.skills.length,
      itemBuilder: (context, index) {
        final skill = user.skills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${skill.level.toStringAsFixed(2)}  --  ${(skill.level / 21.0 * 100).toStringAsFixed(2)}%',
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: skill.level / 21.0,
                backgroundColor: Colors.grey[300],
                color: Colors.black,
                minHeight: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: user.projects.length,
      itemBuilder: (context, index) {
        final project = user.projects[index];
        final bool isValidated = project.validated == true;
        final Color color = isValidated
            ? Colors.green
            : (project.validated == false ? Colors.red : Colors.grey);

        return Card(
          child: ListTile(
            title: Text(project.name),
            subtitle: Text(project.status.replaceAll('_', ' ')),
            trailing: Text(
              project.finalMark != null ? '${project.finalMark}' : '-',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
