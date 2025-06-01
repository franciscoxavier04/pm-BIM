---
sidebar_navigation:
  title: Test Management with OpenProject 
  priority: 950
description: OpenProject can be configured to support lightweight test management using custom work package types and project templates. This guide describes how to manage test cases and test runs in a reusable, scalable way.
keywords: test plan, test case, test case, test management

---

## Purpose

This document describes a configuration approach for using OpenProject as a lightweight test management system. The goal is to support manual or semi-automated test processes directly within OpenProject by modeling test cases, test runs, and test planning using native features.

The described setup assumes that OpenProject is already in use for project planning, task tracking, or requirements management, and extends it to cover testing activities without introducing an additional tool.

## Scope and assumptions

This setup is suitable for:

- Teams who want to track test definitions and test executions in OpenProject
- Scenarios where manual test steps or external automated test triggers exist
- Projects that benefit from structuring tests per release or version

It is not intended to replace specialized test management tools where advanced test parameterization, automated execution orchestration, or lab device control are required.

## Conceptual model

| Concept            | OpenProject entity                                |
| ------------------ | ------------------------------------------------- |
| Test plan          | Project (created from a test plan template)       |
| Test case          | Work package type `Test Case`                     |
| Test run           | Work package type `Test Run` (child of test case) |
| Version under test | OpenProject *Version* field on test runs          |

Each test plan is realized as a separate project, created from a project template. Test cases are work packages that describe what to test. Test runs are child work packages, used to track execution results.

![diagram showing the different entities of test management in OpenProject](test-management-entities.png)

## Setup

### Work package types

Define two types under *Administration → Work packages → Types*:

#### Test case

- Describes a test scenario
- Fields: title, description (steps, expected outcome)
- May include custom fields such as category or priority
- Acts as a parent for one or more `Test Run` work packages

#### Test run

- Documents a single execution of a test case
- Fields: status, actual result, version under test
- Related to its `Test Case` via parent-child relation
- Status values may include: `New`, `In progress`, `Passed`, `Failed`, `Blocked`

Optionally define a workflow limiting status transitions.

### Project template

Create a project that will act as a reusable test plan template:

1. Create a new project and enable the modules:  
   *Work packages*, *Wiki* (optional), *Boards* (optional)

2. Add work packages of type `Test Case` and, under each, one or more `Test Run` entries

3. Assign all test runs to a placeholder version (e.g., “X.Y”)

4. Enable “Use as template” in the project settings

This project defines the reusable structure to be used for every test campaign.

## Test execution workflow

1. Create a new project from the test plan template  
   Example: `Test plan – release 2.0`

2. Rename or create the appropriate version (e.g., `2.0.0`) and assign it to the test runs

3. Testers execute the tests:  
   - Update status (`Passed`, `Failed`, `Blocked`)  
   - Enter actual results and optional attachments

4. Link failed runs to defect work packages where applicable

## Tracking and queries

Use the following views and filters to track test progress:

- Hierarchy view: show test runs nested under their test case
- Filter by version: isolate one release
- Group by status: see pass/fail distribution
- Use the “% done” field on test runs to drive parent test case progress
- Optionally use boards to visualize execution flow

## Version handling

- Use OpenProject's built-in *Version* entity to tag each test run with the relevant software version
- When copying a template project, a placeholder version is cloned and can be renamed to match the actual release
- Versions can also be managed centrally across subprojects if needed

## Optional: automation and CI integration

Test runs can be created or updated via the OpenProject REST API. Example use cases:

- CI pipeline triggers a test run and updates its result
- External test tools push execution logs or artifacts into the work package

OpenProject also supports integrations with GitHub and GitLab for pull request tracking and build status visibility, which can complement this setup.

## Summary

This setup provides a structured way to manage manual and semi-automated tests using OpenProject:

- Test definitions (test cases) and executions (test runs) are modeled as work packages
- A project template serves as a reusable test plan
- Execution status, version coverage, and defects are tracked in a unified system

This approach is suitable for teams that require basic test tracking integrated into existing project structures with minimal additional tooling.
