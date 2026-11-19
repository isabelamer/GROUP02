-- Conference Support System
-- Core + Module A + Module F
-- PostgreSQL 14+

SET client_min_messages TO WARNING;

BEGIN;

DROP TABLE IF EXISTS proceedings_editor      CASCADE;
DROP TABLE IF EXISTS contribution_author     CASCADE;
DROP TABLE IF EXISTS published_contribution  CASCADE;
DROP TABLE IF EXISTS proceedings             CASCADE;
DROP TABLE IF EXISTS review                  CASCADE;
DROP TABLE IF EXISTS authorship              CASCADE;
DROP TABLE IF EXISTS paper                   CASCADE;
DROP TABLE IF EXISTS involvement             CASCADE;
DROP TABLE IF EXISTS activity                CASCADE;
DROP TABLE IF EXISTS edition_participant     CASCADE;
DROP TABLE IF EXISTS participant             CASCADE;
DROP TABLE IF EXISTS conference_edition      CASCADE;
DROP TABLE IF EXISTS conference              CASCADE;

DROP FUNCTION IF EXISTS check_activity_edition()        CASCADE;
DROP FUNCTION IF EXISTS check_edition_activities()      CASCADE;
DROP FUNCTION IF EXISTS check_involvement_edition()     CASCADE;
DROP FUNCTION IF EXISTS protect_edition_participation() CASCADE;
DROP FUNCTION IF EXISTS check_contribution_paper()      CASCADE;
DROP FUNCTION IF EXISTS protect_published_paper()       CASCADE;
DROP FUNCTION IF EXISTS protect_proceedings_edition()   CASCADE;
DROP FUNCTION IF EXISTS check_review_not_author()       CASCADE;
DROP FUNCTION IF EXISTS check_author_not_reviewer()     CASCADE;

-- CORE

CREATE TABLE conference (
    conference_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          TEXT NOT NULL,
    acronym       TEXT NOT NULL,
    description   TEXT NOT NULL
);

CREATE TABLE conference_edition (
    edition_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conference_id INTEGER NOT NULL,
    year          INTEGER NOT NULL,
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    location      TEXT NOT NULL,
    CONSTRAINT fk_edition_conference
        FOREIGN KEY (conference_id) REFERENCES conference(conference_id) ON DELETE CASCADE,
    CONSTRAINT uq_edition_conference_year UNIQUE (conference_id, year),
    CONSTRAINT chk_edition_date_range CHECK (end_date >= start_date)
);

CREATE TABLE participant (
    participant_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           TEXT NOT NULL,
    email          TEXT NOT NULL,
    affiliation    TEXT NOT NULL,
    CONSTRAINT uq_participant_email UNIQUE (email)
);

CREATE TABLE edition_participant (
    edition_id     INTEGER NOT NULL,
    participant_id INTEGER NOT NULL,
    CONSTRAINT pk_edition_participant PRIMARY KEY (edition_id, participant_id),
    CONSTRAINT fk_edition_participant_edition
        FOREIGN KEY (edition_id) REFERENCES conference_edition(edition_id) ON DELETE CASCADE,
    CONSTRAINT fk_edition_participant_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE RESTRICT
);

CREATE TABLE activity (
    activity_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edition_id  INTEGER NOT NULL,
    title       TEXT NOT NULL,
    description TEXT NOT NULL,
    start_time  TIMESTAMP NOT NULL,
    end_time    TIMESTAMP NOT NULL,
    CONSTRAINT fk_activity_edition
        FOREIGN KEY (edition_id) REFERENCES conference_edition(edition_id) ON DELETE CASCADE,
    CONSTRAINT chk_activity_time_range CHECK (end_time > start_time)
);

CREATE TABLE involvement (
    activity_id    INTEGER NOT NULL,
    participant_id INTEGER NOT NULL,
    role           TEXT NOT NULL,
    CONSTRAINT pk_involvement PRIMARY KEY (activity_id, participant_id),
    CONSTRAINT fk_involvement_activity
        FOREIGN KEY (activity_id) REFERENCES activity(activity_id) ON DELETE CASCADE,
    CONSTRAINT fk_involvement_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE RESTRICT,
    CONSTRAINT chk_involvement_role
        CHECK (role IN ('speaker', 'chair', 'attendee'))
);

