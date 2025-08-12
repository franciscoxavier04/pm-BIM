import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { Injectable, DOCUMENT, inject } from '@angular/core';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Injectable()
export class TypeBannerService extends BannersService {
  protected confirmDialog = inject(ConfirmDialogService);
  protected I18n = inject(I18nService);

  eeAvailable = this.allowsTo('edit_attribute_groups');

  showEEOnlyHint():void {
    this.confirmDialog.confirm({
      text: {
        title: this.I18n.t('js.types.attribute_groups.upgrade_to_ee'),
        text: this.I18n.t('js.types.attribute_groups.upgrade_to_ee_text'),
        button_continue: this.I18n.t('js.types.attribute_groups.more_information'),
        button_cancel: this.I18n.t('js.types.attribute_groups.nevermind'),
      },
    }).then(() => {
      window.location.href = 'https://www.openproject.org/enterprise-edition/?utm_source=unknown&utm_medium=community-edition&utm_campaign=form-configuration';
    })
      .catch(() => {
      });
  }
}
