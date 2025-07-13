---
sidebar_navigation:
  title: Project settings
  priority: 900
description: Configure your project in OpenProject.
keywords: project settings
---
# Project settings

In OpenProject you can customize your project settings. To do this, open a project via the *Select a project* drop-down menu and navigate to *Project settings* in the project menu.

![Project settings module selected in left-hand project menu in OpenProject](openproject_user_guide_project_settings_module.png)

> [!NOTE]
> You need to be a project administrator in order to see and access the project settings.

## Overview

| Topic                                                  | Content                                                      |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| [Project information](project-information)             | Define project name, subproject, description, project status, and much more. |
| [Project life cycle](project-life-cycle)               | Activate or deactivate project phases in a project.          |
| [Project attributes](project-attributes)               | View and edit project attributes in a project.               |
| [Modules](modules)                                     | Activate or deactivate modules in a project.                 |
| [Work package types](work-packages)                    | Activate or deactivate work package types in a project.      |
| [Work package categories](work-packages)               | Create and manage work package categories.                   |
| [Work package custom fields](work-packages)            | Activate or deactivate custom fields for work packages in a project. |
| [Versions](versions)                                   | Create and manage versions in a project.                     |
| [Repository](repository)                               | Activate and manage a SVN or GIT repository for a project.   |
| [Activities (time tracking)](activities-time-tracking) | Activate or deactivate Activities (for time tracking) in a project. |
| [Backlogs settings](backlogs-settings)                 | Manage backlogs settings for a project.                      |
| [Files](files)                                         | Manage the storages connected to the project, add project folders and activate manual attachment uploads. |



Further, in the top right corner you can [add a subproject](../../#create-a-subproject) and edit the **project identifier**. This is the part of the project name shown in the URL, e.g. /demo-project.

![Add a subproject or change a project identifier under project settings in OpenProject](C:/Users/Maya/Documents/GitHub/openproject/docs/user-guide/projects/project-settings/project-information/openproject_user_guide_project_settings_information_subproject_and_identifier.png)

If you click the **three dot** icon, you will see a dropdown menu with the following options: 

- [Copy a project](#copy-a-project)
- [Make a project public](../../#set-a-project-to-public)
- [Archive a project](../../#archive-a-project)
- [Set a project as a template](../../project-templates) 
- [Delete a project](../../#delete-a-project)

![Copy, archive or delete a project in project settings in OpenProject](openproject_user_guide_project_settings_information_more_icon_menu.png)

## Create subproject

Find out how to [create a subproject](/project-settings) in OpenProject. 

To create a subproject for an existing project, navigate to [*Project settings*](#project-settings) -> *Information* and click on the green **+ Subproject** button.

Then follow the instructions to [create a new project](../../getting-started/projects/#create-a-new-project).

## Change project identifier

- The identifier will be shown in the URL.

> [!NOTE]
> Changing the project identifier while the project is already being worked on can have major effects and is therefore not recommended. For example, repositories may not be loaded correctly and deep links may no longer work (since the project URL changes when the project identifier is changed).

## Copy a project

You can copy an existing project by navigating to the [Project settings](project-settings) -> Information. Click the **More** (three dots) menu in the upper right corner and select **Copy**.

![Copy a project under project settings in OpenProject](project-information-copy-project.png)

Give the new project a name. Under **Copy options** select which modules and settings you want to copy and whether or not you want to notify users via email during copying.
You can copy existing [boards](../agile-boards) (apart from the Subproject board) and the [Project overview](../project-overview/#project-overview) dashboards along with your project, too.

![project settings information copy project copy options](project-settigns-copy-project.png)

> [!IMPORTANT]
> **Budgets** cannot be copied, so they must be removed from the work package table beforehand. Alternatively, you can delete them in the Budget module and thus delete them from the work packages as well.

For further configuration open the **Advanced settings**. Here you can specify (among other things) the project's URL (identifier), its visibility and status. Furthermore you can set values for custom fields.

![copy project advanced settings](project-settings-copy-project-advanced-settings.png)

Under the **Copy options** section you can select what additional project data and settings, such as versions, work package categories, attachments, project life cycle and project members should be copied as well.

![Copy options when copying a project in OpenProject](project-settings-copy-project-copy-options.png)

> [!NOTE]
> The File storages options only apply if the template project had a file storage with automatically managed folders activated.

If you select the **File Storages: Project folders** option, both the storage and the storage folders are copied into the new project if automatically managed project folders were selected for the original file storage. For storages with manually managed project folders setup the copied storage will be referencing the same folder as the original project.

If you de-select the **File Storages: Project folders** option, the storage is copied, but no specific folder is set up.

If you de-select the **File Storages** option, no storages are copied to the new project.

Once you are done, click the green **Save** button.

## Make project public

If you want to set a project to be public, you can do so by ticking the box next to "Public" in the [project settings](project-settings) *->Information*.

Setting a project to public will make it accessible to all people within your OpenProject instance.

(Should your instance be [accessible without authentication](../../system-admin-guide/authentication/login-registration-settings/) this option will make the project visible to the general public outside your registered users, too)

## Archive a project

In order to archive a project, navigate to the [project settings](project-settings), and click the **Archive project** button.

> [!NOTE]
> This option is always available to instance and project administrators. It can also be activated for specific roles by enabling the _Archive project_ permission for that role via the [Roles and permissions](../../system-admin-guide/users-permissions/roles-permissions/) page in the administrator settings.

![project settings archive project](project-settings-archive-project.png)

Then, the project cannot be selected from the project selection anymore. It is still available in the **[Project lists](./project-lists)** dashboard if you set the "Active" filter to "off" (move slider to the left). You can un-archive it there, too, using the three dots at the right end of a row.

![project list filter](project-list-filter.png)

You can also archive a project directly on the [project overview page.](../project-overview/#archive-a-project) 

## Set a project as a template



## Change the project hierarchy

To change the project's hierarchy, navigate to the [project settings](project-settings) -> *Information* and change the **Subproject of** in *Project relations* section.

![project settings information change hierarchy](openproject_user_guide_projects_subproject_of.png)



## Delete a project

If you want to delete a project, navigate to the [Project settings](project-settings). Click the button **Delete project** on the top right of the page.

![delete a project](delete-a-project.png)

You can also delete a project via the [projects overview list](./project-lists/).

> [!NOTE]
> Deleting projects is only available for System administrators.
