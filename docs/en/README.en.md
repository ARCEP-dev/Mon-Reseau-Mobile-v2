<div align="center">

# Mon réseau mobile

**Compare the coverage and quality of service of mobile operators in France**

[![Code licence](https://img.shields.io/badge/Code-GPLv3-blue.svg)](../../LICENSE)
[![Data licence](https://img.shields.io/badge/Data-Open%20Licence%201.0-blue.svg)](#-licenses)
[![Online service](https://img.shields.io/badge/Demo-monreseaumobile.arcep.fr-green.svg)](https://monreseaumobile.arcep.fr/)
[![Public code](https://img.shields.io/badge/code.gouv.fr-referenced-informational.svg)](https://code.gouv.fr/)

[Open the service](https://monreseaumobile.arcep.fr/) ·
[Report a bug](../../../../issues) ·

</div>

🌍 **Other languages:**
[Français](../../README.md)   [Español](../es/README.es.md)

---

## Contents

- [About](#-about)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Data sources](#-data-sources)
- [Architecture](#-architecture)
- [Tech stack](#-tech-stack)
- [Accessibility and eco-design](#-accessibility-and-eco-design)
- [Security](#-security)
- [Licenses](#-licenses)
- [Who are we?](#-who-are-we)
- [Credits and contact](#-credits-and-contact)

---

## ℹ️ About

**"Mon réseau mobile"** is a mapping tool published by the **Arcep** (the French regulatory
authority for electronic communications, postal services and press distribution).
This version corresponds to the one available since **August 2025**. **"Mon réseau mobile"**
lets you compare the performance of mobile operators in terms of coverage
(services: "Calls and SMS" and "Mobile internet") and quality of service, both at home and
while travelling, across metropolitan France and the overseas territories.

The service is aimed at all audiences:

- **individuals** and **businesses** who want to compare networks before switching operator;
- **local authorities** monitoring the rollout of mobile networks across their area.

This repository publishes the application's **source code**, in line with the open-source
policy for government code (article L.300-4 of the French code on relations between the public
and the administration). It aims for transparency, reuse and community contribution.

> ℹ️ This README describes the project for reuse purposes. The reference service remains
> the one published by Arcep: <https://monreseaumobile.arcep.fr/>.

---

## ✨ Features

The application renders, on an interactive map background, several layers of information
available by operator and by technology (2G / 3G / 4G):

- **Theoretical coverage maps**
  - _Calls and SMS_ coverage
  - _Mobile internet_ coverage
- **Network quality tests** from the field measurement campaigns run by Arcep and its partners
  - _Web browsing_ tests
  - _Online video_ tests
  - _Download throughput_ tests
  - _File upload_ tests
  - _Voice_ tests
  - _SMS_ tests
- **Antennas and deployments**
  - Location of sites by operator.
  - Location of sites experiencing outages.
- **Areas to be covered**
  - _Points of interest_ (POI) and areas identified by public authorities.
  - _Priority road routes_ and _rail routes_.
- **Reports** submitted via [« J'alerte l'Arcep »](https://www.arcep.fr/nos-sujets/jalerte-larcep-un-geste-citoyen-pour-ameliorer-les-reseaux-dechange.html).

> ⚠️ Coverage information is **simulated** and provided for indicative purposes only, with no
> contractual value. Actual coverage may vary depending on the device, buildings, weather,
> season and network load.

---

## 🖼️ Screenshots

<table style="width:100%; table-layout:fixed">
  <tr>
    <th>Mobile coverage</th>
    <th>Quality of service</th>
    <th>Antennas and deployments</th>
    <th>Areas to be covered</th>
    <th>Reports</th>
  </tr>
  <tr>
    <td><img src="../coverage.png" alt="Mobile coverage map by operator" width="100%"></td>
    <td><img src="../qos.png" alt="Quality-of-service tests" width="100%"></td>
    <td><img src="../antenna.png" alt="4G/5G antennas and deployments" width="100%"></td>
    <td><img src="../zac.png" alt="Areas to be covered under the targeted coverage scheme" width="100%"></td>
    <td><img src="../signalements.png" alt="J'alerte l'Arcep reports" width="100%"></td>
  </tr>
</table>

Open the application: **<https://monreseaumobile.arcep.fr/>**

---

## 📜 Licenses

- **Source code**: published under **GNU GPL-3.0**. See [`LICENSE`](../../LICENSE).
- **Data**: the datasets are under an open licence (see the details on each one's page on data.gouv.fr).
- **Trademarks and logos**: Arcep logo — protected, excluded from the code licence and not reusable without authorisation.

---

## 🧰 Tech stack

- **Mapping**: MapLibre GL JS, pg_tileserv, vector tiles.
- **Front-end**: Next.js, Tailwind.
- **Back-end**: Django.
- **Geospatial data**: PostgreSQL + PostGIS.
- **Containerisation & deployment**: Docker, Ansible.

---

## 🏗️ Architecture

<img src="../stack.png" alt="Architecture">

---

## 🗂️ Data sources

The data displayed comes from open sources and from regulatory submissions by operators.
The main reusable public sources are:

| Data | Producer | Access |
| --- | --- | --- |
| Coverage maps | Operators / Arcep | [data.arcep.fr](https://data.arcep.fr/mobile/couvertures_theoriques/) |
| Quality-of-service measurements | Arcep | [data.arcep.fr](https://data.arcep.fr/mobile/mesures_qualite_arcep/) |
| Crowdsourcing measurements | Local authorities / Companies | [data.arcep.fr](https://data.arcep.fr/mobile/mesures_crowdsourcing/) |
| Antennas and deployments | Arcep / ANFR | [data.arcep.fr](https://data.arcep.fr/mobile/sites/) · [data.gouv](https://www.data.gouv.fr/datasets/donnees-sur-les-installations-radioelectriques-de-plus-de-5-watts-1) |
| Areas to be covered | Arcep / Government | [data.arcep.fr](https://data.arcep.fr/mobile/dispositif_couverture_ciblee/) |
| Consumer reports | Arcep ("J'alerte l'Arcep") | Not available |

The datasets are under an open licence (see the details on each one's page on data.gouv.fr).
Check the licence specific to each dataset before any reuse.

---

## ♿ Accessibility and eco-design

As a public digital service, the application was developed aiming for compliance with the [RGAA](https://accessibilite.numerique.gouv.fr/)
(General accessibility improvement framework) and the [RGESN](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/)
(General framework for eco-design of digital services).
Any contribution must take care not to degrade accessibility (keyboard navigation, contrast,
text alternatives, ARIA) or frugality (asset weight, network requests).

---

## 🔐 Security

Please do **not** disclose a security vulnerability publicly in an _issue_.
Report it responsibly via the channel indicated in [`/docs/SECURITY.md`](../SECURITY.md) or
via the contact address below.

Contact address: opendata@arcep.fr

**Mon réseau mobile** undergoes regular security audits and is part of the information-systems
security approach offered by the ANSSI (French National Cybersecurity Agency) through
[MonServiceSécurisé](https://monservicesecurise.cyber.gouv.fr/). Nevertheless, vulnerabilities
may remain.

---

## 🏛️ Who are we?

Arcep is the "Autorité de régulation des communications électroniques, des postes et de la distribution de la presse" (the regulatory authority for electronic communications, postal services and press distribution): it works to ensure access to digital services across France — everywhere, for everyone and for the long term. It steers operators towards reconciling their economic interests with objectives of general interest.

**Why?** Because access to fibre, 4G or 5G, to a choice of high-quality and sustainable digital services, at fair prices across the whole territory, has become essential for citizens and businesses.

**How?** Arcep sets rules and obligations for operators to foster competition, ensure digital development of the territory and encourage them to invest in improving their services; it collects and publishes information for greater transparency, and uses its power of sanction.

An Independent Administrative Authority (AAI), it acts in complete independence from the government and from companies.

Visit our [website](https://www.arcep.fr/) for more information.

---

## 🙏 Credits and contact

- **Publisher**: Neogeo Technologies, BAL, 67 All. Jean Jaurès, 31000 Toulouse.
- **Partner data**: Local authorities, Speedchecker, Ookla (non-exhaustive list)
- **Online service**: <https://monreseaumobile.arcep.fr/>
- **Information page**:
  [How to use "Mon réseau mobile"?](https://www.arcep.fr/mes-demarches-et-services/consommateurs/fiches-pratiques/comment-utiliser-mon-reseau-mobile.html)
- **Contact**: opendata@arcep.fr

<div align="center">

—

*"Mon réseau mobile" — a service by Arcep.*

</div>
