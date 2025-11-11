-- Script pour corriger le problème des index
-- À exécuter manuellement dans MySQL

SET FOREIGN_KEY_CHECKS=0;

-- Supprimer la table users corrompue
DROP TABLE IF EXISTS `users`;

-- Recréer la table users proprement
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `googleId` varchar(255) DEFAULT NULL COMMENT 'ID Google de l''utilisateur pour Google Sign-In',
  `isVisibleOnMap` tinyint(1) DEFAULT 1,
  `currentLat` float DEFAULT NULL,
  `currentLon` float DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `googleId` (`googleId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS=1;
