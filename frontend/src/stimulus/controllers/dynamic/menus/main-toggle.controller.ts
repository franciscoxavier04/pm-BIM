import { Controller } from '@hotwired/stimulus';
import { MainMenuToggleService } from 'core-app/core/main-menu/main-menu-toggle.service';

export default class MainToggleController extends Controller {
  mainMenuService:MainMenuToggleService;

  initialize() {
    console.count("INIT");

  }

  async connect() {
    console.count("CONNECT");
    await window.OpenProject.getPluginContext()
      .then((pluginContext) => pluginContext.injector.get(MainMenuToggleService))
      .then((service) => {
        this.mainMenuService = service;
        this.mainMenuService.initializeMenu();
      });
  }

  toggleNavigation(e:Event) {
    this.mainMenuService.toggleNavigation(e);
  }
}
