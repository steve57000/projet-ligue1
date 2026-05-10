-- =====================================
-- Nettoyage des anciennes tables
-- =====================================

DROP TABLE IF EXISTS salaire_source CASCADE;
DROP TABLE IF EXISTS progression CASCADE;
DROP TABLE IF EXISTS attendu CASCADE;
DROP TABLE IF EXISTS performance CASCADE;
DROP TABLE IF EXISTS temps_de_jeu CASCADE;
DROP TABLE IF EXISTS joueur CASCADE;
DROP TABLE IF EXISTS position CASCADE;
DROP TABLE IF EXISTS equipe CASCADE;

-- =====================================
-- Tables de référence
-- =====================================

CREATE TABLE IF NOT EXISTS equipe (
    id_equipe  INT PRIMARY KEY,
    nom_equipe VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS position (
    code_position    VARCHAR(10) PRIMARY KEY,
    libelle_position VARCHAR(50) NOT NULL
);

-- =====================================
-- Table joueur
-- =====================================

CREATE TABLE IF NOT EXISTS joueur (
    id_joueur       INT PRIMARY KEY,
    nom_joueur      VARCHAR(100) NOT NULL,
    nation          VARCHAR(50),
    annee_naissance INT,
    code_position   VARCHAR(10) NOT NULL,
    id_equipe       INT NOT NULL,

    CONSTRAINT fk_joueur_position
      FOREIGN KEY (code_position)
          REFERENCES position (code_position),

    CONSTRAINT fk_joueur_equipe
      FOREIGN KEY (id_equipe)
          REFERENCES equipe (id_equipe)
);

-- =====================================
-- Temps de jeu
-- Relation : joueur 1 -> N temps_de_jeu
-- =====================================

CREATE TABLE IF NOT EXISTS temps_de_jeu (
    id_temps_de_jeu   SERIAL PRIMARY KEY,
    id_joueur         INT NOT NULL,
    matchs_joues      INT NOT NULL CHECK (matchs_joues >= 0),
    matchs_titulaires INT NOT NULL CHECK (matchs_titulaires >= 0),
    minutes_jouees    INT NOT NULL CHECK (minutes_jouees >= 0),
    matchs_90         NUMERIC(6, 2) NOT NULL CHECK (matchs_90 >= 0),

    CONSTRAINT fk_temps_joueur
        FOREIGN KEY (id_joueur)
            REFERENCES joueur (id_joueur)
            ON DELETE CASCADE
);

-- =====================================
-- Performance
-- Relation : joueur 1 -> N performance
-- =====================================

CREATE TABLE IF NOT EXISTS performance (
    id_performance      SERIAL PRIMARY KEY,
    id_joueur           INT NOT NULL,
    buts                INT NOT NULL CHECK (buts >= 0),
    passes_decisives    INT NOT NULL CHECK (passes_decisives >= 0),
    buts_plus_passes    INT GENERATED ALWAYS AS (buts + passes_decisives) STORED,
    buts_hors_penalties INT NOT NULL CHECK (buts_hors_penalties >= 0),
    penalties_marques   INT NOT NULL CHECK (penalties_marques >= 0),
    penalties_tentes    INT NOT NULL CHECK (penalties_tentes >= 0),
    cartons_jaunes      INT NOT NULL CHECK (cartons_jaunes >= 0),
    cartons_rouges      INT NOT NULL CHECK (cartons_rouges >= 0),

    CONSTRAINT fk_performance_joueur
       FOREIGN KEY (id_joueur)
           REFERENCES joueur (id_joueur)
           ON DELETE CASCADE
);

-- =====================================
-- Statistiques attendues
-- Relation : joueur 1 -> N attendu
-- =====================================

CREATE TABLE IF NOT EXISTS attendu (
    id_attendu INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    id_joueur  INT NOT NULL,
    xg         NUMERIC(6, 2) NOT NULL CHECK (xg >= 0),
    npxg       NUMERIC(6, 2) NOT NULL CHECK (npxg >= 0),
    xag        NUMERIC(6, 2) NOT NULL CHECK (xag >= 0),
    npxg_xag   NUMERIC(6, 2) GENERATED ALWAYS AS (npxg + xag) STORED,

    CONSTRAINT fk_attendu_joueur
       FOREIGN KEY (id_joueur)
           REFERENCES joueur (id_joueur)
           ON DELETE CASCADE
);

-- =====================================
-- Progression
-- Relation : joueur 1 -> N progression
-- =====================================

CREATE TABLE IF NOT EXISTS progression (
    id_progression       SERIAL PRIMARY KEY,
    id_joueur            INT NOT NULL,
    progression_conduite INT NOT NULL CHECK (progression_conduite >= 0),
    progression_passe    INT NOT NULL CHECK (progression_passe >= 0),
    progression_course   INT NOT NULL CHECK (progression_course >= 0),

    CONSTRAINT fk_progression_joueur
       FOREIGN KEY (id_joueur)
           REFERENCES joueur (id_joueur)
           ON DELETE CASCADE
);

-- =====================================
-- Salaire source
-- Relation : joueur 1 -> N salaire_source possible
-- =====================================

CREATE TABLE IF NOT EXISTS salaire_source (
    id_joueur_source INT PRIMARY KEY,
    nom_joueur       VARCHAR(100) NOT NULL,
    age              INT CHECK (age >= 0),
    salaire_annuel   NUMERIC(12, 2) CHECK (salaire_annuel >= 0),
    note_source      TEXT,
    id_joueur        INT NULL,

    CONSTRAINT fk_salaire_joueur
      FOREIGN KEY (id_joueur)
          REFERENCES joueur (id_joueur)
          ON DELETE SET NULL
);

-- =====================================
-- Vérification : liste des tables créées
-- =====================================

SELECT 'Tables créées avec succès' AS status;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;