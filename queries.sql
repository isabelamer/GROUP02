-- Example parameters: edition_id = 1, proceedings_id = 1

-- Core Q1
SELECT  a.activity_id,
        a.title,
        a.start_time,
        a.end_time,
        p.name AS participant,
        i.role
FROM activity a
LEFT JOIN involvement i ON i.activity_id = a.activity_id
LEFT JOIN participant p ON p.participant_id = i.participant_id
WHERE a.edition_id = 1
ORDER BY a.start_time, a.title, i.role, p.name;

-- Core Q2
SELECT  p.participant_id,
        p.name,
        COUNT(DISTINCT i.activity_id) AS num_activities
FROM involvement i
JOIN activity a    ON a.activity_id = i.activity_id
JOIN participant p ON p.participant_id = i.participant_id
WHERE a.edition_id = 1
GROUP BY p.participant_id, p.name
ORDER BY num_activities DESC, p.name;

-- Module A Q1
SELECT  pa.paper_id,
        pa.title,
        au.position,
        p.name AS author
FROM paper pa
LEFT JOIN authorship au  ON au.paper_id = pa.paper_id
LEFT JOIN participant p  ON p.participant_id = au.participant_id
WHERE pa.edition_id = 1
ORDER BY pa.paper_id, au.position NULLS LAST;

-- Module A Q2
SELECT  pa.paper_id,
        pa.title,
        COUNT(r.reviewer_id)   AS num_reviews,
        ROUND(AVG(r.score), 2) AS avg_score
FROM paper pa
LEFT JOIN review r ON r.paper_id = pa.paper_id
WHERE pa.edition_id = 1
GROUP BY pa.paper_id, pa.title
ORDER BY pa.paper_id;

-- Module F Q1
SELECT  pc.contribution_id,
        pc.first_page,
        pc.last_page,
        pc.title,
        pc.doi,
        ca.position,
        p.name AS author
FROM published_contribution pc
LEFT JOIN contribution_author ca ON ca.contribution_id = pc.contribution_id
LEFT JOIN participant p          ON p.participant_id = ca.participant_id
WHERE pc.proceedings_id = 1
ORDER BY pc.first_page, pc.contribution_id, ca.position NULLS LAST;

-- Module F Q2
SELECT  pr.proceedings_id,
        pr.title,
        pr.publication_identifier,
        (SELECT string_agg(p.name, ', ' ORDER BY p.name)
           FROM proceedings_editor pe
           JOIN participant p ON p.participant_id = pe.participant_id
          WHERE pe.proceedings_id = pr.proceedings_id) AS editors,
        (SELECT COUNT(*)
           FROM published_contribution pc
          WHERE pc.proceedings_id = pr.proceedings_id) AS num_contributions
FROM proceedings pr
WHERE pr.edition_id = 1
ORDER BY pr.publication_date, pr.title;