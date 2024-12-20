import { Title } from '@angular/platform-browser';
import { Injectable } from '@angular/core';

const titlePartsSeparator = ' | ';

@Injectable({ providedIn: 'root' })
export class OpTitleService {
  constructor(private titleService:Title) {
  }

  public get base():string {
    const appTitle = document.querySelector('meta[name=app_title]') as HTMLMetaElement;
    return appTitle.content;
  }

  public setFirstPart(value:string) {
    const newTitle = [value, this.base].join(titlePartsSeparator);
    this.titleService.setTitle(newTitle);
  }
}
