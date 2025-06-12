---
sidebar_navigation:
  title: Project life cycle
  priority: 400
description: Viewing, creating and modifying project phases and gates in OpenProject
keywords: project life cycle, project phase, project phase gate, project settings
---

# Project life cycle (Enterprise add-on)

> [!NOTE]
> Defining project phases for the project life cycle is an Enterprise add-on and can only be used with [Enterprise cloud](../../../enterprise-guide/enterprise-cloud-guide/)
> or [Enterprise on-premises](../../../enterprise-guide/enterprise-on-premises-guide/). An upgrade from the free Community edition is easy and helps support OpenProject.

## Overview

The *Project life cycle* feature allows organizations to define and visualize structured project phases across all projects and portfolios. This makes it easier to:

- Track the current stage of any project at a glance
- Understand portfolio-level progress
- Support decision-making and project governance

Each life cycle consists of multiple **project phases**, and each phase can optionally include **start** and **finish phase gates**. These help mark formal checkpoints within your project’s timeline.

Project phases appear in the **overview page** of each project, helping teams clearly communicate project progress.

Existing projects created before the life cycle feature is enabled will not automatically have project phases or gates enabled. New projects will also have this feature disabled by default — you must manually enable it for each project after setup.

> [!NOTE]
>
> While project phases and gates can be customized globally in system administration, they **cannot** be modified per individual project, only enabled or disabled.

## Manage project phases

To manage project phases and gates, navigate to:  *Administration → Projects → Project life cycle*.

By default, OpenProject includes four standard project phases:

- **Initiating**
- **Planning**
- **Executing**
- **Closing**

Each phase can have a **start gate** and/or a **finish gate**, which are optional and configurable.

![Project phases listed in OpenProject administration](openproject_userguide_project_settings_life_cycle.png)

### Reorder phases

Project phases are listen in order. You can rearrange the order of the phases within **system administration**:

- Use **drag and drop** to move phases into the desired order

- Or click the **More** menu (three dots icon) and select **Move up** or **Move down**

  ![Reorder project phases under OpenProject system settings](openproject_userguide_project_settings_life_cycle_move.png)

> [!NOTE]
>
> The order of project phases is **system-wide** and cannot be changed per project.

### Add a project phase 

To add a new project phase go to *Administration → Projects → Project life cycle* and click the **+ Add** button. You can then enter a name for the new phase and choose a color to visually distinguish the phase. Click **Create**. 

![Add a new project phase under project life cycles in OpenProject system administration](openproject_userguide_project_settings_life_cycle_add_new.png)

### Add a phase gate

After creating the phase, navigate to the *Phase gate* tab and activate and name start and/or finish phase gates. 

![Add phase gates under project life cycle settings in OpenProject administration](openproject_userguide_project_settings_life_cycle_add_new_gates.png)

### Edit a project phase

To modify an existing project phase:

- Click the phase name directly, or
- Click the More menu (three dots icon) next to the phase and choose *Edit*

To edit the gates associated with a phase, switch to the Phase gate tab and make the necessary adjustments.

![Edit project phases under OpenProject system settings](openproject_userguide_project_settings_life_cycle_edit.png)

### Delete a project phase

To delete an existing project phase click the More menu (three dots icon) next to the phase and choose *Delete*.

![Delete project phases under OpenProject system settings](openproject_userguide_project_settings_life_cycle_delete.png)