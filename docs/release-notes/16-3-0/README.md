---
title: OpenProject 16.3.0
sidebar_navigation:
    title: 16.3.0
release_version: 16.3.0
release_date: 2025-07-31
---

# OpenProject 16.3.0

Release date: 2025-07-31

We released OpenProject [OpenProject 16.3.0](https://community.openproject.org/versions/2204).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes.
At the end, you will find a complete list of all changes and bug fixes.

## Important feature changes

<!-- Inform about the major features in this section -->

## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Redesign the top bar app header using Primer \[[#56583](https://community.openproject.org/wp/56583)\]
- Feature: Allow muting email notifications and ICS for meetings \[[#61773](https://community.openproject.org/wp/61773)\]
- Feature: Show more action in agenda items and outcomes also when meeting is closed \[[#62669](https://community.openproject.org/wp/62669)\]
- Feature: Show % Complete sum also in Status-based progress calculation mode \[[#63191](https://community.openproject.org/wp/63191)\]
- Feature: Health check: Indicate missing token exchange capability \[[#64466](https://community.openproject.org/wp/64466)\]
- Feature: Migrate waffle icon from a normal menu to a overlapping lateral menu \[[#65090](https://community.openproject.org/wp/65090)\]
- Feature: Add copy-able backchannel logout uri to OIDC edit page \[[#65112](https://community.openproject.org/wp/65112)\]
- Feature: Show ongoing timers in &quot;My time tracking&quot; page \[[#65504](https://community.openproject.org/wp/65504)\]
- Feature: Close mobile sidebar menu by outside click \[[#65547](https://community.openproject.org/wp/65547)\]
- Feature: Add Home, My page and My time tracking to the waffle menu \[[#65564](https://community.openproject.org/wp/65564)\]
- Feature: Add delete button to the context menu of time entries \[[#65610](https://community.openproject.org/wp/65610)\]
- Feature: Adapt openDesk waffle menu to look like in OpenProject. \[[#65936](https://community.openproject.org/wp/65936)\]
- Feature: Add the OpenProject logo in the mobile header \[[#66026](https://community.openproject.org/wp/66026)\]
- Bugfix: \[Work-Package\] Move work-package with an invalid user in a custom field \[[#59381](https://community.openproject.org/wp/59381)\]
- Bugfix: Work package pdf export - table width formatting \[[#61037](https://community.openproject.org/wp/61037)\]
- Bugfix: Pattern input dropdown does not overlay background \[[#61937](https://community.openproject.org/wp/61937)\]
- Bugfix: Work package datepicker incorrectly renders turbo frame response \[[#62523](https://community.openproject.org/wp/62523)\]
- Bugfix: Version from the shared work package not available in Version filter on global wp page \[[#62610](https://community.openproject.org/wp/62610)\]
- Bugfix: Project identifier cannot be updated if a required project attribute is created \[[#63668](https://community.openproject.org/wp/63668)\]
- Bugfix: Lose track of meeting item and switch to template editing after adding a backlog agenda item \[[#64106](https://community.openproject.org/wp/64106)\]
- Bugfix: \[Accessibility\] Contrast issues in avatars, sidebar and graph widget \[[#64230](https://community.openproject.org/wp/64230)\]
- Bugfix: Meeting text fields cleared without warning when status is changed \[[#64260](https://community.openproject.org/wp/64260)\]
- Bugfix: Automatic subject pattern is editable after enterprise token got invalid \[[#64290](https://community.openproject.org/wp/64290)\]
- Bugfix: TreeView is not updated when a new item is added \[[#64557](https://community.openproject.org/wp/64557)\]
- Bugfix: Reminders: When an in-line validation error is displayed and the user corrects it by entering the missing information, dismiss the error \[[#64654](https://community.openproject.org/wp/64654)\]
- Bugfix: cannot load such file -- DummyConfig \[[#64804](https://community.openproject.org/wp/64804)\]
- Bugfix: Possible to deactivate the default work package priority \[[#64842](https://community.openproject.org/wp/64842)\]
- Bugfix: Can&#39;t delete a meeting series \[[#65018](https://community.openproject.org/wp/65018)\]
- Bugfix: Copying project fails with internal error (lock version null) \[[#65021](https://community.openproject.org/wp/65021)\]
- Bugfix: ActiveRecord::Deadlocked from Journals::CreateService#create\_journal \[[#65109](https://community.openproject.org/wp/65109)\]
- Bugfix: Truncation of &quot;Tage&quot; (Days) in duration field when language=DE \[[#65227](https://community.openproject.org/wp/65227)\]
- Bugfix: Wrong focused field in date picker \[[#65236](https://community.openproject.org/wp/65236)\]
- Bugfix: &quot;My spent time&quot; widget unexpectedly caching entries \[[#65509](https://community.openproject.org/wp/65509)\]
- Bugfix: Time entry without start and end time display lateral handles that are unactionable on calendar view \[[#65516](https://community.openproject.org/wp/65516)\]
- Bugfix: Log time cards of 30min generate an overlap with next time entry \[[#65520](https://community.openproject.org/wp/65520)\]
- Bugfix: TypeError in goodjob worker \[[#65557](https://community.openproject.org/wp/65557)\]
- Bugfix: Wrong selected menu, when moving from my page to a WP page \[[#65616](https://community.openproject.org/wp/65616)\]
- Bugfix: NoMethodError in  TimeEntriesController \[[#65622](https://community.openproject.org/wp/65622)\]
- Bugfix: Use WorkPackage::InfoLine and top-align rows in my time tracking border box table \[[#65626](https://community.openproject.org/wp/65626)\]
- Bugfix: Second line of breadcrumb is not properly left-aligned on non-mobile/desktop viewports \[[#65635](https://community.openproject.org/wp/65635)\]
- Bugfix: Notification center WP Overview tab: Link to project not working \[[#65652](https://community.openproject.org/wp/65652)\]
- Bugfix: NoMethodError in Storages::CopyProjectFoldersJob#perform \[[#65710](https://community.openproject.org/wp/65710)\]
- Bugfix: Poor performance on a number of API endpoints (i.e. slow work package table) \[[#65718](https://community.openproject.org/wp/65718)\]
- Bugfix: Entra user can not be found during sign in after being provisioned by SCIM client. \[[#65739](https://community.openproject.org/wp/65739)\]
- Bugfix: Server error when cancelling OAuth flow \[[#65836](https://community.openproject.org/wp/65836)\]
- Bugfix: NoMethodError in GET::API::V3::Queries::QueriesAPI#/queries/:id/ \[[#65866](https://community.openproject.org/wp/65866)\]
- Bugfix: Meeting status captions are underlined \[[#65869](https://community.openproject.org/wp/65869)\]
- Bugfix: Multi-language input broken in Administration &gt; Email Notifications, User Settings \[[#65886](https://community.openproject.org/wp/65886)\]
- Bugfix: ActionMenu SubMenu does not support dividers \[[#65898](https://community.openproject.org/wp/65898)\]
- Bugfix: JavaScript error when adding a new story in Backlogs module \[[#65927](https://community.openproject.org/wp/65927)\]
- Bugfix: On My tracking page, clicking on Today doesn&#39;t always take you to the current day \[[#65966](https://community.openproject.org/wp/65966)\]
- Bugfix: Hierarchy left side box doesn&#39;t go down the whole page \[[#65971](https://community.openproject.org/wp/65971)\]
- Bugfix: openproject run bundle exec rake redmine:email:receive\_imap delivers warnings to email every 5 minutes \[[#65993](https://community.openproject.org/wp/65993)\]
- Bugfix: Cursor jumps to the front in PatternInput \[[#66089](https://community.openproject.org/wp/66089)\]
- Bugfix: OpenID Connect: Claims and ACR values are not being used \[[#66217](https://community.openproject.org/wp/66217)\]
- Bugfix: NoMethodError on Storages::CopyProjectFoldersJob#perform \[[#66221](https://community.openproject.org/wp/66221)\]
- Bugfix:  ArgumentError in  GET::API::V3::Storages::StorageOpenAPI#/storages/:storage\_id/open/ \[[#66225](https://community.openproject.org/wp/66225)\]
- Bugfix: NoMethodError in Storages::Admin::HealthStatusController#create\_health\_status\_report \[[#66226](https://community.openproject.org/wp/66226)\]
- Bugfix: Storages::Adapters::Errors::UnknownProvider in Storages::Admin::StoragesController#new \[[#66227](https://community.openproject.org/wp/66227)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to our sponsors for this release.
Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
Special thanks for reporting and finding bugs go to Sven Kunze, Michael Lathion, Gábor Alexovics, Tom Gugel.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings!
Would you like to help out with translations yourself?
Then take a look at our translation guide and find out exactly how you can contribute.
It is very much appreciated!

