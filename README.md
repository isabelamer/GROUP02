# FCED – Conference Support System

## Group 02

|                  Name                   | Student number |
|------------------------------------------|----------------|
| Benedita Barreto da Costa Gonçalves      | 202205903 |
| Isabela Moreira Merelles                 | 202602764 |
| Maria Leonor Soares Carvalho | 202307522 |
| Mariana Vale de Oliveira Coelho de Pinho | 202306234 |

## Selected modules

Module A – Paper Submission and Review  
Module F – Proceedings and Publication  
Integration A–F (accepted Paper ↔ Published Contribution) is implemented.

## DBMS

PostgreSQL (tested on PostgreSQL 18, using pgAdmin 4).  
Execution order: `schema.sql`, then `data.sql` (optional), then `queries.sql`.

## Modelling decisions and assumptions

### Core

1. **Edition identity.** A Conference Edition has a surrogate key `edition_id`. The constraint `UNIQUE (conference_id, year)` ensures that a Conference cannot have two editions in the same year.
2. **Participation in an edition** is represented by the table `edition_participant`. The rule that a Participant involved in an Activity must participate in the Conference Edition of that Activity is not enforced in the schema.
3. **Activity dates.** An Activity must fall within its edition. This rule is not enforced in the schema.
4. **Roles** in an Activity are limited to `speaker`, `chair` and `attendee`.

### Module A

5. **Status vs. decision.** The submission `status` (submitted, under review, withdrawn) and the final `decision` (accepted, rejected) are independent attributes of `paper`. `decision` and `decision_date` are both set or both null (CHECK). The condition `decision_date >= submission_date` is also checked.
6. **Authors and reviewers.** They must be Participants of the system, but not necessarily Participants of the edition (the requirements do not demand it).
7. **Author order** is stored in `authorship.position`, unique per Paper (deferrable, so authors can be reordered within a transaction).
8. **One Review per reviewer and Paper** is enforced by the composite primary key of `review`: `(paper, reviewer)`. This prevents the same Participant from submitting two Reviews for the same Paper.
9. **Extra rule (group decision):** a Participant cannot review a Paper they authored (enforced by trigger).
10. **Assumed value sets:** review score between 1 and 5; recommendation in `{accept, weak_accept, weak_reject, reject}`.
11. A Paper must have at least one author. This requirement is not enforced in the schema.

### Module F

12. **Editors.** The requirements state that one or more Participants may act as Editors of a Proceedings publication, so each Proceedings must have at least one editor. This minimum is not enforced in the schema. Editors only need to be Participants of the system.
13. **Published Contribution authors** keep their order in `contribution_author.position`. At least one author is required; this minimum is not enforced in the schema.
14. **Page ranges** must satisfy `last_page >= first_page`. Overlap between contributions of the same Proceedings is not checked. If the UML contains such a constraint, it is conceptual only.
15. `publication_identifier` (ISBN or equivalent) is unique. `doi` is optional and unique when present.

### Integration A–F

16. `published_contribution.paper_id` is optional and `UNIQUE`. An accepted Paper has at most one Published Contribution, and contributions without a Paper (invited material) are allowed.
17. **Same edition.** The requirement that the Paper and the Proceedings belong to the same Conference Edition is not enforced in the schema.
18. **Only accepted Papers.** The requirement that a Paper linked to a Published Contribution must have `decision = 'accepted'` is not enforced in the schema. Additionally, a trigger prevents changing the decision of a Paper that has already been published.

### Not enforced in the schema

- An Activity's start and end must fall within the start and end dates of its Conference Edition.
- A Participant involved in an Activity must participate in the Conference Edition of that Activity.
- A Paper linked to a Published Contribution must have `decision = 'accepted'` and belong to the same Conference Edition as the Proceedings of that contribution.
- Page ranges of Published Contributions in the same Proceedings must not overlap.
- A Review's `submissionDate` must not precede the `submissionDate` of its Paper.
- Every Paper must have at least one author.
- Every Published Contribution must have at least one author.
- Every Proceedings must have at least one Published Contribution.
- Every Proceedings must have at least one Editor.

## Queries (`queries.sql`)

- Example parameters: `edition_id = 1` and `proceedings_id = 1`.
- Core Q1 uses `LEFT JOIN`, so Activities without Participants are listed.
- Core Q2 counts distinct Activities per Participant and orders from largest to smallest.
- Module A Q2 uses `LEFT JOIN`, so Papers without Reviews appear (0 reviews, average NULL).
- Module F Q1 orders by `firstPage`, then by `authorOrder`.
- Module F Q2 aggregates the Editors into a single column (`string_agg`) and counts contributions with correlated subqueries to avoid duplicated rows.

## Example data (`data.sql`)

- Assumes an empty database (identity values start at 1).
- Runs in one transaction so that the example data is inserted consistently.
- Ends with commented-out negative tests, each of which must fail.