-- MODULE A

CREATE TABLE paper (
    paper_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edition_id      INTEGER NOT NULL,
    title           TEXT NOT NULL,
    abstract        TEXT NOT NULL,
    submission_date DATE NOT NULL,
    status          TEXT NOT NULL,
    decision        TEXT,
    decision_date   DATE,
    CONSTRAINT fk_paper_edition
        FOREIGN KEY (edition_id) REFERENCES conference_edition(edition_id) ON DELETE RESTRICT,
    CONSTRAINT chk_paper_status
        CHECK (status IN ('submitted', 'under_review', 'withdrawn')),
    CONSTRAINT chk_paper_decision
        CHECK (decision IN ('accepted', 'rejected')),
    CONSTRAINT chk_paper_decision_pair
        CHECK ((decision IS NULL) = (decision_date IS NULL)),
    CONSTRAINT chk_paper_decision_date
        CHECK (decision_date IS NULL OR decision_date >= submission_date)
);

CREATE TABLE authorship (
    paper_id       INTEGER NOT NULL,
    participant_id INTEGER NOT NULL,
    position       INTEGER NOT NULL,
    CONSTRAINT pk_authorship PRIMARY KEY (paper_id, participant_id),
    CONSTRAINT uq_authorship_position UNIQUE (paper_id, position) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_authorship_paper
        FOREIGN KEY (paper_id) REFERENCES paper(paper_id) ON DELETE CASCADE,
    CONSTRAINT fk_authorship_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE RESTRICT,
    CONSTRAINT chk_authorship_position CHECK (position >= 1)
);

CREATE TABLE review (
    paper_id        INTEGER NOT NULL,
    reviewer_id     INTEGER NOT NULL,
    score           INTEGER NOT NULL,
    assessment      TEXT NOT NULL,
    recommendation  TEXT NOT NULL,
    submission_date DATE NOT NULL,
    CONSTRAINT pk_review PRIMARY KEY (paper_id, reviewer_id),
    CONSTRAINT fk_review_paper
        FOREIGN KEY (paper_id) REFERENCES paper(paper_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_reviewer
        FOREIGN KEY (reviewer_id) REFERENCES participant(participant_id) ON DELETE RESTRICT,
    CONSTRAINT chk_review_score CHECK (score BETWEEN 1 AND 5),
    CONSTRAINT chk_review_recommendation
        CHECK (recommendation IN ('accept', 'weak_accept', 'weak_reject', 'reject'))
);

-- MODULE F

CREATE TABLE proceedings (
    proceedings_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edition_id             INTEGER NOT NULL,
    title                  TEXT NOT NULL,
    publication_date       DATE NOT NULL,
    publication_identifier TEXT NOT NULL,
    CONSTRAINT fk_proceedings_edition
        FOREIGN KEY (edition_id) REFERENCES conference_edition(edition_id) ON DELETE RESTRICT,
    CONSTRAINT uq_proceedings_identifier UNIQUE (publication_identifier)
);

CREATE TABLE published_contribution (
    contribution_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    proceedings_id  INTEGER NOT NULL,
    title           TEXT NOT NULL,
    first_page      INTEGER NOT NULL,
    last_page       INTEGER NOT NULL,
    doi             TEXT,
    paper_id        INTEGER,
    CONSTRAINT fk_contribution_proceedings
        FOREIGN KEY (proceedings_id) REFERENCES proceedings(proceedings_id) ON DELETE CASCADE,
    CONSTRAINT fk_contribution_paper
        FOREIGN KEY (paper_id) REFERENCES paper(paper_id) ON DELETE RESTRICT,
    CONSTRAINT uq_contribution_doi UNIQUE (doi),
    CONSTRAINT uq_contribution_paper UNIQUE (paper_id),
    CONSTRAINT chk_contribution_first_page CHECK (first_page >= 1),
    CONSTRAINT chk_contribution_page_range CHECK (last_page >= first_page)
);

CREATE TABLE contribution_author (
    contribution_id INTEGER NOT NULL,
    participant_id  INTEGER NOT NULL,
    position        INTEGER NOT NULL,
    CONSTRAINT pk_contribution_author PRIMARY KEY (contribution_id, participant_id),
    CONSTRAINT uq_contribution_author_position
        UNIQUE (contribution_id, position) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_contribution_author_contribution
        FOREIGN KEY (contribution_id)
        REFERENCES published_contribution(contribution_id) ON DELETE CASCADE,
    CONSTRAINT fk_contribution_author_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE RESTRICT,
    CONSTRAINT chk_contribution_author_position CHECK (position >= 1)
);

CREATE TABLE proceedings_editor (
    proceedings_id INTEGER NOT NULL,
    participant_id INTEGER NOT NULL,
    CONSTRAINT pk_proceedings_editor PRIMARY KEY (proceedings_id, participant_id),
    CONSTRAINT fk_editor_proceedings
        FOREIGN KEY (proceedings_id) REFERENCES proceedings(proceedings_id) ON DELETE CASCADE,
    CONSTRAINT fk_editor_participant
        FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE RESTRICT
);

-- INDEXES

CREATE INDEX idx_activity_edition         ON activity(edition_id);
CREATE INDEX idx_paper_edition            ON paper(edition_id);
CREATE INDEX idx_review_reviewer          ON review(reviewer_id);
CREATE INDEX idx_authorship_part          ON authorship(participant_id);
CREATE INDEX idx_edition_participant_part ON edition_participant(participant_id);
CREATE INDEX idx_involvement_participant  ON involvement(participant_id);
CREATE INDEX idx_proceedings_edition      ON proceedings(edition_id);
CREATE INDEX idx_contribution_proc        ON published_contribution(proceedings_id);
CREATE INDEX idx_contribution_author_par  ON contribution_author(participant_id);
CREATE INDEX idx_editor_participant       ON proceedings_editor(participant_id);

-- CORE: Activities must stay within their edition, and existing involvements
-- must remain valid if an Activity is moved to another edition.
CREATE FUNCTION check_activity_edition() RETURNS TRIGGER AS $$
DECLARE
    ed conference_edition%ROWTYPE;
BEGIN
    SELECT * INTO ed FROM conference_edition WHERE edition_id = NEW.edition_id;

    IF NEW.start_time < ed.start_date::timestamp
       OR NEW.end_time >= (ed.end_date + 1)::timestamp THEN
        RAISE EXCEPTION 'Activity % must occur within edition % dates',
            NEW.activity_id, NEW.edition_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM involvement i
        WHERE i.activity_id = NEW.activity_id
          AND NOT EXISTS (
              SELECT 1 FROM edition_participant ep
              WHERE ep.edition_id = NEW.edition_id
                AND ep.participant_id = i.participant_id
          )
    ) THEN
        RAISE EXCEPTION 'Activity % has participants outside edition %',
            NEW.activity_id, NEW.edition_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_activity_edition
