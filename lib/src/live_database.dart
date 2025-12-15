import 'livedb_client.dart';

class LiveDatabase {
  final LiveDB _client;

  LiveDatabase(this._client);

  // ============ References (Fluent API) ============

  /// Get reference to a project
  ProjectRef project(String name) => ProjectRef(_client, name);

  /// Shortcut to get reference to a collection
  CollectionRef collection(String projectName, String collectionName) =>
      ProjectRef(_client, projectName).collection(collectionName);

  // ============ Legacy Methods (Wrappers) ============

  /// List all projects
  Future<dynamic> getProjects() async {
    return _client.sendRequest('/api/db/index/projects', method: 'GET');
  }

  /// Create a new project
  Future<dynamic> createProject(String name, String description) async {
    return project(name).create(description: description);
  }

  /// List collections in a project
  Future<dynamic> getCollections(String projectName) async {
    return project(projectName).getCollections();
  }

  /// Add a document to a collection
  Future<dynamic> add(
    String projectName,
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    return collection(projectName, collectionName).add(data);
  }

  /// Get documents (with optional filters)
  Future<dynamic> get(
    String projectName,
    String collectionName, {
    Map<String, dynamic>? filters,
  }) async {
    return collection(projectName, collectionName).get(filters: filters);
  }

  /// Get single document by ID
  Future<dynamic> getById(
    String projectName,
    String collectionName,
    String id,
  ) async {
    return collection(projectName, collectionName).doc(id).get();
  }

  /// Update a document
  Future<dynamic> update(
    String projectName,
    String collectionName,
    String id,
    Map<String, dynamic> data,
  ) async {
    return collection(projectName, collectionName).doc(id).update(data);
  }

  /// Delete a document
  Future<dynamic> delete(
    String projectName,
    String collectionName,
    String id,
  ) async {
    return collection(projectName, collectionName).doc(id).delete();
  }
}

/// Reference to a Project
class ProjectRef {
  final LiveDB _client;
  final String name;

  ProjectRef(this._client, this.name);

  /// Get reference to a collection in this project
  CollectionRef collection(String collectionName) =>
      CollectionRef(_client, name, collectionName);

  /// Create this project
  Future<dynamic> create({String description = ''}) async {
    return _client.sendRequest(
      '/api/db/index/projects',
      method: 'POST',
      data: {'name': name, 'description': description},
    );
  }

  /// Get list of collections in this project
  Future<dynamic> getCollections() async {
    return _client.sendRequest('/api/db/index/$name', method: 'GET');
  }
}

/// Reference to a Collection
class CollectionRef {
  final LiveDB _client;
  final String projectName;
  final String name;

  CollectionRef(this._client, this.projectName, this.name);

  /// Get reference to a document in this collection
  DocumentRef doc(String id) => DocumentRef(_client, projectName, name, id);

  /// Add a new document to this collection
  Future<dynamic> add(Map<String, dynamic> data) async {
    return _client.sendRequest(
      '/api/db/index/$projectName/$name',
      method: 'POST',
      data: data,
    );
  }

  /// Query documents in this collection
  ///
  /// [filters] examples:
  /// - `age[gt]`: 18
  /// - `role`: 'admin'
  /// - `_limit`: 10
  /// - `_sort`: 'created_at:desc'
  Future<dynamic> get({Map<String, dynamic>? filters}) async {
    return _client.sendRequest(
      '/api/db/index/$projectName/$name',
      method: 'GET',
      queryParameters: filters,
    );
  }
}

/// Reference to a Document
class DocumentRef {
  final LiveDB _client;
  final String projectName;
  final String collectionName;
  final String id;

  DocumentRef(this._client, this.projectName, this.collectionName, this.id);

  /// Get this document's data
  Future<dynamic> get() async {
    return _client.sendRequest(
      '/api/db/index/$projectName/$collectionName/$id',
      method: 'GET',
    );
  }

  /// Update this document
  Future<dynamic> update(Map<String, dynamic> data) async {
    return _client.sendRequest(
      '/api/db/index/$projectName/$collectionName/$id',
      method: 'PUT',
      data: data,
    );
  }

  /// Delete this document
  Future<dynamic> delete() async {
    return _client.sendRequest(
      '/api/db/index/$projectName/$collectionName/$id',
      method: 'DELETE',
    );
  }
}
