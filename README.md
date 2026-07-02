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

🌍 **Other languages:** 
[English](docs/en/README.en.md) / [Español](docs/es/README.es.md)

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
- [Qui sommes-nous ?](#-qui-sommes-nous-?)
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

- les **particuliers** et les **entreprises** qui veulent comparer les réseaux avant de changer d'opérateur ;
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

## 🖼️ Captures d'écran

<table style="width:100%; table-layout:fixed">
  <tr>
    <th>Couverture mobile</th>
    <th>Qualité de service</th>
    <th>Antennes et déploiements</th>
    <th>Zones à couvrir</th>
    <th>Signalements</th>
  </tr>
  <tr>
    <td><img src="docs/coverage.png" alt="Carte de couverture mobile par opérateur" width="100%"></td>
    <td><img src="docs/qos.png" alt="Tests de qualité de service" width="100%"></td>
    <td><img src="docs/antenna.png" alt="Antennes et déploiements 4G/5G" width="100%"></td>
    <td><img src="docs/zac.png" alt="Zones à couvrir du dispositif de couverture ciblée" width="100%"></td>
    <td><img src="docs/signalements.png" alt="Signalements J'alerte l'Arcep" width="100%"></td>
  </tr>
</table>

Accéder à l'application : **<https://monreseaumobile.arcep.fr/>**  

---

## 📜 Licences

- **Code source** : publié sous **GNU GPL-3.0**. Voir [`LICENSE`](LICENSE).
- **Données** : Les jeux de données sont sous licence ouverte (voir le détail sur la page de chacun sur data.gouv.fr) 
- **Marques et logos** : Logos Arcep - protégés, exclus de la licence du code et non réutilisables sans autorisation.

---

## 🧰 Pile technique

---

- **Cartographie** : MapLibre GL JS, pg_tileserv, tuiles vectorielles.
- **Front-end** : Next.js, Tailwind.
- **Back-end** : Django.
- **Données géospatiales** : PostgreSQL + PostGIS.
- **Conteneurisation & déploiement** : Docker, Ansible.

---

## 🏗️ Architecture

<img src="docs/stack.png" alt="Architecture">

Vous pouvez monter la base de données grâce au fichier _skeleton-db-mrm.sql_. Les extensions requises sont : [postgis](https://postgis.net/), [pg_trgm](https://docs.postgresql.fr/9.6/pgtrgm.html), [unaccent](https://docs.postgresql.fr/10/unaccent.html), [pg_buffercache](https://docs.postgresql.fr/11/pgbuffercache.html).  

---

## 🗂️ Sources de données

Les données affichées proviennent de sources ouvertes et de transmissions réglementaires des
opérateurs. Les principales sources publiques réutilisables sont :

| Données | Producteur | Accès |
| --- | --- | --- |
| Cartes de couverture | Opérateurs / Arcep | [data.arcep.fr](https://data.arcep.fr/mobile/couvertures_theoriques/) |
| Mesures de qualité de service | Arcep | [data.arcep.fr](https://data.arcep.fr/mobile/mesures_qualite_arcep/) |
| Mesures de crowdsourcing | Collectivités / Entreprises | [data.arcep.fr](https://data.arcep.fr/mobile/mesures_crowdsourcing/) |
| Antennes et déploiements | Arcep / ANFR | [data.arcep.fr](https://data.arcep.fr/mobile/sites/) · [data.gouv](https://www.data.gouv.fr/datasets/donnees-sur-les-installations-radioelectriques-de-plus-de-5-watts-1) |
| Zones à couvrir | Arcep / Gouvernement | [data.arcep.fr](https://data.arcep.fr/mobile/dispositif_couverture_ciblee/) |
| Signalements consommateurs | Arcep (« J'alerte l'Arcep ») | Non disponibles |

Les jeux de données sont sous licence ouverte (voir le détail sur la page de chacun sur data.gouv.fr).
Vérifiez la licence propre à chaque jeu de données avant toute réutilisation.

---

## ♿ Accessibilité et éco-conception

Service public numérique, l'application a été développée en visant une conformité au [RGAA](https://accessibilite.numerique.gouv.fr/) (Référentiel général
d'amélioration de l'accessibilité) et au [RGESN](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) (Référentiel général d'écoconception de services numériques). 
Toute contribution doit veiller à ne pas dégrader l'accessibilité (navigation clavier, contrastes, alternatives
textuelles, ARIA) ni la sobriété (poids des assets, requêtes réseau).

---

## 🔐 Sécurité

Merci de **ne pas** divulguer publiquement une faille de sécurité dans une _issue_.
Signalez-la de manière responsable via le canal indiqué dans [`/docs/SECURITY.md`](docs/SECURITY.md) ou
via l'adresse de contact ci-dessous. 

Adresse de contact : opendata@arcep.fr

**Mon reseau mobile** fait l'objet d'audits de sécurité réguliers et s'inscrit dans la 
démarche de sécurisation des systèmes d'informations proposée par l'ANSSI (Agence nationale 
de la sécurité des systèmes d'information) via [MonServiceSécurisé](https://monservicesecurise.cyber.gouv.fr/).
Néanmoins, des failles peuvent subsister. 

---

## 🏛️ Qui sommes-nous ?

L’Arcep, c’est « _l’Autorité de régulation des communications électroniques, des postes et de la distribution de la presse_ » : elle veille à l’accès au numérique en France, partout, pour tous et pour longtemps. Elle conduit les opérateurs à concilier leurs intérêts économiques avec des objectifs d’intérêt général.

**Pourquoi ?** Parce que l’accès à la fibre, la 4G ou la 5G, à un choix de services numériques de qualité et durables, à des prix justes sur tout le territoire, est devenu essentiel pour les citoyens et les entreprises. 

**Comment ?** L’Arcep fixe des règles et des obligations aux opérateurs pour favoriser la concurrence, assurer l’aménagement numérique du territoire et les inciter à investir dans l’amélioration de leurs services, elle collecte et en publie des informations pour plus de transparence, ou utilise son pouvoir de sanction. 

Autorité Administrative Indépendante (AAI), elle agit en toute indépendance par rapport au gouvernement et aux entreprises.

Visitez notre [site web](https://www.arcep.fr/) pour plus d'informations.

---

## 🙏 Crédits et contact

- **Éditeur** : Neogeo Technologies, BAL, 67 All. Jean Jaurès, 31000 Toulouse.
- **Données partenaires** : Collectivités territoriales, Speedchecker, Ookla (liste non-exhaustive)
- **Service en ligne** : <https://monreseaumobile.arcep.fr/>
- **Page d'information** :
  [Comment utiliser « Mon réseau mobile » ?](https://www.arcep.fr/mes-demarches-et-services/consommateurs/fiches-pratiques/comment-utiliser-mon-reseau-mobile.html)
- **Contact** : opendata@arcep.fr

<div align="center">

—

*« Mon réseau mobile » — un service de l'Arcep.*

</div>