BEFORE INSERT OR UPDATE OF edition_id, start_time, end_time ON activity
FOR EACH ROW EXECUTE FUNCTION check_activity_edition();

-- An edition's dates cannot be changed so as to exclude existing Activities.
CREATE FUNCTION check_edition_activities() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM activity a
        WHERE a.edition_id = NEW.edition_id
          AND (a.start_time < NEW.start_date::timestamp
               OR a.end_time >= (NEW.end_date + 1)::timestamp)
    ) THEN
        RAISE EXCEPTION 'Edition % dates would exclude existing Activities', NEW.edition_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_edition_activities
BEFORE UPDATE OF start_date, end_date ON conference_edition
FOR EACH ROW EXECUTE FUNCTION check_edition_activities();

-- An Activity involvement is valid only for a Participant of that edition.
CREATE FUNCTION check_involvement_edition() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM activity a
        JOIN edition_participant ep ON ep.edition_id = a.edition_id
        WHERE a.activity_id = NEW.activity_id
          AND ep.participant_id = NEW.participant_id
    ) THEN
        RAISE EXCEPTION 'Participant % does not participate in the edition of Activity %',
            NEW.participant_id, NEW.activity_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_involvement_edition
BEFORE INSERT OR UPDATE OF activity_id, participant_id ON involvement
FOR EACH ROW EXECUTE FUNCTION check_involvement_edition();

