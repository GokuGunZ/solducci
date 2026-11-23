import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/services/project_hierarchy_service.dart';

enum ProjectModuleType {
  heroHeader,
  folderTreePreview,
  egoGraphRadar,
  thoughtStream,
  continuityPulse,
}

/// Evaluated context of a project entity, determining which progressive dashboard
/// modules should self-assemble without cluttering nascent ideas.
class ProjectScopeContext extends Equatable {
  final LifeEntity rootEntity;
  final List<ProjectHierarchyNode> hierarchyTree;
  final List<LifeEntity> descendants;
  final Set<ProjectModuleType> activeModules;

  const ProjectScopeContext({
    required this.rootEntity,
    required this.hierarchyTree,
    required this.descendants,
    required this.activeModules,
  });

  /// Evaluates which modules to render dynamically based on actual content depth.
  static Set<ProjectModuleType> evaluateModules({
    required int directChildrenCount,
    required int totalDescendantCount,
    required int blockCount,
  }) {
    final modules = <ProjectModuleType>{
      ProjectModuleType.heroHeader,
      ProjectModuleType.thoughtStream,
    };

    // Folder preview appears when there is at least 1 child
    if (directChildrenCount > 0) {
      modules.add(ProjectModuleType.folderTreePreview);
    }

    // Ego Graph radar activates when there are multiple elements (>= 2)
    if (totalDescendantCount >= 2) {
      modules.add(ProjectModuleType.egoGraphRadar);
    }

    // Continuity pulse appears when the project has accumulated meaningful content
    if (totalDescendantCount > 1 || blockCount > 2) {
      modules.add(ProjectModuleType.continuityPulse);
    }

    return modules;
  }

  @override
  List<Object?> get props => [rootEntity, hierarchyTree, descendants, activeModules];
}
