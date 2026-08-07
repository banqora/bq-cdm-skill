# Industry-body guidance

Use this reference for market practice, agreement, adoption, collateral, and reporting context.
Use FINOS CDM source and runtime artefacts—not association prose—for the technical contract.

## Apply a freshness and evidence rule

Association guidance can lag the active CDM release, even when a page labels a handbook or
download as "current". Before relying on a source:

1. record its publisher, title, canonical URL, publication or update date, and retrieval date;
2. record every stated CDM, agreement, regulation, or message-specification version and whether
   it is a recommendation, draft, or historical material; use `not stated` when absent;
3. prefer the publisher's stable landing page and select the latest applicable document there;
4. verify technical claims about types, fields, cardinalities, functions, JSON, validation, or
   runtime behavior against the exact active-version Rune source and generated runtime;
5. present market guidance as context or best practice, not as legal advice or proof of CDM
   behavior.

If the association guidance and active artefact disagree, report the disagreement and follow the
active artefact for implementation. Do not silently modernize an old example.

## ISDA: derivatives, collateral, reporting, and FpML

### What does ISDA say CDM is for in derivatives?

Start with the [ISDA CDM InfoHub](https://www.isda.org/isda-solutions-infohub/cdm/). It routes to
ISDA's introductory modules and derivatives, collateral, and regulatory-reporting use cases. Use
it for business rationale and ISDA-led adoption context, not generated API details.

### How is CDM applied to collateral management?

Use [ISDA's Collateral Initiatives](https://www.isda.org/2023/02/16/isda-collateral-initiatives/)
for the collateral start-up modules, eligible-collateral work, and business workflows. Confirm the
date and CDM version of any linked tutorial before following its object paths or examples.

### What is ISDA Digital Regulatory Reporting?

Use the [ISDA DRR InfoHub](https://www.isda.org/isda-solutions-infohub/isda-digital-regulatory-reporting/)
for supported regimes, implementation material, training, and release context. Regulatory scope
and compliance dates change independently of CDM. Check the applicable jurisdiction and current
rule set, then review the separate
[ISDA DRR licence](https://www.isda.org/2023/09/19/isda-digital-regulatory-reporting-drr-license/)
before copying or distributing DRR material.

### Is FpML the same thing as CDM?

No. FpML is an ISDA-owned adjacent standard for exchanging and processing derivatives
information; CDM is a domain and process model. Use the [ISDA FpML InfoHub](https://www.isda.org/isda-solutions-infohub/fpml/)
for orientation and [The FpML Standard](https://www.fpml.org/the_standard/) for schemas, views,
coding schemes, examples, errata, and version status. Record the exact FpML version, build, view,
and maturity: a working draft is not a recommendation. Review the
[FpML Public License](https://www.fpml.org/the_standard/fpml-public-license/) before reuse.

## ISLA: securities lending, GMSLA, and operational practice

### What CDM coverage and activity exist for securities lending?

Start with ISLA's [Common Domain Model hub](https://www.islagroup.org/common-domain-model/).
Use it to find securities-lending coverage assessments, event-negotiation examples, business
cases, roadmaps, and working-group material. Coverage percentages and example JSON are
version-specific claims; capture their source date and stated CDM version.

### Why and where might a securities-lending firm adopt CDM?

Use [CDM: The Road to Adoption](https://www.islagroup.org/cdm-the-road-to-adoption/) for use cases
across lifecycle efficiency, collateral, regulatory reporting, legal documentation, and pre-trade.
Treat it as an adoption guide rather than a statement of current executable coverage.

### What is current securities-lending best practice?

Use the [ISLA Best Practice Handbook](https://www.islagroup.org/isla-best-practice-handbook/)
for operational market practice and the versioned CDM handbooks it currently lists. Check each
page's status, last-updated date, audit/version history, and named CDM version. Guidance may be
voluntary, under review, or still aligned to an older production release.

### How do GMSLA clauses and negotiated outcomes relate to CDM?

Use the [ISLA Clause Library & Taxonomy](https://www.islagroup.org/isla-clause-library-and-taxonomy/)
for GMSLA clause outcomes and their relationship to CDM legal-agreement data. Access and use are
subject to ISLA terms: some content is member- or subscriber-only and commercial hosting can
require a licence. Do not scrape, cache, embed, or redistribute restricted content.

## ICMA: repo, bonds, GMRA, and repo practice

### What repo and bond products or lifecycle events does CDM cover?

Start with ICMA's [FINOS CDM for repo and bonds hub](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/fintech/common-domain-model-cdm/).
It routes to the project scope, demonstrations, phase reports, factsheets, and implementation
work. Treat phase reports and recordings as dated evidence, not the live model inventory.

### What is accepted European repo market practice?

Use the [ICMA ERCC Guide to Best Practice in the European Repo Market](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/icma-ercc-publications/icma-ercc-guide-to-best-practice-in-the-european-repo-market/).
Select the latest guide from that landing page, record its effective date, and do not substitute
an archived edition. The recommendations provide market context; parties can agree different
terms, and the guide is not proof that a CDM function enforces them.

### Where does CDM fit into a repo application stack?

Use ICMA's [implementation workshop](https://www.icmagroup.org/media-and-market-data/icma-webinars-and-podcasts/how-to-implement-the-cdm-and-automate-repo-trading-and-related-lifecycle-events/)
for model-to-model mapping, integration, language, messaging, and lifecycle questions. The page
or recording may require an ICMA member login. Do not bypass access controls or infer a right to
redistribute workshop material.

## Access and reuse boundary

Publicly reachable does not mean freely redistributable. Link to association material by default.
Do not vendor page text, PDFs, recordings, embeddings, agreement language, or member content
unless the applicable terms expressly permit it. Preserve required attribution and licence notices
for ISDA DRR or FpML. When access is restricted, tell the user what source exists and ask them to
provide an authorised copy if its contents are needed.