-- Removing or changing participation must not invalidate existing involvements.
CREATE FUNCTION protect_edition_participation() RETURNS TRIGGER AS $$
BEGIN
    -- The edition itself is being deleted (cascade): nothing to protect.
    IF TG_OP = 'DELETE' AND NOT EXISTS (
        SELECT 1 FROM conference_edition WHERE edition_id = OLD.edition_id
    ) THEN
        RETURN OLD;
    END IF;
    IF EXISTS (
        SELECT 1 FROM involvement i
        JOIN activity a ON a.activity_id = i.activity_id
        WHERE a.edition_id = OLD.edition_id
          AND i.participant_id = OLD.participant_id
    ) THEN
        RAISE EXCEPTION 'Participant % is involved in Activities of edition %',
            OLD.participant_id, OLD.edition_id;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        RETURN NEW;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protect_edition_participation
BEFORE DELETE ON edition_participant
FOR EACH ROW
EXECUTE FUNCTION protect_edition_participation();

CREATE TRIGGER trg_protect_edition_participation_update
BEFORE UPDATE OF edition_id, participant_id ON edition_participant
FOR EACH ROW
WHEN (OLD.edition_id IS DISTINCT FROM NEW.edition_id
      OR OLD.participant_id IS DISTINCT FROM NEW.participant_id)
EXECUTE FUNCTION protect_edition_participation();

-- MODULE A + F: A linked Paper must be accepted and belong to the same
-- edition as the Proceedings containing its Published Contribution.
CREATE FUNCTION check_contribution_paper() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.paper_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM paper pa
        JOIN proceedings pr ON pr.proceedings_id = NEW.proceedings_id
        WHERE pa.paper_id = NEW.paper_id
          AND pa.decision = 'accepted'
          AND pa.edition_id = pr.edition_id
    ) THEN
        RAISE EXCEPTION 'Contribution Paper % must be accepted and from the Proceedings edition',
            NEW.paper_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contribution_paper
BEFORE INSERT OR UPDATE OF paper_id, proceedings_id ON published_contribution
FOR EACH ROW EXECUTE FUNCTION check_contribution_paper();

-- Subsequent updates must not invalidate an already published Paper.
CREATE FUNCTION protect_published_paper() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM published_contribution pc
        JOIN proceedings pr ON pr.proceedings_id = pc.proceedings_id
        WHERE pc.paper_id = NEW.paper_id
          AND (NEW.decision IS DISTINCT FROM 'accepted'
               OR NEW.edition_id <> pr.edition_id)
    ) THEN
        RAISE EXCEPTION 'Paper % is published and must remain accepted in the same edition',
            NEW.paper_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protect_published_paper
BEFORE UPDATE OF decision, edition_id ON paper
FOR EACH ROW EXECUTE FUNCTION protect_published_paper();

CREATE FUNCTION protect_proceedings_edition() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM published_contribution pc
        JOIN paper pa ON pa.paper_id = pc.paper_id
        WHERE pc.proceedings_id = NEW.proceedings_id
          AND pa.edition_id <> NEW.edition_id
    ) THEN
        RAISE EXCEPTION 'Proceedings % must remain in the edition of its linked Papers',
            NEW.proceedings_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protect_proceedings_edition
BEFORE UPDATE OF edition_id ON proceedings
FOR EACH ROW EXECUTE FUNCTION protect_proceedings_edition();

-- MODULE A: a Participant cannot review a Paper they authored (group decision).
CREATE FUNCTION check_review_not_author() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM authorship au
        WHERE au.paper_id = NEW.paper_id
          AND au.participant_id = NEW.reviewer_id
    ) THEN
        RAISE EXCEPTION 'Participant % cannot review Paper % because they are an author',
            NEW.reviewer_id, NEW.paper_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_review_not_author
BEFORE INSERT OR UPDATE OF paper_id, reviewer_id ON review
FOR EACH ROW EXECUTE FUNCTION check_review_not_author();

-- The same rule seen from the authorship side.
CREATE FUNCTION check_author_not_reviewer() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM review r
        WHERE r.paper_id = NEW.paper_id
          AND r.reviewer_id = NEW.participant_id
    ) THEN
        RAISE EXCEPTION 'Participant % already reviewed Paper % and cannot be an author',
            NEW.participant_id, NEW.paper_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_author_not_reviewer
BEFORE INSERT OR UPDATE OF paper_id, participant_id ON authorship
FOR EACH ROW EXECUTE FUNCTION check_author_not_reviewer();

COMMIT;