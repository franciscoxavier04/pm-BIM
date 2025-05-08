# Automatic subjects

## 1. Introduction

Automatic subjects are predefined, dynamic work package titles. They are useful for enforcing consistency and clarity in the naming of repetitive tasks. They can be enabled per work package type. Admins can set up a **subject pattern** adding free text and referencing attributes like Author, Start date, custom fields or even parent and project attributes. When users create or edit such a work package, the subject is automatically generated and updated.

**Examples:**

Vacation request: `[Author] [Start date] - [Finish date]`
Candidate interview: `[Custom Field: Candidate] with [Assignee] on [Start date]`

Supplier invoice: `[Author] Invoice [Creation date] - [Custom Field: Invoice ID]`

If you notice a locked subject, it means your admin has enforced an automatic subject pattern for that work package type (e.g. vacation requests or invoices). 

> [!IMPORTANT]
> If you cannot edit a subject it can also mean that you lack permissions to edit this work package. 

## 2. How to use automatic subjects

Work packages with automatic subjects behave like regular work packages, with one key difference:

*   **Creating or editing**: You enter details normally but without filling out the subject.

*   **Subject is read-only**: The title field is automatically filled and cannot be manually edited.


> **Tip**: When you update any attribute of a work package it will automatically update the subject independently if the changed attribute is part of the subject pattern or not.

## 3. How attribute values appear in the subject

Automatic subjects display actual attribute values configured by your admin, such as:

*   **Dates** (e.g., `[Start date]`, `[Finish date]`)

*   **Users** (e.g., `[Author]`, `[Assignee]`)

*   **Attributes** (e.g., `[Priority]`, `[Category]`, `[Custom Field: X]`)

*   **Project details** (e.g., `[Project name]`, `[Project identifier]`)

If a referenced attribute is not available in this project **&quot;N/A&quot;** appears in its place (see [FAQ](https://community.openproject.org/#4-faq)).

If a referenced attribute has no value set yet, **[Attribute Name]** appears in the work package subject.


## 4. FAQ

### How does the subject update automatically?

When attributes referenced in the pattern change (e.g., date or custom field), the subject regenerates automatically upon saving. No manual action needed.

### What if the subject pattern references parent or project attributes?

If the pattern includes attributes from a **parent work package** or the **project**, changes in the parent or project won’t immediately update the child subject. The subject refreshes only when you update and save the child work package. This limitation will be improved in a future release.

### Why does &quot;N/A&quot; appear in my subject?

&quot;N/A&quot; indicates an unavailable attribute referenced in the subject pattern. This can happen in several scenarios:


*   The pattern references an attribute from a **parent work package**, but no parent is set.

*   The parent exists, but the referenced attribute **is not available** in the parent’s work package type.

*   The attribute referenced in the pattern **is not activated** for the current project.


Once the attribute becomes available and has a valid value, updating and saving the work package automatically refreshes the subject accordingly.

> **Example**: Pattern: `INVOICE: [Custom Field: Invoice ID] - [Start date]`  
> If &quot;Invoice ID&quot; is empty or unavailable, you’ll see `INVOICE: N/A - 2025-01-23`.

## 5. Why [Attribute Name] appears in subjects

[Attribute Name] indicates an empty attribute referenced in the subject pattern.

- The attribute hasn't been filled by the user.
- A parent attribute is referenced, but no parent is set.
- A project attribute is referenced, but hasn't been filled.

