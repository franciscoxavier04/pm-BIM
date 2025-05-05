---
title: OpenProject 16.0.0
sidebar_navigation:
    title: 16.0.0
release_version: 16.0.0
release_date: 2025-05-01
---

# OpenProject 16.0.0

Release date: 2025-05-01

We released OpenProject [OpenProject 16.0.0](https://community.openproject.org/versions/1412). This major release contains many features and bug fixes and we recommend updating to the newest version. In these Release Notes, we will give an overview of important updates, important feature changes and important technical updates. At the end, you will find a complete list of all changes and bug fixes for 16.0.

## Important updates

The Enterprise plans (Basic, Professional, Premium, and Corporate) have been updated. Each plan now includes a specific set of Enterprise add-ons. Support levels and pricing remain unchanged.

Current Enterprise customers retain their existing plans with access to all Enterprise add-ons available at that time. No features are removed.

From this version onward, new Enterprise add-ons may be included only in higher-tier plans. For example, the new Internal comments feature (more information below) is part of the Professional plan.

Customers on lower Enterprise plans who want to try out new add-ons from higher plans can do so by [requesting a new Enterprise trial token (on-premises)](https://www.openproject.org/contact/) or by starting a new Cloud trial instance.

More details are available in the updated [Enterprise guide](https://www.openproject.org/docs/enterprise-guide/).

## Important feature changes

## Meeting backlogs

Meeting organization becomes even easier with OpenProject 16.0: Meeting backlogs allow users to collect, manage, and prepare agenda items more flexibly — both for one-time meetings and for recurring meeting series.

In one-time meetings, the new **Agenda backlog** stores topics that are not yet assigned to the current meeting but may be added later.

**Screenshot**

In recurring meetings, the shared **Series backlog** helps track open points across all meeting occurrences and move items between them as priorities change.

**Screenshot**

Agenda items can easily be moved from the backlog to a meeting — or back to the backlog if an agenda item needs to be postponed. Work packages can also be added directly to the backlog. Even meetings without current agenda items can maintain a backlog of important topics.

Meeting backlogs support better preparation, more flexibility, and a clearer structure for meeting management in OpenProject.

### End of classic meetings

With version 16.0, the 'classic’ option will no longer be offered when creating a new meeting in OpenProject. With the release of meeting outcomes and now also meeting backlogs, classic meetings are considered outdated.

No data will get lost with the update, apart from the Meeting history of your classic meetings. If you used classic meetings in the past, see [this blog article](https://www.openproject.org/blog/end-classic-meetings-may-2025/) to learn more about the change and the reasons behind it.

## Release to Community: Graphs on project overview page

From time to time an Enterprise add-on is released for the free Community version. We are happy to announce that with OpenProject 16.0, the **graphs on the project overview page are now available in all editions**. This means that Community users can now display graphs directly on the project overview page to visualize important project information and communicate project status to the team and management.

The work package graph widgets display information about the work packages within a project and can be shown in different views, such as bar graphs or pie charts.

[Learn more about this feature in our user guide]([../../user-guide/project-overview/#work-package-graph-widgets-enterprise-add-on](https://www.openproject.org/docs/user-guide/project-overview/#work-package-graph-widgets-enterprise-add-on).

**Screenshot**

## Internal comments in work packages (Enterprise add-on)

Users of the Enterprise Professional version are now able to communicate internally in the work package Activity tab. To use this feature, a project admin has to enable internal comments. By default, these are only visible to the project admin role, but administrators can grant a new set of permissions to any number of roles.

Users with these permissions then see an "Internal comment" checkbox when adding a new comment. If they check this box, the comment will only be visible to other people with these permissions. The different background color indicates that a comment is internal. 

**Screenshot**

## Automatically generated work package subjects (Enterprise add-on)

OpenProject now supports automatically generated subjects for work packages. This new Enterprise add-on, available in the Professional plan, allows administrators to define subject patterns for each work package type. When enabled, the subject field is filled automatically and becomes non-editable during work package creation and updates.

This is especially useful for structured processes such as vacation requests, IT tickets, or maintenance reports, where consistent naming is required. Subject patterns can include static text as well as dynamic placeholders like project name, work package type, or custom field values.

More details and examples can be found in our [blog article on automatically generated work package subjects](https://www.openproject.org/blog/automatically-generated-work-package-subjects/).

Screenshot

## Separate time tracking module with calendar view

OpenProject 16.0 offers a separate time tracking module with a calendar view. It is accessible from the global view and listed in the left side bar navigation called 'My Time tracking'. There, users can view and edit their logged time with start and end times. The user can switch between daily, weekly, work weekly and monthly views and also log new time entries directly by clicking in the calendar.

Each day shows the sum of the tracked time, and in the weekly and monthly views, the total tracked time is displayed in the lower right corner.

**Screenshot**

### Time entries with legally required mandatory fields: start time and finish time

Before 16.0, time reports only included the duration of the logged time, not the explicit start and end time. Now, they also show start and finish time. This applies to the new time tracking module as well as PDF timesheets.

### Overview of time logged per day per user in PDF timesheet

Exported PDF timesheets now include an overview of logged time per day and user. It is displayed in a table view at the beginning of the report. If the list contains more than five users, the view is split into several tables.

**Screenshot**

## Add parent item to relations

text https://community.openproject.org/wp/38030

screenshot

## Save work package export configuration

When exporting a single work package, users can now save their configuration settings, e.g. the file format or the display and order of the columns. This saves time and allows users to share the export settings with their team (e.g. for a defects and approval report).

Screenshot

## Storage Health status: Multiple visible checks and download option (Enterprise add-on)

The Health check for storages has been extended in OpenProject 16.0. Administrators can now view **multiple visible results**, grouped into base configuration, authentication, and automatically-managed folders. Each group displays a short summary indicating whether all checks passed, warnings occurred, or failures were detected. If issues are found, a link to detailed documentation is provided.

The summary of the most recent health check remains visible in the sidebar. In addition, a new option allows administrators to open a **full detailed report** to review all individual checks directly.

To make troubleshooting even easier, administrators can now also **download** the complete health check report as a text file, for example to include in a support request.

## Option to select favorite project tab as default in project quick search

small but helpful feature...

## Important technical changes

## Seamless integration of user sessions of Nextcloud and OpenProject using OIDC & JWTs (Enterprise add-on)

OpenProject 16.0 introduces a major improvement for customers of the Enterprise Corporate plan that are using Nextcloud alongside OpenProject. Through a new configuration based on OpenID Connect (OIDC) and JSON Web Tokens (JWTs), OpenProject and Nextcloud can now integrate user sessions seamlessly without showing separate consent screens in each application.

Instead of mutually acting as OAuth servers and clients, both OpenProject and Nextcloud can now authenticate against a common Identity Provider (IDP). This allows OpenProject to reuse the user session to call Nextcloud APIs directly — improving the user experience and reducing complexity in daily workflows.

Please see our documentation to learn how to set up this integration.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Internal comments in the work package activity tab \[[#31163](https://community.openproject.org/wp/31163)\]
- Feature: Seamless integration of user sessions of Nextcloud and OpenProject using OIDC &amp; JWTs \[[#52828](https://community.openproject.org/wp/52828)\]
- Feature: Automatically generated work package subjects \[[#53653](https://community.openproject.org/wp/53653)\]
- Feature: Meeting backlogs \[[#54751](https://community.openproject.org/wp/54751)\]
- Feature: Apply standardized component for PageHeaders &amp; SubHeaders in the missing rails based pages \[[#58155](https://community.openproject.org/wp/58155)\]
- Feature: Introduce enterprise plans \[[#62469](https://community.openproject.org/wp/62469)\]
- Feature: Add parent item to relations \[[#38030](https://community.openproject.org/wp/38030)\]
- Feature: File storages settings for type Nextcloud: Allow OIDC based connection instead of OAuth2 \[[#55284](https://community.openproject.org/wp/55284)\]
- Feature: Option to select favorite project tab as default in project quick search \[[#55792](https://community.openproject.org/wp/55792)\]
- Feature: Extend Nextcloud files storage to use SSO access tokens  \[[#57056](https://community.openproject.org/wp/57056)\]
- Feature: Save export configuration for next export of a view \[[#57388](https://community.openproject.org/wp/57388)\]
- Feature: Store token exchange capability on OIDC providers \[[#58862](https://community.openproject.org/wp/58862)\]
- Feature: Track start time, finish time, and duration in Log time dialog \[[#59038](https://community.openproject.org/wp/59038)\]
- Feature: Separate time tracking module with calendar view for logged time with start and finish time \[[#59376](https://community.openproject.org/wp/59376)\]
- Feature: Define subject patterns in work package type settings \[[#59909](https://community.openproject.org/wp/59909)\]
- Feature: Prevent editing of subject on work package creation and update \[[#59910](https://community.openproject.org/wp/59910)\]
- Feature: Block users from editing managed subjects of work packages in table views \[[#59911](https://community.openproject.org/wp/59911)\]
- Feature: Add times for labor costs to the cost report and export \[[#59914](https://community.openproject.org/wp/59914)\]
- Feature: Update PageHeaders &amp; SubHeaders in the (rails) project pages (Part 2) \[[#59915](https://community.openproject.org/wp/59915)\]
- Feature: Add enterprise banner to subject configuration \[[#59929](https://community.openproject.org/wp/59929)\]
- Feature: Support OIDC in storage health status \[[#60161](https://community.openproject.org/wp/60161)\]
- Feature: Export metrics in prometheus format \[[#60181](https://community.openproject.org/wp/60181)\]
- Feature: Enterprise banner (Professional Edition) for Nextcloud SSO authentication \[[#60612](https://community.openproject.org/wp/60612)\]
- Feature: Add start and end times to the API \[[#60633](https://community.openproject.org/wp/60633)\]
- Feature: Amend work package comment href from \`#activity-&lt;journal-sequence&gt;\` to \`#comment-&lt;journal-id&gt;\` with backwards compatibility for old links \[[#60875](https://community.openproject.org/wp/60875)\]
- Feature: Introduce internal comments \[[#60977](https://community.openproject.org/wp/60977)\]
- Feature: Enterprise/Professional upsale banners for internal comments \[[#61061](https://community.openproject.org/wp/61061)\]
- Feature: Trigger browser confirmation dialog when clicking on &#39;Mark all as read&#39; \[[#61309](https://community.openproject.org/wp/61309)\]
- Feature: Cosmetic UI optimisations to the emoji reactions \[[#61402](https://community.openproject.org/wp/61402)\]
- Feature: Allow to configure SSO authentication + two-way OAuth 2 \[[#61532](https://community.openproject.org/wp/61532)\]
- Feature: Storage Health status: Multiple visible checks \[[#61556](https://community.openproject.org/wp/61556)\]
- Feature: Audience selection for Nextcloud Hub scenario \[[#61623](https://community.openproject.org/wp/61623)\]
- Feature: Validate subject pattern \[[#61692](https://community.openproject.org/wp/61692)\]
- Feature: Form input: introduce a smaller input size for date/time \[[#61779](https://community.openproject.org/wp/61779)\]
- Feature: Link to new OIDC docs from storages setup \[[#61839](https://community.openproject.org/wp/61839)\]
- Feature: Primerize Project Settings &gt; Information form \[[#61889](https://community.openproject.org/wp/61889)\]
- Feature: Overview of time logged per day per user in PDF timesheet \[[#61896](https://community.openproject.org/wp/61896)\]
- Feature: Add leading character to pattern input to initiate search \[[#62150](https://community.openproject.org/wp/62150)\]
- Feature: Consistent permissions for meetings modules \[[#62175](https://community.openproject.org/wp/62175)\]
- Feature: Allow to set authentication method and storage audience via API \[[#62191](https://community.openproject.org/wp/62191)\]
- Feature: Hide authentication method for &quot;SSO with Fallback&quot; \[[#62192](https://community.openproject.org/wp/62192)\]
- Feature: \[openproject-subscriptions\] Support for v5 tokens with features restricted on a per-plan basis \[[#62268](https://community.openproject.org/wp/62268)\]
- Feature: Don&#39;t show work package comment inline attachments in Files tab \[[#62356](https://community.openproject.org/wp/62356)\]
- Feature: Validate scope of JWTs \[[#62360](https://community.openproject.org/wp/62360)\]
- Feature: Add information about current restrictions of &quot;Automatic subjects&quot; \[[#62368](https://community.openproject.org/wp/62368)\]
- Feature: Implement cross-plan upsale \[[#62471](https://community.openproject.org/wp/62471)\]
- Feature: Allow generation of Enterprise plan tokens in enterprise-tokens repo \[[#62548](https://community.openproject.org/wp/62548)\]
- Feature: Allow booking &quot;Premium&quot; plan in SaaS \[[#62573](https://community.openproject.org/wp/62573)\]
- Feature: Create a \`BorderBox::CollapsibleHeader\` component \[[#62577](https://community.openproject.org/wp/62577)\]
- Feature: Migrate classic meeting functionality into dynamic meetings \[[#62621](https://community.openproject.org/wp/62621)\]
- Feature: Introduce enterprise banner for enforced start &amp; end time tracking \[[#62624](https://community.openproject.org/wp/62624)\]
- Feature: Create a CollapsibleSectionComponent  \[[#62754](https://community.openproject.org/wp/62754)\]
- Feature: Storage sidebar button in projects should behave correctly in all scenarios \[[#62758](https://community.openproject.org/wp/62758)\]
- Feature: Show warning if a user tries to uncheck the &#39;Internal comment&#39; checkbox when there&#39;s already text in the comment box \[[#62785](https://community.openproject.org/wp/62785)\]
- Feature: Replace banner on home page \[[#62843](https://community.openproject.org/wp/62843)\]
- Feature: Additional protections for internal comments in places where comments are accessed \[[#62988](https://community.openproject.org/wp/62988)\]
- Feature: Check the accessibility on CollapsibleSectionComponent &amp; CollapsibleHeaderComponent \[[#63275](https://community.openproject.org/wp/63275)\]
- Feature: Time tracking list view \[[#63336](https://community.openproject.org/wp/63336)\]
- Feature: Communicate dangers of automatic self registration \[[#63379](https://community.openproject.org/wp/63379)\]
- Feature: Download Storage Health status report \[[#63467](https://community.openproject.org/wp/63467)\]
- Feature: Create Project Status Component \[[#63482](https://community.openproject.org/wp/63482)\]
- Feature: Add error codes to health check results \[[#63518](https://community.openproject.org/wp/63518)\]
- Feature: Implement medium banner component \[[#63525](https://community.openproject.org/wp/63525)\]
- Feature: PDF Timesheet: Restore previous overview table and add headlines \[[#63526](https://community.openproject.org/wp/63526)\]
- Feature: Make the SaaS Trial Plan Corporate \[[#63532](https://community.openproject.org/wp/63532)\]
- Feature: Add meeting backlogs \[[#63543](https://community.openproject.org/wp/63543)\]
- Feature: Primerize Administration &gt; Authentication settings \[[#63567](https://community.openproject.org/wp/63567)\]
- Feature: Make SSO feature available to professional plan \[[#63572](https://community.openproject.org/wp/63572)\]
- Feature: Release Enterprise add-on &quot;Graphs on project overview page&quot; to the Community version \[[#63619](https://community.openproject.org/wp/63619)\]
- Feature: Work week available in the view selector of time tracking calendar and list \[[#63621](https://community.openproject.org/wp/63621)\]
- Feature: Remove internal comments feature flag \[[#63635](https://community.openproject.org/wp/63635)\]
- Feature: Remove work package comment ID URL feature flag \[[#63646](https://community.openproject.org/wp/63646)\]
- Feature: Show attribute name instead of N/A if attribute is just empty \[[#63660](https://community.openproject.org/wp/63660)\]
- Feature: Implement new homescreen enterprise banner style \[[#63727](https://community.openproject.org/wp/63727)\]
- Feature: Render attribute help texts in Primerized Settings &gt; Information form \[[#63737](https://community.openproject.org/wp/63737)\]
- Bugfix: User is able to edit someone else&#39;s comment \[[#58511](https://community.openproject.org/wp/58511)\]
- Bugfix: Boards search for WorkPackages is too small \[[#58702](https://community.openproject.org/wp/58702)\]
- Bugfix: Quick wins for top bar search \[[#58704](https://community.openproject.org/wp/58704)\]
- Bugfix: String &quot;All&quot; within search cannot be translated \[[#59247](https://community.openproject.org/wp/59247)\]
- Bugfix: Inconsistently used red color for notification bell and ongoing time tracking \[[#59379](https://community.openproject.org/wp/59379)\]
- Bugfix: Broken pages in lookbook \[[#59918](https://community.openproject.org/wp/59918)\]
- Bugfix: Activity Tab renders the same turbo frame multiple times inside of itself \[[#61544](https://community.openproject.org/wp/61544)\]
- Bugfix: Primer Dialog close button ARIA label is not localised \[[#61631](https://community.openproject.org/wp/61631)\]
- Bugfix: Token Refresh and Exchange does not work when Client ID contains special characters \[[#61694](https://community.openproject.org/wp/61694)\]
- Bugfix: Empty audience translation is missing \[[#61855](https://community.openproject.org/wp/61855)\]
- Bugfix: SSO users storage connection does not work on project storage members page  \[[#61880](https://community.openproject.org/wp/61880)\]
- Bugfix: Autocompleter dropdown in pattern input is missing default entry \[[#61935](https://community.openproject.org/wp/61935)\]
- Bugfix: Can&#39;t associate storage to project via storage admin view \[[#61936](https://community.openproject.org/wp/61936)\]
- Bugfix: Pattern input dropdown does not overlay background \[[#61937](https://community.openproject.org/wp/61937)\]
- Bugfix: Input with angle brackets disappears on save but is saved \[[#62040](https://community.openproject.org/wp/62040)\]
- Bugfix: Linking to project storage via SSO fails when user can&#39;t authenticate \[[#62166](https://community.openproject.org/wp/62166)\]
- Bugfix: Updating a work package with generated subject fails, if project is missing custom field \[[#62217](https://community.openproject.org/wp/62217)\]
- Bugfix: Storage shows as healthy even if audience is misconfigured \[[#62237](https://community.openproject.org/wp/62237)\]
- Bugfix: PDF export does not export all embedded screenshots \[[#62293](https://community.openproject.org/wp/62293)\]
- Bugfix: Cannot inline create a WP with auto generated subject when no other attribute is a required field \[[#62318](https://community.openproject.org/wp/62318)\]
- Bugfix: Project attribute list entries not displayed when applied as filter in project list \[[#62386](https://community.openproject.org/wp/62386)\]
- Bugfix: Add missing attributes in subject patterns \[[#62429](https://community.openproject.org/wp/62429)\]
- Bugfix: OpenProject enterprise key domain check is case-sensitive \[[#62520](https://community.openproject.org/wp/62520)\]
- Bugfix: No errors displayed from dates and progress edit modals when unable to save work package \[[#62563](https://community.openproject.org/wp/62563)\]
- Bugfix: Marking a notification as read automatically selects the first notification \[[#62604](https://community.openproject.org/wp/62604)\]
- Bugfix: Version from the shared work package not available in Version filter on global wp page \[[#62610](https://community.openproject.org/wp/62610)\]
- Bugfix: (Regression) Error on Save (in various places) \[[#62627](https://community.openproject.org/wp/62627)\]
- Bugfix: Wrong Uppercase transformation for relationship names \[[#62817](https://community.openproject.org/wp/62817)\]
- Bugfix:  Changing status when adding a picture to a comment  \[[#62845](https://community.openproject.org/wp/62845)\]
- Bugfix: Sum queries (∑) do not display children that are not in the current project in view \[[#62847](https://community.openproject.org/wp/62847)\]
- Bugfix: Exposing restricted comments when polling \[[#62978](https://community.openproject.org/wp/62978)\]
- Bugfix: Gantt module work package list still uses old term &quot;follower&quot; \[[#63351](https://community.openproject.org/wp/63351)\]
- Bugfix: User with a particular set of permissions sees error when updating WP dates \[[#63434](https://community.openproject.org/wp/63434)\]
- Bugfix: Adding or removing successor in relations tab is not correctly reflected in Gantt chart \[[#63437](https://community.openproject.org/wp/63437)\]
- Bugfix: User without permission to manage public view can edit and save the export configuration \[[#63438](https://community.openproject.org/wp/63438)\]
- Bugfix: Health report no longer includes error codes \[[#63440](https://community.openproject.org/wp/63440)\]
- Bugfix: Missing attributes of generated work package subjects are displayed wrongly \[[#63441](https://community.openproject.org/wp/63441)\]
- Bugfix: Missing space when putting multiple CollapsibleSections below each other \[[#63442](https://community.openproject.org/wp/63442)\]
- Bugfix: Collapsed preview not working \[[#63443](https://community.openproject.org/wp/63443)\]
- Bugfix: Sort projects in Favorite Projects widget on My page alphabetically  \[[#63444](https://community.openproject.org/wp/63444)\]
- Bugfix: Missing parent attributes in subject patterns \[[#63483](https://community.openproject.org/wp/63483)\]
- Bugfix: My Time tracking calendar view, does not look properly in dark mode \[[#63548](https://community.openproject.org/wp/63548)\]
- Bugfix: Duplicate work package comments when submitting via ctlr/cmd + enter \[[#63556](https://community.openproject.org/wp/63556)\]
- Bugfix: Bad translations of &quot;All checks passed&quot; for Arabic and Latvian languages \[[#63568](https://community.openproject.org/wp/63568)\]
- Bugfix: My sessions page takes forever to load \[[#63587](https://community.openproject.org/wp/63587)\]
- Bugfix: Boolean custom fields in subject patterns are not supported \[[#63641](https://community.openproject.org/wp/63641)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to City of Cologne, Deutsche Bahn and ZenDiS for sponsoring released or upcoming features. Your support, alongside the efforts of our amazing Community, helps drive these innovations. Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes. Special thanks for reporting and finding bugs go to alex e, Klaas vT, Daniel Elkeles, Marcel Carvalho, Regina Schikora, Çağlar Yeşilyurt, and Александр Татаринцев.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings! This release we would like to particularly thank the following users:
- [name](https://crowdin.com/profile/name), for a great number of translations into [language].


Would you like to help out with translations yourself? Then take a look at our [translation guide](../../contributions-guide/translate-openproject/) and find out exactly how you can contribute. It is very much appreciated!
