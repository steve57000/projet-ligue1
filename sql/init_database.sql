CREATE TABLE IF NOT EXISTS equipe (
    id_equipe  INT PRIMARY KEY,
    nom_equipe VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS position (
    code_position    VARCHAR(10) PRIMARY KEY,
    libelle_position VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS joueur (
    id_joueur       INT PRIMARY KEY,
    nom_joueur      VARCHAR(100) NOT NULL,
    nation          VARCHAR(50),
    annee_naissance INT,
    code_position   VARCHAR(10)  NOT NULL,
    id_equipe       INT          NOT NULL,
    CONSTRAINT fk_joueur_position
      FOREIGN KEY (code_position) REFERENCES position (code_position),
    CONSTRAINT fk_joueur_equipe
      FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
);

CREATE TABLE IF NOT EXISTS temps_de_jeu (
    id_joueur         INT PRIMARY KEY,
    matchs_joues      INT           NOT NULL CHECK (matchs_joues >= 0),
    matchs_titulaires INT           NOT NULL CHECK (matchs_titulaires >= 0),
    minutes_jouees    INT           NOT NULL CHECK (minutes_jouees >= 0),
    matchs_90         NUMERIC(6, 2) NOT NULL CHECK (matchs_90 >= 0),
    CONSTRAINT fk_temps_joueur
        FOREIGN KEY (id_joueur) REFERENCES joueur (id_joueur)
            ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS performance (
    id_joueur           INT PRIMARY KEY,
    buts                INT NOT NULL CHECK (buts >= 0),
    passes_decisives    INT NOT NULL CHECK (passes_decisives >= 0),
    buts_plus_passes    INT NOT NULL CHECK (buts_plus_passes >= 0),
    buts_hors_penalties INT NOT NULL CHECK (buts_hors_penalties >= 0),
    penalties_marques   INT NOT NULL CHECK (penalties_marques >= 0),
    penalties_tentes    INT NOT NULL CHECK (penalties_tentes >= 0),
    cartons_jaunes      INT NOT NULL CHECK (cartons_jaunes >= 0),
    cartons_rouges      INT NOT NULL CHECK (cartons_rouges >= 0),
    CONSTRAINT fk_performance_joueur
       FOREIGN KEY (id_joueur) REFERENCES joueur (id_joueur)
           ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS attendu (
    id_joueur INT PRIMARY KEY,
    xg        NUMERIC(6, 2) NOT NULL CHECK (xg >= 0),
    npxg      NUMERIC(6, 2) NOT NULL CHECK (npxg >= 0),
    xag       NUMERIC(6, 2) NOT NULL CHECK (xag >= 0),
    npxg_xag  NUMERIC(6, 2) NOT NULL CHECK (npxg_xag >= 0),
    CONSTRAINT fk_attendu_joueur
       FOREIGN KEY (id_joueur) REFERENCES joueur (id_joueur)
           ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS progression (
    id_joueur            INT PRIMARY KEY,
    progression_conduite INT NOT NULL CHECK (progression_conduite >= 0),
    progression_passe    INT NOT NULL CHECK (progression_passe >= 0),
    progression_course   INT NOT NULL CHECK (progression_course >= 0),
    CONSTRAINT fk_progression_joueur
       FOREIGN KEY (id_joueur) REFERENCES joueur (id_joueur)
           ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salaire_source (
    id_source      SERIAL PRIMARY KEY,
    nom_joueur     VARCHAR(100) NOT NULL,
    age            INT CHECK (age >= 0),
    salaire_annuel NUMERIC(12, 2) CHECK (salaire_annuel >= 0),
    note_source    TEXT,
    id_joueur      INT UNIQUE,
    CONSTRAINT fk_salaire_joueur
      FOREIGN KEY (id_joueur) REFERENCES joueur (id_joueur)
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