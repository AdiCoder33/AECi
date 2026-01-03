import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class ResearchProject {
  ResearchProject({
    required this.id,
    required this.title,
    required this.status,
    required this.createdBy,
    this.summary,
    this.role,
    this.startDate,
    this.endDate,
    this.keywords = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final String createdBy;
  final String? summary;
  final String? role;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> keywords;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ResearchProject.fromMap(Map<String, dynamic> map) {
    return ResearchProject(
      id: map['id'] as String,
      title: map['title'] as String,
      status: map['status'] as String,
      createdBy: map['created_by'] as String,
      summary: map['summary'] as String?,
      role: map['role'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      keywords: (map['keywords'] as List?)?.cast<String>() ?? const [],
      attachments: (map['attachments'] as List?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'title': title,
      'status': status,
      'summary': summary,
      'role': role,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'keywords': keywords,
      'attachments': attachments,
      'created_by': userId,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'status': status,
      'summary': summary,
      'role': role,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'keywords': keywords,
      'attachments': attachments,
    };
  }
}

class PublicationItem {
  PublicationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.createdBy,
    this.abstractText,
    this.venueOrJournal,
    this.date,
    this.link,
    this.keywords = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type; // presentation | publication
  final String title;
  final String createdBy;
  final String? abstractText;
  final String? venueOrJournal;
  final DateTime? date;
  final String? link;
  final List<String> keywords;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PublicationItem.fromMap(Map<String, dynamic> map) {
    return PublicationItem(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      createdBy: map['created_by'] as String,
      abstractText: map['abstract'] as String?,
      venueOrJournal: map['venue_or_journal'] as String?,
      date:
          map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      link: map['link'] as String?,
      keywords: (map['keywords'] as List?)?.cast<String>() ?? const [],
      attachments: (map['attachments'] as List?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'type': type,
      'title': title,
      'abstract': abstractText,
      'venue_or_journal': venueOrJournal,
      'date': date?.toIso8601String(),
      'link': link,
      'keywords': keywords,
      'attachments': attachments,
      'created_by': userId,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'type': type,
      'title': title,
      'abstract': abstractText,
      'venue_or_journal': venueOrJournal,
      'date': date?.toIso8601String(),
      'link': link,
      'keywords': keywords,
      'attachments': attachments,
    };
  }
}

class PortfolioRepository {
  PortfolioRepository(this._client);

  final SupabaseClient _client;

  Future<List<ResearchProject>> listResearch() async {
    final rows = await _client
        .from('research_projects')
        .select('*')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) => ResearchProject.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ResearchProject> getResearch(String id) async {
    final row = await _client
        .from('research_projects')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      throw PostgrestException(message: 'Research not found');
    }
    return ResearchProject.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> createResearch(ResearchProject data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not signed in');
    final inserted = await _client
        .from('research_projects')
        .insert(data.toInsertMap(userId))
        .select('id')
        .maybeSingle();
    if (inserted == null) throw PostgrestException(message: 'Unable to create');
    return inserted['id'] as String;
  }

  Future<void> updateResearch(String id, ResearchProject data) async {
    await _client.from('research_projects').update(data.toUpdateMap()).eq('id', id);
  }

  Future<void> deleteResearch(String id) async {
    await _client.from('research_projects').delete().eq('id', id);
  }

  Future<List<PublicationItem>> listPublications() async {
    final rows = await _client
        .from('presentations_publications')
        .select('*')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) => PublicationItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PublicationItem> getPublication(String id) async {
    final row = await _client
        .from('presentations_publications')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      throw PostgrestException(message: 'Item not found');
    }
    return PublicationItem.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<PublicationItem>> listPublicationsByIds(
    List<String> publicationIds,
  ) async {
    if (publicationIds.isEmpty) return [];
    final quoted = publicationIds.toSet().map((id) => '"$id"').join(',');
    final rows = await _client
        .from('presentations_publications')
        .select('*')
        .filter('id', 'in', '($quoted)')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) => PublicationItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> createPublication(PublicationItem data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not signed in');
    final inserted = await _client
        .from('presentations_publications')
        .insert(data.toInsertMap(userId))
        .select('id')
        .maybeSingle();
    if (inserted == null) throw PostgrestException(message: 'Unable to create');
    return inserted['id'] as String;
  }

  Future<void> updatePublication(String id, PublicationItem data) async {
    await _client
        .from('presentations_publications')
        .update(data.toUpdateMap())
        .eq('id', id);
  }

  Future<void> deletePublication(String id) async {
    await _client.from('presentations_publications').delete().eq('id', id);
  }

  Future<String> uploadAttachment({
    required String kind, // research or pubs
    required String itemId,
    required File file,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not signed in');
    final path = '$userId/$kind/$itemId/${p.basename(file.path)}';
    await _client.storage.from('elogbook-media').upload(path, file);
    return path;
  }

  Future<String> signAttachment(String path) async {
    final url =
        await _client.storage.from('elogbook-media').createSignedUrl(path, 3600);
    return url;
  }
}

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PortfolioRepository(client);
});
