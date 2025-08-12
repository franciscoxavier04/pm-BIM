---
sidebar_navigation:
  title: My page
  priority: 300
description: My page in OpenProject - your personal dashboard
keywords: my page, personal overview page, dashboard
---

# My page

The My page is your **personal dashboard** with important overarching project information, such as work package reports, news, spent time, or a calendar. It can be configured to your specific needs.

| Topic                                           | Content                                    |
| ----------------------------------------------- | ------------------------------------------ |
| [My page introduction](#my-page-introduction)   | What is My page and what can I do with it? |
| [Configure the My page](#configure-the-my-page) | How to add and edit widgets on My page.    |
| [My spent time widget](#my-spent-time-widget)   | How to track spent time on My page.        |

## My page introduction

My page is your personal dashboard where you can display important information of your projects. This personal dashboard contains information from all your projects. **My page** can be configured according to your preferences. You can include project information, for example the latest news, work packages assigned to you or reported work packages.

You can open your **My page** by clicking on your user avatar in the upper right corner and then selecting **My page** from the overlay menu. Alternatively, you can select *My Page* by clicking the respective option in the menu on the left. 

![Navigate to My page in OpenProject](openproject_getting_started_my_page_navigate.png)

You can also click the grid icon in the top left corner and select the *My page* option from the menu that will open.

![Grid icon in the top left corner of OpenProject head navigation](openproject_getting_started_my_page_grid_icon.png)



![An overlay menu showing global modules and further options in the head navigation in OpenProject](openproject_getting_started_my_page_grid_icon_menu_opened.png)

As a default, you will see two lists of all **work packages assigned to you** and **work packages created by you** from all your projects.

![Default view of My page in OpenProject](openproject_getting_started_my_page_default_view.png)

## Configure the My page

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Quick_guide-Widgets.mp4"></video>

### Add widgets

In order to **add a widget to My page**, decide where you want to place the widget (above, below or between the existing widgets) hover to the respective location around the existing widgets. The **+** icon will appear automatically.

![Plus icon to add a new widget to My page in OpenProject](openproject_getting_started_my_page_add_widget_icon.png)

Press the plus icon and choose from a number of different widgets that can be included on your dashboard.

![A list of available widgets in a popover form on My page in OpenProject](openproject_getting_started_my_page_widget_list.png)

For a **detailed explanation of the widgets**, visit the section in the [project overview](../../user-guide/project-overview/#available-project-overview-widgets).

### Change position of the widgets

You can change the position of a widget on the dashboard with drag and drop.

Click the dots next to the title and drag it to the new place.

![Move a widget by drag and drop on My page in OpenProject](openproject_getting_started_my_page_move_widget.png)

### Change the size of a widget

If you click the dots on the lower right hand corner in a widget you can change the size of a widget by pulling the widget left and right, up and down with the mouse.

![Change widget size in OpenProject My page](openproject_getting_started_my_page_resize_widget.png)

### Configure the view of a widget (for work package tables)

You can configure the view of a work package widget to have the information included that you need.

<div class="glossary">
**Work package** is a subset of a project that can be assigned to users for execution, such as Tasks, Bugs, User Stories, Milestones, and more. Work packages have a type, an ID and a subject and may have additional attributes, such as assignee, responsible, story points or target version. Work packages are displayed in a project timeline (unless they are filtered out in the timeline configuration) - either as a milestone or as a phase. In order to use the work packages, the work package module has to be activated in the project settings.

</div>

On a work package widget, click on the button with the three dots and select **Configure view...**

You can configure the work package table (e.g. filter, group, highlight, sort) according to the [filter, sorting and grouping criteria for work packages](../../user-guide/work-packages/work-package-table-configuration/).

![Configure a widget view on My page of OpenProject](openproject_getting_started_configure_widget_view.gif)

### Remove a widget

To delete a widget from the dashboard, click on the three dots in the upper right corner of the widget and select **Remove widget**.

![Remove a widget on My page in OpenProject](openproject_getting_started_my_page_remove_widget.png)

## My spent time widget

> [!NOTE]
>
> Please note that this widget will be deprecated in an upcoming release. Instead of using it, we recommend logging time via [My time tracking module](../../user-guide/time-and-costs/my-time-tracking/). 

To track spent time, [add the **My spent time** widget](#add-widgets) in the My page.

You can directly create new time entries by clicking on the day, change the date with drag and drop, edit or remove time entries.

Watch the short video to see how to activate the spent time widget, add spent time, edit spent time (e.g. change the date or work packages or change the time booked) and delete spent time.

![My page time log](my-page-time-log.gif)
