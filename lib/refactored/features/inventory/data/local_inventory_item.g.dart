// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_inventory_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalInventoryItemCollection on Isar {
  IsarCollection<LocalInventoryItem> get localInventoryItems =>
      this.collection();
}

const LocalInventoryItemSchema = CollectionSchema(
  name: r'LocalInventoryItem',
  id: 1198390868261562101,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'inventoryId': PropertySchema(
      id: 1,
      name: r'inventoryId',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 2,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 3,
      name: r'productName',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 4,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'sellerId': PropertySchema(
      id: 5,
      name: r'sellerId',
      type: IsarType.string,
    ),
    r'shelfId': PropertySchema(
      id: 6,
      name: r'shelfId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _localInventoryItemEstimateSize,
  serialize: _localInventoryItemSerialize,
  deserialize: _localInventoryItemDeserialize,
  deserializeProp: _localInventoryItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'inventoryId': IndexSchema(
      id: 5580507021079049209,
      name: r'inventoryId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'inventoryId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localInventoryItemGetId,
  getLinks: _localInventoryItemGetLinks,
  attach: _localInventoryItemAttach,
  version: '3.1.0+1',
);

int _localInventoryItemEstimateSize(
  LocalInventoryItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.inventoryId.length * 3;
  {
    final value = object.productId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.productName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sellerId.length * 3;
  {
    final value = object.shelfId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _localInventoryItemSerialize(
  LocalInventoryItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.inventoryId);
  writer.writeString(offsets[2], object.productId);
  writer.writeString(offsets[3], object.productName);
  writer.writeLong(offsets[4], object.quantity);
  writer.writeString(offsets[5], object.sellerId);
  writer.writeString(offsets[6], object.shelfId);
  writer.writeString(offsets[7], object.status);
}

LocalInventoryItem _localInventoryItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalInventoryItem();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.inventoryId = reader.readString(offsets[1]);
  object.productId = reader.readStringOrNull(offsets[2]);
  object.productName = reader.readStringOrNull(offsets[3]);
  object.quantity = reader.readLong(offsets[4]);
  object.sellerId = reader.readString(offsets[5]);
  object.shelfId = reader.readStringOrNull(offsets[6]);
  object.status = reader.readString(offsets[7]);
  return object;
}

P _localInventoryItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localInventoryItemGetId(LocalInventoryItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localInventoryItemGetLinks(
    LocalInventoryItem object) {
  return [];
}

void _localInventoryItemAttach(
    IsarCollection<dynamic> col, Id id, LocalInventoryItem object) {
  object.id = id;
}

extension LocalInventoryItemByIndex on IsarCollection<LocalInventoryItem> {
  Future<LocalInventoryItem?> getByInventoryId(String inventoryId) {
    return getByIndex(r'inventoryId', [inventoryId]);
  }

  LocalInventoryItem? getByInventoryIdSync(String inventoryId) {
    return getByIndexSync(r'inventoryId', [inventoryId]);
  }

  Future<bool> deleteByInventoryId(String inventoryId) {
    return deleteByIndex(r'inventoryId', [inventoryId]);
  }

  bool deleteByInventoryIdSync(String inventoryId) {
    return deleteByIndexSync(r'inventoryId', [inventoryId]);
  }

  Future<List<LocalInventoryItem?>> getAllByInventoryId(
      List<String> inventoryIdValues) {
    final values = inventoryIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'inventoryId', values);
  }

  List<LocalInventoryItem?> getAllByInventoryIdSync(
      List<String> inventoryIdValues) {
    final values = inventoryIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'inventoryId', values);
  }

  Future<int> deleteAllByInventoryId(List<String> inventoryIdValues) {
    final values = inventoryIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'inventoryId', values);
  }

  int deleteAllByInventoryIdSync(List<String> inventoryIdValues) {
    final values = inventoryIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'inventoryId', values);
  }

  Future<Id> putByInventoryId(LocalInventoryItem object) {
    return putByIndex(r'inventoryId', object);
  }

  Id putByInventoryIdSync(LocalInventoryItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'inventoryId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInventoryId(List<LocalInventoryItem> objects) {
    return putAllByIndex(r'inventoryId', objects);
  }

  List<Id> putAllByInventoryIdSync(List<LocalInventoryItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'inventoryId', objects, saveLinks: saveLinks);
  }
}

extension LocalInventoryItemQueryWhereSort
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QWhere> {
  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalInventoryItemQueryWhere
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QWhereClause> {
  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      inventoryIdEqualTo(String inventoryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'inventoryId',
        value: [inventoryId],
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterWhereClause>
      inventoryIdNotEqualTo(String inventoryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inventoryId',
              lower: [],
              upper: [inventoryId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inventoryId',
              lower: [inventoryId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inventoryId',
              lower: [inventoryId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inventoryId',
              lower: [],
              upper: [inventoryId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalInventoryItemQueryFilter
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QFilterCondition> {
  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inventoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inventoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inventoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inventoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'inventoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'inventoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'inventoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'inventoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inventoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      inventoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'inventoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'productId',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'productId',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'productName',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'productName',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      quantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      quantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      quantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sellerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      sellerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sellerId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shelfId',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shelfId',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shelfId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shelfId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shelfId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shelfId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shelfId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shelfId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shelfId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shelfId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shelfId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      shelfIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shelfId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension LocalInventoryItemQueryObject
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QFilterCondition> {}

extension LocalInventoryItemQueryLinks
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QFilterCondition> {}

extension LocalInventoryItemQuerySortBy
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QSortBy> {
  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByInventoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByInventoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortBySellerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortBySellerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByShelfId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByShelfIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension LocalInventoryItemQuerySortThenBy
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QSortThenBy> {
  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByInventoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByInventoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenBySellerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenBySellerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByShelfId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfId', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByShelfIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfId', Sort.desc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension LocalInventoryItemQueryWhereDistinct
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct> {
  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByInventoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inventoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctBySellerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByShelfId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shelfId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalInventoryItem, LocalInventoryItem, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension LocalInventoryItemQueryProperty
    on QueryBuilder<LocalInventoryItem, LocalInventoryItem, QQueryProperty> {
  QueryBuilder<LocalInventoryItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalInventoryItem, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalInventoryItem, String, QQueryOperations>
      inventoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inventoryId');
    });
  }

  QueryBuilder<LocalInventoryItem, String?, QQueryOperations>
      productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<LocalInventoryItem, String?, QQueryOperations>
      productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<LocalInventoryItem, int, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<LocalInventoryItem, String, QQueryOperations>
      sellerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellerId');
    });
  }

  QueryBuilder<LocalInventoryItem, String?, QQueryOperations>
      shelfIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shelfId');
    });
  }

  QueryBuilder<LocalInventoryItem, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
