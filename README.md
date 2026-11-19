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

The UML diagram uses conceptual names (e.g. `ConferenceEdition`, `authorOrder`). The relational model uses the same relation and attribute names as `schema.sql` (e.g. `conference_edition`, `position`).

### Core

1. **Edition identity.** A Conference Edition has a surrogate key `edition_id`. In the UML, `year` is the qualifier of the composition between Conference and ConferenceEdition, so a Conference has at most one Edition per year. In the relational model this becomes `{UK: conference_id, year}`, implemented as `UNIQUE (conference_id, year)`.
2. **Participation in an edition** is represented by the table `edition_participant`. Triggers enforce that a Participant involved in an Activity also participates in its Conference Edition, including when an Activity changes edition or edition participation is removed.
3. **Activity dates.** An Activity must fall within its edition (including the full end date). Triggers validate Activity inserts/updates and prevent shortening an edition's dates so that existing Activities fall outside them.
4. **Roles** in an Activity are limited to `speaker`, `chair` and `attendee`.
5. **Deletion policy.** The compositions Conference–ConferenceEdition and ConferenceEdition–Activity are implemented with `ON DELETE CASCADE`. Deleting a Conference removes its Editions, and deleting an Edition removes its Activities, involvements and participations. Papers and Proceedings are plain associations (`ON DELETE RESTRICT`), so an Edition that still has Papers or Proceedings cannot be deleted.

### Module A

6. **Status vs. decision.** The submission `status` (submitted, under review, withdrawn) and the final `decision` (accepted, rejected) are independent attributes of `paper`. `decision` and `decision_date` are both set or both null (CHECK). The condition `decision_date >= submission_date` is also checked. The `status` keeps the last stage of the submission process, so a Paper that has received a decision usually remains `under_review` (as in the example data).
7. **Authors and reviewers.** They must be Participants of the system, but not necessarily Participants of the edition (the requirements do not demand it).
8. **Author order** is stored in `authorship.position`, unique per Paper (deferrable, so authors can be reordered within a transaction).
9. **One Review per reviewer and Paper** is enforced by the composite primary key of `review`: `(paper_id, reviewer_id)`. This prevents the same Participant from submitting two Reviews for the same Paper.
10. **Extra rule (group decision):** a Participant cannot review a Paper they authored (enforced by trigger).
11. **Assumed value sets:** review score between 1 and 5; recommendation in `{accept, weak_accept, weak_reject, reject}`.
12. A Paper must have at least one author. This requirement is not enforced in the schema.

### Module F

13. **Editors.** The requirements state that one or more Participants may act as Editors of a Proceedings publication, so each Proceedings must have at least one editor. This minimum is not enforced in the schema. Editors only need to be Participants of the system.
14. **Published Contribution authors** keep their order in `contribution_author.position`. At least one author is required; this minimum is not enforced in the schema.
15. **Page ranges** must satisfy `last_page >= first_page`. The UML states, in the note attached to PublishedContribution, that contributions of the same Proceedings must not overlap. This rule is not enforced in the schema.
16. `publication_identifier` (ISBN or equivalent) is unique. `doi` is optional and unique when present.

### Integration A–F

17. `published_contribution.paper_id` is optional and `UNIQUE`. An accepted Paper has at most one Published Contribution, and contributions without a Paper (invited material) are allowed.
18. **Same edition.** Triggers ensure that a linked Paper and the Proceedings belong to the same Conference Edition, including after updates to either edition.
19. **Only accepted Papers.** A trigger ensures that a Paper linked to a Published Contribution has `decision = 'accepted'`. Another trigger prevents subsequently changing that decision to a non-accepted value while the Paper remains linked.

### Not enforced in the schema

- Page ranges of Published Contributions in the same Proceedings must not overlap.
- A Review's `submission_date` must not precede the `submission_date` of its Paper.
- Every Paper must have at least one author.
- Every Published Contribution must have at least one author.
- Every Proceedings must have at least one Published Contribution.
- Every Proceedings must have at least one Editor.

## Queries (`queries.sql`)

- Example parameters: `edition_id = 1` and `proceedings_id = 1`.
- Core Q1 uses `LEFT JOIN`, so Activities without Participants are listed.
- Core Q2 counts distinct Activities per Participant and orders from largest to smallest.
- Module A Q1 interprets "submitted Papers" as all Papers submitted to the edition, whatever their current `status` (including withdrawn ones).
- Module A Q2 uses `LEFT JOIN`, so Papers without Reviews appear (0 reviews, average NULL).
- Module F Q1 orders by `first_page`, then by `position`.
- Module F Q2 aggregates the Editors into a single column (`string_agg`) and counts contributions with correlated subqueries to avoid duplicated rows.

## Example data (`data.sql`)

- Assumes an empty database (identity values start at 1).
- Runs in one transaction so that the example data is inserted consistently.
- Ends with commented-out negative tests, each of which must fail.