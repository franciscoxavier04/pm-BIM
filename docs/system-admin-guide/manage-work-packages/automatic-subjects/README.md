# Configuring automatic subjects

This guide explains how administrators configure **automatic subject patterns** for work packages in OpenProject. Subject patterns combine static text with dynamic attributes - such as dates, author names, or custom fields - to automatically generate consistent and informative work package titles.

Automatic subject patterns help teams quickly identify tasks, reduce manual errors, and standardize naming conventions across your projects.



## 1. How subject patterns work

A subject pattern includes a combination of:

- **Static text** (e.g., `Invoice`, `Vacation Request`)
- **Dynamic attribute placeholders** (e.g., `[Author]`, `[Start date]`, `[Custom Field: Invoice ID]`)

When users create or edit work packages, OpenProject automatically replaces these placeholders with real attribute values, generating clear subjects.



## 2. Adding, changing, and deleting attributes

Administrators configure subject patterns using a simple editor in the admin settings:

### 2.1 Adding attributes

1. Navigate to **Administration → Work Package Types**, choose a type, then open **Subject configuration**.
2. Type `/` in the input field to open attribute search.
3. Search for and select an attribute from the dropdown. The chosen attribute appears as a placeholder (e.g., `[Start date]`).

### 2.2 Changing attributes

- Click into an existing attribute placeholder to edit it. This triggers the attribute search again.
- Type and select a different attribute from the dropdown. The placeholder updates automatically.

### 2.3 Deleting attributes

- Delete an attribute placeholder just like regular text (e.g., using backspace).



## 3. Supported attributes and limitations

### 3.1 Work package attributes

Subject patterns can include placeholders referencing the following work package attributes:

| Attribute Name | Data Type         | Example    |
| -- | -- | - |
| Accountable    | User name         | Jon Doe    |
| Assignee       | User name         | Jon Doe    |
| Author         | User name         | Jon Doe    |
| Category       | String            | Category A |
| Created on     | Date              | 2025-01-10 |
| Finish date    | Date              | 2025-01-15 |
| ID             | Integer           | 3000       |
| Priority       | String            | Normal     |
| Project        | Project ID        | 30         |
| Remaining work | Hours (float)     | 8.0        |
| Start date     | Date              | 2025-01-12 |
| Status         | String            | New        |
| Type           | Work package type | Task       |
| Work           | Hours (float)     | 10.0       |

**Custom fields**: Supported custom fields include Text, Integer, Float, List, Date, Boolean, User, Version.
**Unsupported attributes**: Long text and Link custom fields are excluded to keep subjects concise.

> [!NOTE] 
> Ensure selected attributes are activated and available in your project and work package types to avoid showing “N/A” in subjects.


### 3.2 Supported project attribute

| Attribute Name         | Data Type   | Example  |
| - | -- | -- |
| Project: Active        | Boolean     | true     |
| Project: Name          | String      | HR       |
| Project: Status        | Status code | on_track |
| Project: Subproject of | ID          | 123      |
| Project: Public        | Boolean     | false    |

**Custom project attributes:** Supported attributes include Integer, Float, List, Date, Boolean, User, Version.
**Unsupported project attributes**: Long text and Link custom fields are excluded to keep subjects concise.




## 4. updating automatic subjects

Automatic subjects update whenever an attribute referenced in the **current work package** changes and the work package is saved.

> [!IMPORTANT] 
> Attributes referencing parent work packages or project attributes won't trigger immediate updates. Changes in parent or project attributes appear only when the child work package itself is updated and saved again.



## 5. Why "N/A" appears in subjects

"N/A" indicates an unavailable attribute referenced in the subject pattern. Typical causes:

- The attribute isn't activated in the current project.
- The attribute was removed from form configuration after creating the pattern.
- A parent attribute is referenced, but the parent doesn't contain the attribute.



## 5. Why [Attribute Name] appears in subjects

[Attribute Name] indicates an empty attribute referenced in the subject pattern.

- The attribute hasn't been filled by the user.
- A parent attribute is referenced, but no parent is set.
- A project attribute is referenced, but hasn't been filled.


## 6. Tips for effective patterns

Good subject patterns should be:

- **Concise**: Keep subjects short and readable.
- **Relevant**: Include only essential attributes needed for quick identification.
- **Descriptive**: Use clear static text (e.g., `Invoice`, `Bug Report`) to define the work package type.

Check our [Example Subject Patterns](https://www.openproject.org/blog/automatically-generated-work-package-subjects/) for inspiration.


