import 'package:flutter/material.dart';
import 'package:job_swaipe/models/course.dart';

class SkillGapView extends StatelessWidget {
  final List<SkillGap> skillGaps;

  const SkillGapView({super.key, required this.skillGaps});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Skill Gap Detected',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'We found ${skillGaps.length} missing skills that could improve your job matches:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: skillGaps.length,
                itemBuilder: (context, index) {
                  final skillGap = skillGaps[index];
                  return _buildSkillGapCard(context, skillGap);
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to detailed skill plan view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _SkillPlanView(skillGaps: skillGaps),
                    ),
                  );
                },
                icon: const Icon(Icons.school),
                label: const Text('START SKILL PLAN'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGapCard(BuildContext context, SkillGap skillGap) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skillGap.skillName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Importance: ${skillGap.importance}/10',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Related to: ${skillGap.relatedRoles.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillPlanView extends StatelessWidget {
  final List<SkillGap> skillGaps;

  const _SkillPlanView({required this.skillGaps});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Skill Plan'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: skillGaps.length,
        itemBuilder: (context, index) {
          final skillGap = skillGaps[index];
          return _buildSkillPlanCard(context, skillGap, index);
        },
      ),
    );
  }

  Widget _buildSkillPlanCard(BuildContext context, SkillGap skillGap, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    skillGap.skillName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              skillGap.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Recommended Courses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (skillGap.recommendedCourses.isEmpty)
              const Text('No specific courses found. Check the Course Hub for more options.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: skillGap.recommendedCourses.length,
                itemBuilder: (context, courseIndex) {
                  final course = skillGap.recommendedCourses[courseIndex];
                  return _buildCourseItem(context, course);
                },
              ),
            const SizedBox(height: 16),
            const Text(
              'Learning Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('• Start with beginner courses if you\'re new to this skill'),
            const Text('• Practice with real projects to reinforce learning'),
            const Text('• Join communities to learn from peers'),
            const Text('• Set specific goals and track your progress'),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '5 people like you became ${skillGap.relatedRoles.isNotEmpty ? skillGap.relatedRoles.first : "professionals"} after learning ${skillGap.skillName}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, Course course) {
    return ListTile(
      title: Text(
        course.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${course.provider} • ${course.duration}'),
      trailing: course.isFree
          ? const Chip(
              label: Text('FREE'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            )
          : null,
      onTap: () {
        // Open course details or URL
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(course.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.network(
                        course.imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 150,
                        ),
                      ),
                    ),
                  Text('Provider: ${course.provider}'),
                  Text('Duration: ${course.duration}'),
                  Text('Level: ${course.level.name}'),
                  const SizedBox(height: 8),
                  Text(course.description),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Launch course URL
                  Navigator.pop(context);
                  // TODO: Add URL launcher functionality
                },
                child: const Text('OPEN COURSE'),
              ),
            ],
          ),
        );
      },
    );
  }
} 