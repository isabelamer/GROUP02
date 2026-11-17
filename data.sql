-- Example data for Core + Module A + Module F
-- Run after schema.sql, on a fresh database.

BEGIN;

INSERT INTO conference (name, acronym, description) VALUES
('Conference on Data Science and Engineering', 'CDSE',
 'Annual conference on data science and data engineering.');

INSERT INTO conference_edition (conference_id, year, start_date, end_date, location) VALUES
(1, 2026, '2026-09-14', '2026-09-16', 'Porto, Portugal'),
(1, 2025, '2025-09-08', '2025-09-10', 'Lisbon, Portugal');

INSERT INTO participant (name, email, affiliation) VALUES
('Ana Silva',      'ana.silva@up.pt',          'University of Porto'),
('Bruno Costa',    'bruno.costa@fe.up.pt',     'FEUP'),
('Carla Mendes',   'carla.mendes@ist.pt',      'IST Lisboa'),
('David Rocha',    'david.rocha@uminho.pt',    'University of Minho'),
('Eva Martins',    'eva.martins@uc.pt',        'University of Coimbra'),
('Filipe Nunes',   'filipe.nunes@inesctec.pt', 'INESC TEC'),
('Gabriela Lopes', 'gabriela.lopes@ua.pt',     'University of Aveiro'),
('Hugo Pereira',   'hugo.pereira@fct.pt',      'FCT'),
('Ines Ferreira',  'ines.ferreira@up.pt',      'University of Porto'),
('Joao Almeida',   'joao.almeida@isep.pt',     'ISEP');

INSERT INTO edition_participant (edition_id, participant_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9),
(2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 10);

INSERT INTO activity (edition_id, title, description, start_time, end_time) VALUES
(1, 'Opening Keynote: The Future of Data Engineering', 'Opening talk of CDSE 2026.',
    '2026-09-14 09:00', '2026-09-14 10:00'),
(1, 'Session 1: Data Management', 'Papers on data management.',
    '2026-09-14 10:30', '2026-09-14 12:00'),
(1, 'Panel: Data Science Education', 'Panel on teaching data science.',
    '2026-09-14 14:00', '2026-09-14 15:30'),
(1, 'Session 2: Machine Learning Systems', 'Papers on ML systems.',
    '2026-09-15 09:30', '2026-09-15 11:00'),
(1, 'Workshop on Reproducible Pipelines', 'Hands-on workshop.',
    '2026-09-15 14:00', '2026-09-15 17:00'),
(1, 'Closing Session', 'No participants registered yet.',
    '2026-09-16 16:00', '2026-09-16 17:00'),
(2, 'Opening Keynote 2025', 'Opening talk of CDSE 2025.',
    '2025-09-08 09:00', '2025-09-08 10:00'),
(2, 'Session 1: Databases', 'Papers on databases.',
    '2025-09-09 10:00', '2025-09-09 11:30');

INSERT INTO involvement (activity_id, participant_id, role) VALUES
(1, 1, 'speaker'), (1, 2, 'chair'),   (1, 3, 'attendee'),
(1, 4, 'attendee'), (1, 5, 'attendee'),
(2, 2, 'chair'),   (2, 3, 'speaker'), (2, 4, 'speaker'),
(2, 6, 'attendee'),
(3, 1, 'chair'),   (3, 5, 'speaker'), (3, 6, 'speaker'),
(3, 7, 'speaker'), (3, 8, 'attendee'),
(4, 6, 'chair'),   (4, 4, 'speaker'), (4, 9, 'speaker'),
(4, 1, 'attendee'),
(5, 7, 'speaker'), (5, 9, 'attendee'),
(7, 1, 'speaker'), (7, 2, 'attendee'),
(8, 3, 'chair'),   (8, 4, 'speaker'), (8, 10, 'attendee');

