enum AccountRole { freelancer, client }

extension AccountRoleValue on AccountRole {
  String get value => name;

  static AccountRole? fromValue(String? value) => switch (value) {
    'freelancer' => AccountRole.freelancer,
    'client' => AccountRole.client,
    _ => null,
  };
}

enum DocumentStatus { approved, pending, amendments }

class Document {
  const Document({
    required this.name,
    required this.type,
    required this.version,
    required this.status,
  });

  final String name;
  final String type;
  final String version;
  final DocumentStatus status;
}

class Project {
  const Project({
    required this.name,
    required this.owner,
    required this.pending,
    required this.documents,
  });

  final String name;
  final String owner;
  final int pending;
  final List<Document> documents;
}

const demoProjects = [
  Project(
    name: 'Nova Cafe Branding',
    owner: 'Sara Khan',
    pending: 1,
    documents: [
      Document(
        name: 'Service contract',
        type: 'Contract',
        version: 'v1',
        status: DocumentStatus.approved,
      ),
      Document(
        name: 'Logo concepts v2',
        type: 'Design',
        version: 'v2',
        status: DocumentStatus.pending,
      ),
      Document(
        name: 'Invoice #001',
        type: 'Invoice',
        version: 'v1',
        status: DocumentStatus.pending,
      ),
    ],
  ),
  Project(
    name: 'Landing Page',
    owner: 'Bilal Ahmed',
    pending: 0,
    documents: [],
  ),
];
