abstract class ResourceTemplate {
  final String id;
  final String name;
  final String description;
  
  const ResourceTemplate({
    required this.id, 
    required this.name, 
    required this.description
  });
}

class CanvasTemplate extends ResourceTemplate {
  final List<CanvasTemplateNode> nodes;
  
  const CanvasTemplate({
    required super.id, 
    required super.name, 
    required super.description, 
    required this.nodes
  });
}

class CanvasTemplateNode {
  final String title;
  final String type; // 'folder' | 'markdown'
  final String? payloadText;
  final List<CanvasTemplateNode> children;

  const CanvasTemplateNode({
    required this.title,
    required this.type,
    this.payloadText,
    this.children = const [],
  });
}
