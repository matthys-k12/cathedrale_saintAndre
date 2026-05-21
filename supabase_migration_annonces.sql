-- =============================================================================
-- Migration Supabase : Mise à jour des catégories d'annonces
-- Cathédrale Saint André
-- =============================================================================
-- ÉTAPE 1 : Voir les catégories existantes (pour info)
-- SELECT DISTINCT categorie FROM annonces;

-- ÉTAPE 2 : Mapper les anciens slugs vers les nouveaux
--   liturgie    → activites
--   solidarite  → associations
--   jeunesse    → activites
--   formation   → activites
--   autre       → activites
-- (mariage, prieres, ceb, rappel_a_dieu sont nouvelles — à créer directement)

UPDATE annonces SET categorie = 'activites'    WHERE categorie IN ('liturgie', 'jeunesse', 'formation', 'autre');
UPDATE annonces SET categorie = 'associations' WHERE categorie = 'solidarite';

-- ÉTAPE 3 : Vérifier le résultat
-- SELECT categorie, COUNT(*) FROM annonces GROUP BY categorie ORDER BY categorie;

-- =============================================================================
-- Les nouvelles catégories valides sont :
--   activites
--   mariage
--   prieres
--   ceb
--   associations
--   rappel_a_dieu
-- =============================================================================
-- Si vous avez une table de référence des catégories, mettez-la à jour :
-- DELETE FROM annonce_categories;
-- INSERT INTO annonce_categories (id, label) VALUES
--   ('activites',     'Activités'),
--   ('mariage',       'Mariage'),
--   ('prieres',       'Prières'),
--   ('ceb',           'CEB'),
--   ('associations',  'Associations'),
--   ('rappel_a_dieu', 'Rappel à Dieu');
