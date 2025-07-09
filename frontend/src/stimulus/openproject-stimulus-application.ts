import { ControllerConstructor } from '@hotwired/stimulus/dist/types/core/controller';
import { Application } from '@hotwired/stimulus';

export class OpenProjectStimulusApplication extends Application {
  static controllers = new Map<string, ControllerConstructor>();

  /**
   * Register a controller to be used in the application,
   * allowing it to be registered before the Stimulus application is being initialized.
   *
   * This is useful for plugins that execute code before we call setup.ts
   *
   * @param name the name/identifier of the controller
   * @param controller the controller class
   */
  static preregister(name:string, controller:ControllerConstructor) {
    this.controllers.set(name, controller);
  }

  async start():Promise<void> {
    this.preregisteredControllers.forEach((controller, name) => {
      this.register(name, controller);
    });

    await super.start();
  }

  get preregisteredControllers() {
    return OpenProjectStimulusApplication.controllers;
  }
}
