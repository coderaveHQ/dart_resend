import 'dart:convert';

import 'package:dart_resend/dart_resend.dart';

/// Creates a global contact with properties, segments, and topic preferences.
Future<ResendResponse<ResendId>> createContact(Resend resend) {
  return resend.contacts.create(
    CreateContactRequest(
      email: 'ada@example.com',
      firstName: 'Ada',
      lastName: 'Lovelace',
      unsubscribed: false,
      properties: <String, Object?>{'plan': 'pro', 'login_count': 7},
      segments: <ContactSegmentReference>[
        ContactSegmentReference('seg_customers'),
      ],
      topics: <ContactTopicSubscription>[
        ContactTopicSubscription(
          id: 'topic_product_updates',
          subscription: TopicSubscription.optIn,
        ),
      ],
    ),
  );
}

/// Lists global contacts.
Future<ResendResponse<ResendPage<Contact>>> listContacts(Resend resend) {
  return resend.contacts.list(pagination: PaginationOptions(limit: 50));
}

/// Lists contacts in one segment.
Future<ResendResponse<ResendPage<Contact>>> listContactsInSegment(
  Resend resend,
  String segmentId,
) {
  return resend.contacts.list(
    segmentId: segmentId,
    pagination: PaginationOptions(limit: 50),
  );
}

/// Retrieves a contact by ID or email address.
Future<ResendResponse<Contact>> retrieveContact(
  Resend resend,
  String idOrEmail,
) {
  return resend.contacts.retrieve(idOrEmail);
}

/// Updates a contact and removes one existing property value.
Future<ResendResponse<ResendId>> updateContact(
  Resend resend,
  String idOrEmail,
) {
  return resend.contacts.update(
    idOrEmail,
    UpdateContactRequest(
      firstName: 'Augusta Ada',
      clearLastName: true,
      unsubscribed: false,
      properties: <String, Object?>{'plan': 'enterprise', 'login_count': null},
    ),
  );
}

/// Deletes a contact by ID or email address.
Future<ResendResponse<ResendDeletion>> deleteContact(
  Resend resend,
  String idOrEmail,
) {
  return resend.contacts.delete(idOrEmail);
}

/// Lists the segments to which a contact belongs.
Future<ResendResponse<ResendPage<ContactSegment>>> listContactSegments(
  Resend resend,
  String idOrEmail,
) {
  return resend.contacts.listSegments(
    idOrEmail,
    pagination: PaginationOptions(limit: 25),
  );
}

/// Adds a contact to a segment.
Future<ResendResponse<ResendId>> addContactToSegment(
  Resend resend,
  String idOrEmail,
  String segmentId,
) {
  return resend.contacts.addToSegment(idOrEmail, segmentId);
}

/// Removes a contact from a segment.
Future<ResendResponse<ContactSegmentDeletion>> removeContactFromSegment(
  Resend resend,
  String idOrEmail,
  String segmentId,
) {
  return resend.contacts.removeFromSegment(idOrEmail, segmentId);
}

/// Lists a contact's topic subscriptions.
Future<ResendResponse<ResendPage<ContactTopic>>> listContactTopics(
  Resend resend,
  String idOrEmail,
) {
  return resend.contacts.listTopics(
    idOrEmail,
    pagination: PaginationOptions(limit: 25),
  );
}

/// Replaces selected topic subscription values for a contact.
Future<ResendResponse<ResendId>> updateContactTopics(
  Resend resend,
  String idOrEmail,
) {
  return resend.contacts.updateTopics(
    idOrEmail,
    UpdateContactTopicsRequest(<ContactTopicSubscription>[
      ContactTopicSubscription(
        id: 'topic_product_updates',
        subscription: TopicSubscription.optIn,
      ),
      ContactTopicSubscription(
        id: 'topic_marketing',
        subscription: TopicSubscription.optOut,
      ),
    ]),
  );
}

/// Starts an asynchronous CSV contact import.
Future<ResendResponse<ResendId>> createContactImport(Resend resend) {
  final List<int> csv = utf8.encode(
    'email,first_name,age,subscribed\n'
    'ada@example.com,Ada,36,true\n',
  );
  return resend.contacts.imports.create(
    CreateContactImportRequest(
      bytes: csv,
      filename: 'contacts.csv',
      columnMap: ContactImportColumnMap(
        email: 'email',
        firstName: 'first_name',
        properties: <String, ContactImportPropertyMapping>{
          'age': ContactImportPropertyMapping(
            column: 'age',
            type: ContactImportPropertyType.number,
          ),
          'subscribed': ContactImportPropertyMapping(
            column: 'subscribed',
            type: ContactImportPropertyType.boolean,
          ),
        },
      ),
      onConflict: ContactImportOnConflict.upsert,
      segments: <ContactSegmentReference>[
        ContactSegmentReference('seg_customers'),
      ],
      topics: <ContactTopicSubscription>[
        ContactTopicSubscription(
          id: 'topic_product_updates',
          subscription: TopicSubscription.optIn,
        ),
      ],
    ),
  );
}

/// Lists asynchronous contact imports, optionally filtered by status.
Future<ResendResponse<ResendPage<ContactImport>>> listContactImports(
  Resend resend,
) {
  return resend.contacts.imports.list(
    status: ContactImportStatus.inProgress,
    pagination: PaginationOptions(limit: 25),
  );
}

/// Retrieves one asynchronous contact import and its row counts.
Future<ResendResponse<ContactImport>> retrieveContactImport(
  Resend resend,
  String importId,
) {
  return resend.contacts.imports.retrieve(importId);
}
