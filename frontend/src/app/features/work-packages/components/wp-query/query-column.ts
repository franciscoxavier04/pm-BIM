import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export const queryColumnTypes = {
  PROPERTY: 'QueryColumn::Property',
  RELATION_OF_TYPE: 'QueryColumn::RelationOfType',
  RELATION_TO_TYPE: 'QueryColumn::RelationToType',
  RELATION_CHILD: 'QueryColumn::RelationChild',
};

/**
 * A reference to a query column object as returned from the API.
 */
export interface QueryColumn extends HalResource {
  id:string;
  name:string;
  /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
  custom_field?:any;
  _links?:{
    self:{ href:string, title:string };
  };
}

export interface TypeRelationQueryColumn extends QueryColumn {
  type:{ href:string, name:string },
  _links?:{
    self:{ href:string, title:string },
    type:{ href:string, title:string }
  }
}

export interface RelationQueryColumn extends QueryColumn {
  relationType:string;
}

export function isRelationColumn(column:QueryColumn) {
  const relationTypes = [
    queryColumnTypes.RELATION_TO_TYPE,
    queryColumnTypes.RELATION_OF_TYPE,
    queryColumnTypes.RELATION_CHILD,
  ];
  return relationTypes.indexOf(column._type) >= 0;
}
