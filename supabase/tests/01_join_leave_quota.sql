-- À lancer dans le SQL editor après la migration, avec 3 users de test.
-- Remplace les UUID.

-- 1. A crée une annonce + 2 rôles (Policier max 1, Témoin max 1)
-- 2. B join Policier → ok, filled=1
-- 3. C join Policier → rejected role_full
-- 4. B join Témoin (déjà inscrit) → rejected already_signed_up
-- 5. C join Témoin → ok, status=full
-- 6. C leave → status=open
