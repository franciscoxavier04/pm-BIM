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
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { States } from 'core-app/core/states/states.service';
import { Injectable } from '@angular/core';
import { QueryColumn, queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { combine } from '@openproject/reactivestates';
import { mapTo, take } from 'rxjs/operators';
import { cloneHalResourceCollection } from 'core-app/features/hal/helpers/hal-resource-builder';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { sharedUserColumn } from 'core-app/features/work-packages/components/wp-fast-table/builders/internal-sort-columns';
import compact from 'lodash-es/compact';
import difference from 'lodash-es/difference';
import differenceBy from 'lodash-es/differenceBy';
import findIndex from 'lodash-es/findIndex';
import isEqual from 'lodash-es/isEqual';

@Injectable()
export class WorkPackageViewColumnsService extends WorkPackageQueryStateService<QueryColumn[]> {
  public constructor(readonly states:States, readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  public valueFromQuery(query:QueryResource):QueryColumn[] {
    return [...query.columns];
  }

  public hasChanged(query:QueryResource) {
    return !this.isCurrentlyEqualTo(query.columns);
  }

  public isCurrentlyEqualTo(a:QueryColumn[]) {
    const comparer = (columns:QueryColumn[]) => columns.map((c) => c.href);

    return isEqual(
      comparer(a),
      comparer(this.getColumns()),
    );
  }

  public applyToQuery(query:QueryResource) {
    const toApply = this.getColumns();

    const oldColumns = query.columns.map((el) => el.id);
    const newColumns = toApply.map((el) => el.id);
    query.columns = cloneHalResourceCollection<QueryColumn>(toApply);

    // We can avoid reloading even with relation columns if we only removed columns
    const onlyRemoved = difference(newColumns, oldColumns).length === 0;

    // Reload the table visibly if adding relation or share columns.
    return !onlyRemoved && (this.hasRelationColumns() || this.hasShareColumn());
  }

  /**
   * Returns whether the current set of columns include relations
   */
  public hasRelationColumns() {
    const relationColumns = [
      queryColumnTypes.RELATION_OF_TYPE,
      queryColumnTypes.RELATION_TO_TYPE,
    ];
    return !!this.getColumns().find((c) => relationColumns.indexOf(c._type) >= 0);
  }

  /**
   * Returns whether the current set of columns include child relations
   */
  public hasChildRelationsColumn() {
    return !!this.getColumns().find((c) => c._type === queryColumnTypes.RELATION_CHILD);
  }

  /**
   * Returns whether the current set of columns include shares
   */
  public hasShareColumn() {
    return !!this.getColumns().find((c) => c.id === sharedUserColumn.id);
  }

  /**
   * Retrieve the QueryColumn objects for the selected columns.
   * Returns a shallow copy with the original column objects.
   */
  public getColumns():QueryColumn[] {
    return [...this.current];
  }

  /**
   * Return the index of the given column or -1 if it is not contained.
   */
  public index(id:string):number {
    return findIndex(this.getColumns(), (column) => column.id === id);
  }

  /**
   * Return the column object for the given id.
   * @param id
   */
  public findById(id:string):QueryColumn|undefined {
    return this.getColumns().find((column) => column.id === id);
  }

  /**
   * Return the previous column of the given column name
   * @param column
   */
  public previous(column:QueryColumn):QueryColumn|null {
    const index = this.index(column.id);

    if (index <= 0) {
      return null;
    }

    return this.getColumns()[index - 1];
  }

  /**
   * Return the next column of the given column name
   * @param column
   */
  public next(column:QueryColumn):QueryColumn|null {
    const index = this.index(column.id);

    if (index === -1 || this.isLast(column)) {
      return null;
    }

    return this.getColumns()[index + 1];
  }

  /**
   * Returns true if the column is the first selected
   */
  public isFirst(column:QueryColumn):boolean {
    return this.index(column.id) === 0;
  }

  /**
   * Returns true if the column is the last selected
   */
  public isLast(column:QueryColumn):boolean {
    return this.index(column.id) === this.columnCount - 1;
  }

  /**
   * Update the selected columns to a new set of columns.
   */
  public setColumns(columns:QueryColumn[]) {
    // Don't publish if this is the same content
    if (this.isCurrentlyEqualTo(columns)) {
      return;
    }

    this.update(columns);
  }

  public setColumnsById(columnIds:string[]) {
    const mapped = columnIds.map((id) => this.all.find((c) => c.id === id));
    this.setColumns(compact(mapped));
  }

  /**
   * Move the column at index {fromIndex} to {toIndex}.
   * - If toIndex is larger than all columns, insert at the end.
   * - If toIndex is less than zero, insert at the start.
   */
  public moveColumn(fromIndex:number, toIndex:number) {
    const columns = this.getColumns();

    if (toIndex >= columns.length) {
      toIndex = columns.length - 1;
    }

    if (toIndex < 0) {
      toIndex = 0;
    }

    const element = columns[fromIndex];
    columns.splice(fromIndex, 1);
    columns.splice(toIndex, 0, element);

    this.setColumns(columns);
  }

  /**
   * Shift the given column name X indices,
   * where X is the offset in indices (-1 = shift one to left)
   */
  public shift(column:QueryColumn, offset:number) {
    const index = this.index(column.id);
    if (index === -1) {
      return;
    }

    this.moveColumn(index, index + offset);
  }

  /**
   * Add a new column to the selection at the given position
   */
  public addColumn(id:string, position?:number) {
    const columns = this.getColumns();

    if (position === undefined) {
      position = columns.length;
    }

    if (this.index(id) === -1) {
      const newColumn = this.all.find((column) => column.id === id);

      if (!newColumn) {
        throw new Error('Column with provided name is not found');
      }

      columns.splice(position, 0, newColumn);
      this.setColumns(columns);
    }
  }

  /**
   * Remove a column from the active list
   */
  public removeColumn(column:QueryColumn) {
    const index = this.index(column.id);

    if (index !== -1) {
      const columns = this.getColumns();
      columns.splice(index, 1);
      this.setColumns(columns);
    }
  }

  // only exists to cast the state
  protected get current() {
    return this.lastUpdatedState.getValueOr([]);
  }

  // Get the available state
  protected get availableState() {
    return this.querySpace.available.columns;
  }

  /**
   * Return the number of selected rows.
   */
  public get columnCount():number {
    return this.getColumns().length;
  }

  /**
   * Get all available columns (regardless of whether they are selected already)
   */
  public get all():QueryColumn[] {
    return this.availableState.getValueOr([]);
  }

  public get allPropertyColumns():QueryColumn[] {
    return this
      .all
      .filter((column:QueryColumn) => column._type === queryColumnTypes.PROPERTY);
  }

  /**
   * Get columns not yet selected
   */
  public get unused():QueryColumn[] {
    return differenceBy(this.all, this.getColumns(), '$href');
  }

  /**
   * Columns service depends on two states
   */
  public onReady() {
    return combine(this.pristineState, this.availableState)
      .values$()
      .pipe(
        take(1),
        mapTo(null),
      )
      .toPromise();
  }
}
