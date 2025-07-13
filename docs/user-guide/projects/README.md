---
sidebar_navigation:
  title: Projects
  priority: 600
description: Manage projects in OpenProject
keywords: manage projects
---
# Manage projects

In OpenProject you can create projects to collaborate with your team members, track issues, document and share information with stakeholders, organize things. A project is a way to structure and organize your work in OpenProject.

Your projects can be available publicly or internally. OpenProject does not limit the number of projects, neither in the Community edition nor in the Enterprise cloud or in Enterprise on-premises edition.

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Select a project](../../getting-started/projects/#open-an-existing-project) | Open a project which you want to work at.                    |
| [Create a new project](../../getting-started/projects/#create-a-new-project) | Find out how to create a new project in OpenProject.         |
| [Create a subproject](/project-settings/#create-a-subproject) | Create a subproject of an existing project.                  |
| [Project structure](#project-structure)                      | Find out how to set up a project structure.                  |
| [Project settings](/project-settings)                        | Configure further settings for your projects, such as description, project hierarchy structure, or setting it to public. |
| [Project lists](/project-lists)                              |                                                              |
| [Change the project hierarchy](/project-settings/change-the-project-hierarchy) | You can change the hierarchy by selecting the parent project ("subproject of"). |
| [Set a project to public](/project-settings/#make-a-project-to-public) | Make a project accessible for (at least) all users within your instance. |
| [Create a project template](./project-templates/#create-a-project-template) | Configure a project and set it as template to copy it for future projects. |
| [Use a project template](./project-templates/#use-a-project-template) | Create a new project based on an existing template project.  |
| [Copy a project](/project-settings/#copy-a-project)          | Copy an existing project.                                    |
| [Archive a project](/project-settings/#archive-a-project)    | Find out how to archive completed projects.                  |
| [Delete a project](/project-settings/#delete-a-project)      | How to delete a project.                                     |

![Video](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Projects-Introduction.mp4)

## Project structure

Projects build a structure in OpenProject. You can have parent projects and sub-projects. A project can represent an organizational unit of a company, e.g. to have issues separated:

* Company (Parent project)
  * Marketing (Sub-project)
  * Sales
  * HR
  * IT
  * ...

Also, projects can be for overarching teams working on one topic:

* Launch a new product
  * Design
  * Development
  * ...

Or, a project can be to separate products or customers.

* Product A
  * Customer A
  * Customer B
  * Customer C

OpenProject, for example, uses the projects to structure the different modules/plugin development:

![project hierarchy select project](image-20220728200830893.png)

> [!NOTE]
> You have to be a [member](../members/#add-members) of a project in order to see the project and to work in a project.

## Select a project

Find out in our Getting started guide [how to open an existing project](../../getting-started/projects/#open-an-existing-project) in OpenProject.

## Create a new project

Find out in our Getting started guide how to [create a new project](../../getting-started/projects/#create-a-new-project) in OpenProject.

## Create a subproject

Find out how to [create a subproject](/project-settings) in OpenProject. 

## Project Settings

You can specify further advanced settings for your project. Navigate to your project settings by [selecting a project](../../getting-started/projects/#open-an-existing-project), and click -> *Project settings* -> *Information*. Here you can: 

- Define whether the project should have a parent by selecting **Subproject of**. This way, you can [change the project hierarchy](#change-the-project-hierarchy).

- Enter a detailed description for your project.

- Set the default project **Identifier**. 

- Set a project to **Public**. This means it can be accessed without signing in to OpenProject.

Read the full guide on [project settings in OpenProject](/project-settings).