INSERT INTO paper (edition_id, title, abstract, submission_date, status, decision, decision_date) VALUES
(1, 'Scalable Query Optimisation for Graph Databases',
    'We propose a cost model for large graph queries.',
    '2026-03-01', 'under_review', 'accepted', '2026-05-10'),
(1, 'Reproducible Machine Learning Pipelines',
    'A framework for reproducible ML experiments.',
    '2026-03-03', 'under_review', 'accepted', '2026-05-10'),
(1, 'A Survey of Data Quality Metrics',
    'A survey of metrics used to assess data quality.',
    '2026-03-05', 'under_review', 'rejected', '2026-05-12'),
(1, 'Privacy-Preserving Analytics at Scale',
    'Differential privacy for large analytics workloads.',
    '2026-03-10', 'submitted', NULL, NULL),
(1, 'Early Ideas on Data Lakes',
    'Position paper on data lake governance.',
    '2026-03-12', 'withdrawn', NULL, NULL),
(2, 'Indexing Time Series Efficiently',
    'A new index structure for time series.',
    '2025-03-02', 'under_review', 'accepted', '2025-05-05');

INSERT INTO authorship (paper_id, participant_id, position) VALUES
(1, 1, 1), (1, 2, 2), (1, 3, 3),
(2, 4, 1), (2, 5, 2),
(3, 6, 1), (3, 7, 2), (3, 8, 3),
(4, 9, 1),
(5, 3, 1),
(6, 2, 1), (6, 10, 2);

INSERT INTO review (paper_id, reviewer_id, score, assessment, recommendation, submission_date) VALUES
(1, 4, 5, 'Solid contribution, clear evaluation.',    'accept',      '2026-04-15'),
(1, 6, 4, 'Good idea, evaluation could be broader.',  'weak_accept', '2026-04-18'),
(1, 8, 5, 'Excellent paper.',                         'accept',      '2026-04-20'),
(2, 1, 4, 'Useful and well written.',                 'accept',      '2026-04-16'),
(2, 6, 3, 'Needs more comparison with related work.', 'weak_accept', '2026-04-19'),
(3, 2, 2, 'Limited novelty.',                         'reject',      '2026-04-17'),
(3, 4, 2, 'Incomplete coverage of the literature.',   'reject',      '2026-04-21'),
(6, 1, 5, 'Strong results on real datasets.',         'accept',      '2025-04-10'),
(6, 3, 4, 'Interesting, minor clarity issues.',       'weak_accept', '2025-04-12');

INSERT INTO proceedings (edition_id, title, publication_date, publication_identifier) VALUES
(1, 'Proceedings of CDSE 2026', '2026-09-10', '978-989-0000-26-1'),
(2, 'Proceedings of CDSE 2025', '2025-09-05', '978-989-0000-25-1');

INSERT INTO proceedings_editor (proceedings_id, participant_id) VALUES
(1, 1), (1, 2),
(2, 1), (2, 3);

INSERT INTO published_contribution
    (proceedings_id, title, first_page, last_page, doi, paper_id) VALUES
(1, 'Invited Keynote: The Future of Data Engineering',     25, 30, NULL,                   NULL),
(1, 'Reproducible Machine Learning Pipelines',             13, 24, '10.1234/cdse.2026.002', 2),
(1, 'Scalable Query Optimisation for Graph Databases',      1, 12, '10.1234/cdse.2026.001', 1),
(2, 'Indexing Time Series Efficiently',                     1, 10, '10.1234/cdse.2025.001', 6),
(2, 'Invited Talk: Twenty Years of Relational Databases',  11, 15, NULL,                   NULL);

INSERT INTO contribution_author (contribution_id, participant_id, position) VALUES
(1, 1, 1),
(2, 4, 1), (2, 5, 2),
(3, 1, 1), (3, 2, 2), (3, 3, 3),
(4, 2, 1), (4, 10, 2),
(5, 4, 1), (5, 3, 2);

COMMIT;