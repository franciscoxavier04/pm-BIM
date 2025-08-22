//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Injectable } from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QueryFilterInstanceSchemaResource } from 'core-app/features/hal/resources/query-filter-instance-schema-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { QueryColumn } from '../wp-query/query-column';
import compact from 'lodash-es/compact';
import each from 'lodash-es/each';
import without from 'lodash-es/without';

@Injectable()
export class WorkPackagesListInvalidQueryService {
  constructor(protected halResourceService:HalResourceService) {
  }

  public restoreQuery(query:QueryResource, form:QueryFormResource) {
    this.restoreFilters(query, form.payload, form.schema);
    this.restoreColumns(query, form.payload, form.schema);
    this.restoreSortBy(query, form.payload, form.schema);
    this.restoreGroupBy(query, form.payload, form.schema);
    this.restoreOtherProperties(query, form.payload);
  }

  private restoreFilters(query:QueryResource, payload:QueryResource, querySchema:SchemaResource) {
    let filters = payload.filters.map((filter) => {
      const filterInstanceSchema = querySchema.filtersSchemas.elements.find((schema:QueryFilterInstanceSchemaResource) => (schema.filter.allowedValues as QueryFilterResource[])[0].href === filter.filter.href);

      if (!filterInstanceSchema) {
        return null;
      }

      const recreatedFilter = filterInstanceSchema.getFilter();

      const operator = filterInstanceSchema.operator.allowedValues.find((operator:any) => operator.href === filter.operator.href);

      if (operator) {
        recreatedFilter.operator = operator;
      }

      recreatedFilter.values.length = 0;
      each(filter.values, (value) => recreatedFilter.values.push(value));

      return recreatedFilter;
    });

    filters = compact(filters);

    // clear filters while keeping reference
    query.filters.length = 0;
    each(filters, (filter) => query.filters.push(filter));
  }

  private restoreColumns(query:QueryResource, stubQuery:QueryResource, schema:SchemaResource) {
    let columns = stubQuery.columns.map((column) => (schema.columns.allowedValues as QueryColumn[]).find((candidate) => candidate.href === column.href));

    columns = compact(columns);

    query.columns.length = 0;
    each(columns, (column) => query.columns.push(column!));
  }

  private restoreSortBy(query:QueryResource, stubQuery:QueryResource, schema:SchemaResource) {
    let sortBys = stubQuery.sortBy.map((sortBy) => (schema.sortBy.allowedValues as QuerySortByResource[]).find((candidate) => candidate.href === sortBy.href));

    sortBys = compact(sortBys);

    query.sortBy.length = 0;
    each(sortBys, (sortBy) => query.sortBy.push(sortBy!));
  }

  private restoreGroupBy(query:QueryResource, stubQuery:QueryResource, schema:SchemaResource) {
    const groupBy = (schema.groupBy.allowedValues as QueryGroupByResource[]).find((candidate) => stubQuery.groupBy && stubQuery.groupBy.href === candidate.href);

    query.groupBy = groupBy;
  }

  private restoreOtherProperties(query:QueryResource, stubQuery:QueryResource) {
    without(Object.keys(stubQuery.$source), '_links', 'filters').forEach((property:any) => {
      query[property] = stubQuery[property];
    });

    without(Object.keys(stubQuery.$source._links), 'columns', 'groupBy', 'sortBy').forEach((property:any) => {
      query[property] = stubQuery[property];
    });
  }
}
