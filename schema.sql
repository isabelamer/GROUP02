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
        FOREIGN KEY (conference_id) REFERENCES conference(conference_id) ON DELETE RESTRICT,
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
        FOREIGN KEY (edition_id) REFERENCES conference_edition(edition_id) ON DELETE RESTRICT,
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

COMMIT;