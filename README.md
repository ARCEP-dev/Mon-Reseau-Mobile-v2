<div align="center">

# Mon réseau mobile

**Comparer la couverture et la qualité de service des opérateurs mobiles en France**

[![Licence du code](https://img.shields.io/badge/Code-GPLv3-blue.svg)](LICENSE)
[![Licence des données](https://img.shields.io/badge/Données-Licence%20Ouverte%201.0-blue.svg)](#-licences)
[![Service en ligne](https://img.shields.io/badge/Démo-monreseaumobile.arcep.fr-green.svg)](https://monreseaumobile.arcep.fr/)
[![Code public](https://img.shields.io/badge/code.gouv.fr-référencé-informational.svg)](https://code.gouv.fr/)

[Accéder au service](https://monreseaumobile.arcep.fr/) ·
[Signaler un bug](../../issues) ·

</div>

---

## Sommaire

- [À propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Captures et démonstration](#-captures-et-démonstration)
- [Sources de données](#-sources-de-données)
- [Architecture](#-architecture)
- [Pile technique](#-pile-technique)
- [Accessibilité et éco-conception](#-accessibilité-et-éco-conception)
- [Sécurité](#-sécurité)
- [Licences](#-licences)
- [Crédits et contact](#-crédits-et-contact)

---

## ℹ️ À propos

**« Mon réseau mobile »** est un outil cartographique édité par l'**Arcep** (Autorité de
régulation des communications électroniques, des postes et de la distribution de la presse).
Cette version correspond à la version disponible depuis **août 2025**. **« Mon réseau mobile »** 
permet de comparer les performances des  opérateurs mobiles en matière de couverture
(services : "Appels et SMS" et "Internet mobile") et de qualité de service dans son lieu de vie comme dans 
les transports, en France métropolitaine et en Outre-mer.

Le service s'adresse à tous les publics :

- les **particuliers** qui veulent comparer les réseaux avant de changer d'opérateur ;
- les **entreprises** qui envisagent une nouvelle implantation ;
- les **collectivités** qui suivent l'évolution des déploiements des réseaux mobiles sur leur territoire.

Ce dépôt publie le **code source** de l'application, conformément à la démarche d'ouverture
des codes sources des administrations (article L.300-4 du code des relations entre le public
et l'administration). Il vise la transparence, la réutilisation et la contribution de la communauté.

> ℹ️ Ce README décrit le projet à des fins de réutilisation. Le service de référence reste
> celui mis en ligne par l'Arcep : <https://monreseaumobile.arcep.fr/>.

---

## ✨ Fonctionnalités

L'application restitue, sur un fond cartographique interactif, plusieurs couches d'information
disponibles par opérateur et par technologie (2G / 3G / 4G) :

- **Cartes de couverture théoriques**
  - Couverture _Appels et SMS_
  - Couverture _Internet mobile_
- **Tests de qualité réseau** issus des campagnes de mesures terrain de l'Arcep et de partenaires
  - Tests de _navigation web_ 
  - Tests de _vidéo en ligne_ 
  - Tests de _débits descendants_ 
  - Tests de _téléversement de fichiers_ 
  - Tests de _voix_ 
  - Tests de _SMS_ 
- **Antennes et déploiements**
  - Emplacement des sites par opérateur.
  - Eplacement des sites en pannes.
- **Zones à couvrir** 
  - _Points d'intérêt_ (POI) et zones identifiées par les pouvoirs publics.
  - _Axes routiers prioritaires_ et _axes ferrés_.
- **Signalements** remontés via [« J'alerte l'Arcep »](https://www.arcep.fr/nos-sujets/jalerte-larcep-un-geste-citoyen-pour-ameliorer-les-reseaux-dechange.html).

> ⚠️ Les informations de couverture sont **simulées** et fournies à titre indicatif, sans valeur
> contractuelle. La couverture réelle peut varier selon le terminal, le bâti, la météo, la saison
> et la charge du réseau.

---

## 🖼️ Captures et démonstration

| Couverture mobile | Qualité de service | Antennes et déploiements | Zones à couvrir | Signalements |
| :---: | :---: | :---: | :---: | :---: |
| <img src="docs/coverage.png" alt="Carte de couverture mobile par opérateur" width="150"> | <img src="docs/qos.png" alt="Tests de qualité de service" width="150"> | <img src="docs/antenna.png" alt="Antennes et déploiements 4G/5G" width="150"> | <img src="docs/zac.png" alt="Zones à couvrir du dispositif de couverture ciblée" width="150"> | <img src="docs/signalements.png" alt="Signalements J'alerte l'Arcep" width="150"> |

Accéder à l'application : **<https://monreseaumobile.arcep.fr/>**

---

## 🗂️ Sources de données

Les données affichées proviennent de sources ouvertes et de transmissions réglementaires des
opérateurs. Les principales sources publiques réutilisables sont :

| Données | Producteur | Accès |
| --- | --- | --- |
| Cartes de couverture | Opérateurs / Arcep | [data.arcep.fr](https://data.arcep.fr/mobile/couvertures_theoriques/) |
| Mesures de qualité de service | Arcep | [data.arcep.fr](https://data.arcep.fr/mobile/mesures_qualite_arcep/) |
| Antennes et déploiements | Arcep / ANFR | [data.arcep.fr](https://data.arcep.fr/mobile/sites/) · [data.gouv](https://www.data.gouv.fr/datasets/donnees-sur-les-installations-radioelectriques-de-plus-de-5-watts-1) |
| Zones à couvrir | Arcep / Gouvernement | [data.arcep.fr](https://data.arcep.fr/mobile/dispositif_couverture_ciblee/) |
| Signalements consommateurs | Arcep (« J'alerte l'Arcep ») | Non disponibles |

<!-- À adapter : remplacez par les URLs exactes des jeux de données effectivement consommés -->

Les jeux de données sont, sauf mention contraire, publiés sous **Licence Ouverte / Open Licence 1.0**
(Etalab). Vérifiez la licence propre à chaque jeu de données avant toute réutilisation.

---

## 🏗️ Architecture


<img src="docs/stack.png" alt="Architecture">


## 🧰 Pile technique

---

- **Cartographie** : MapLibre GL JS, pg_tileserv, tuiles vectorielles.
- **Front-end** : Next.js, Tailwind.
- **Back-end** : Django.
- **Données géospatiales** : PostgreSQL + PostGIS.
- **Conteneurisation & déploiement** : Docker, Ansible.

---

## ♿ Accessibilité et éco-conception

Service public numérique, l'application vise la conformité au **RGAA** (Référentiel général
d'amélioration de l'accessibilité) et une démarche d'**éco-conception** (Référentiel général d'écoconception de services numériques). 
Toute contribution doit veiller à ne pas dégrader l'accessibilité (navigation clavier, contrastes, alternatives
textuelles, ARIA) ni la sobriété (poids des assets, requêtes réseau).

---

## 🔐 Sécurité

Merci de **ne pas** divulguer publiquement une faille de sécurité dans une issue.
Signalez-la de manière responsable via l'adresse de contact ci-dessous. 

Adresse de contact : consommateurs@arcep.fr

---

## 📜 Licences

- **Code source** : publié sous **GNU GPL-3.0**. Voir [`LICENSE`](LICENSE).
- **Données** : **Licence Ouverte / Open Licence 1.0** (Etalab), sauf mention contraire propre
  à chaque jeu de données.
- **Marques et logos** (« Mon réseau mobile », Arcep) : protégés, exclus de la licence du code
  et non réutilisables sans autorisation.

---

## 🙏 Crédits et contact

- **Éditeur** : Neogeo Technologies, BAL, 67 All. Jean Jaurès, 31000 Toulouse.
- **Données partenaires** : Collectivités territoriales, Speedchecker, Ookla (liste non-exhaustive)
- **Service en ligne** : <https://monreseaumobile.arcep.fr/>
- **Page d'information** :
  [arcep.fr — « Mon réseau mobile »](https://www.arcep.fr/mes-demarches-et-services/consommateurs/fiches-pratiques/comment-utiliser-mon-reseau-mobile.html)
- **Contact** : <https://www.arcep.fr/nous-contacter.html>

<div align="center">

—

*« Mon réseau mobile » — un service de l'Arcep.*

</div>
