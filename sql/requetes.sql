SELECT COUNT(*) FROM joueur;
SELECT COUNT(*) FROM equipe;
SELECT COUNT(*) FROM performance;

-- Jointure simple
SELECT j.nom_joueur, e.nom_equipe
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
LIMIT 10;

-- Top buteurs
SELECT j.nom_joueur, e.nom_equipe, p.buts
FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN equipe e ON j.id_equipe = e.id_equipe
ORDER BY p.buts DESC
LIMIT 10;

-- Joueurs les plus efficaces (buts / matchs)
SELECT
    j.nom_joueur,
    p.buts,
    t.matchs_joues,
    ROUND(p.buts::decimal / t.matchs_joues, 2) AS ratio_buts
FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
WHERE t.matchs_joues > 5
ORDER BY ratio_buts DESC
LIMIT 10;

-- xG vs buts
SELECT
    j.nom_joueur,
    p.buts,
    a.xg,
    ROUND(p.buts - a.xg, 2) AS surperformance
FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN attendu a ON j.id_joueur = a.id_joueur
ORDER BY surperformance DESC
LIMIT 10;

-- Profil complet joueur
SELECT
    j.nom_joueur,
    e.nom_equipe,
    p.buts,
    p.passes_decisives,
    t.minutes_jouees,
    a.xg,
    a.xag
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
         JOIN attendu a ON j.id_joueur = a.id_joueur
LIMIT 10;

-- Détection talent
SELECT
    j.nom_joueur,
    e.nom_equipe,
    p.buts,
    a.xg,
    (p.buts - a.xg) AS performance_vs_attendu
FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN attendu a ON j.id_joueur = a.id_joueur
         JOIN equipe e ON j.id_equipe = e.id_equipe
WHERE p.buts > 5
ORDER BY performance_vs_attendu DESC
LIMIT 10;
