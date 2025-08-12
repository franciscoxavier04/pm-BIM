import { ChangeDetectorRef, Directive, OnDestroy, OnInit, Renderer2, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridInitializationService } from 'core-app/shared/components/grids/grid/initialization.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridAddWidgetService } from 'core-app/shared/components/grids/grid/add-widget.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';

@Directive()
export abstract class GridPageComponent implements OnInit, OnDestroy {
  readonly gridInitialization = inject(GridInitializationService);
  readonly pathHelper = inject(PathHelperService);
  readonly currentProject = inject(CurrentProjectService);
  readonly i18n = inject(I18nService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly title = inject(OpTitleService);
  readonly addWidget = inject(GridAddWidgetService);
  readonly renderer = inject(Renderer2);
  readonly areas = inject(GridAreaService);
  readonly configurationService = inject(ConfigurationService);

  public text = {
    title: this.i18n.t(`js.${this.i18nNamespace()}.label`),
    html_title: this.i18n.t(`js.${this.i18nNamespace()}.label`),
  };

  public showToolbar = true;

  public grid:GridResource;

  protected isTurboFrameSidebarEnabled():boolean {
    // may be overridden by subclasses
    return false;
  }

  ngOnInit() {
    this.renderer.addClass(document.body, 'widget-grid-layout');
    this
      .gridInitialization
      .initialize(this.gridScopePath())
      .subscribe((grid) => {
        this.grid = grid;
        this.cdRef.detectChanges();
      });

    this.setHtmlTitle();
  }

  ngOnDestroy():void {
    this.renderer.removeClass(document.body, 'widget-grid-layout');
  }

  protected setHtmlTitle() {
    this.title.setFirstPart(this.text.html_title);
  }

  protected abstract i18nNamespace():string;

  protected abstract gridScopePath():string;
}
