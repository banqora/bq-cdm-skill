# Legal agreements and contractual documentation

Use this reference when modelling, mapping, validating, reconciling, or changing legal
agreements and contractual documentation. It is an engineering guide, not legal advice. Keep
the executed text and qualified legal analysis authoritative for rights, obligations,
enforceability, and regulatory-capital treatment.

## Contents

- [Fix the evidence baseline](#fix-the-evidence-baseline)
- [Keep six layers separate](#keep-six-layers-separate)
- [Read the exact CDM legal structure](#read-the-exact-cdm-legal-structure)
- [Respect product, master, and collateral boundaries](#respect-product-master-and-collateral-boundaries)
- [Treat formation and amendment as lifecycle events](#treat-formation-and-amendment-as-lifecycle-events)
- [Implement from evidence](#implement-from-evidence)
- [Apply lessons from production-style implementations](#apply-lessons-from-production-style-implementations)
- [Use association material carefully](#use-association-material-carefully)
- [Test non-vacuously](#test-non-vacuously)

## Fix the evidence baseline

This reference was rechecked on 2026-08-07 against
`org.finos.cdm:cdm-java:7.0.0`, the matching embedded Rune source, and the generated JVM
interfaces and validators. FINOS published the
[7.0.0 release](https://github.com/finos/common-domain-model/releases/tag/7.0.0) on
2026-07-17; its Git tag ref was `a6ffe777bc12ef3d289579cb3a86d1cbffea63d2` when
checked. Re-establish these facts for the project's resolved version rather than treating this
snapshot as timeless.

Use this authority order for implementation decisions:

1. executed documents, applicable law, and current qualified legal advice for the parties and
   jurisdictions;
2. current publisher material and an applicable current legal opinion for market-document
   meaning and enforceability;
3. exact-version Rune source plus generated/runtime behaviour for the CDM technical contract;
4. application mappings, derived classifications, and policy, each labelled as such.

The public [FINOS legal-agreements guide](https://cdm.finos.org/docs/legal-agreements/) still
labels itself version 6.0.0, while the
[next guide](https://cdm.finos.org/docs/next/legal-agreements/) follows unreleased development.
Use those pages for concepts, not as a substitute for the selected release. Record the page's
displayed version, publication/update date if given, and retrieval date.

## Keep six layers separate

| Layer | CDM location or evidence | What it establishes |
|---|---|---|
| Product economics | `NonTransferableProduct.economicTerms`, price and quantity | What is traded and paid or delivered. |
| Transaction contract | `Trade`, `TradeState`, and `Trade.contractDetails` | The executed transaction and its lifecycle state. |
| Relationship agreement | `LegalAgreement` | The master, confirmation, credit-support, security, or other agreement and its structured terms. |
| Human document | `LegalAgreement.attachment` as `Resource`, plus the controlled source record | The text or file from which structured data was read. |
| Structured elections | One branch of `Agreement`, typed terms, or clause/variant/variable identifiers | Selected business outcomes; never the legal prose itself. |
| Application assertion | source mapping, policy, inference, extension, reconciliation | A claim made outside CDM; name its basis and confidence. |

FINOS uses **legal agreement** for relationship-level written terms and **contract** for the
terms of an executed transaction. A `Trade` can therefore contain product economics and link
to one or more governing `LegalAgreement` objects through `ContractDetails.documentation`.
Do not flatten product terms, a confirmation, a master agreement, and its collateral annex
into one undifferentiated record.

## Read the exact CDM legal structure

### Identify the agreement before representing its terms

In CDM 7.0.0, `LegalAgreement` is a keyed root type extending `LegalAgreementBase`:

- `legalAgreementIdentification` is required and composes `agreementName`, `publisher`,
  `vintage`, and `governingLaw`;
- `contractualParty` requires exactly two party references;
- `agreementDate`, `effectiveDate`, one or more `identifier` values, `otherParty`, and
  `attachment` are baseline attributes;
- exactly one of `agreementTerms` and `umbrellaAgreement` is required by the
  `AgreementType` condition;
- `relatedAgreements` points to the agreement or agreements that **govern this agreement**.
  A confirmation or annex points upward to its master; the master does not acquire a second
  child roster.

`AgreementName` is composable. `agreementType` distinguishes master agreement, credit-support
agreement, confirmation, master confirmation, security agreement, and other. More specific
attributes identify the master or credit-support type and can record contractual definitions,
supplements, and matrices. `publisher` and `vintage` describe a published form; they are not a
bilateral agreement identifier. Preserve the parties' stable agreement reference separately in
`LegalAgreement.identifier`, including its issuer reference or explicit issuer and the issuer's
metadata scheme where supplied.

The version-pinned source anchors are:

- [`legaldocumentation-common-type.rosetta`](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-common-type.rosetta)
  for `LegalAgreement`, identification, terms, resources, and related agreements;
- [`legaldocumentation-master-type.rosetta`](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-master-type.rosetta)
  and the exact-version
  [master enums](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-master-enum.rosetta)
  for schedules, clauses, variants, variables, and master-election choices;
- the specialised [ISDA](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-master-isda-type.rosetta),
  [ISLA](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-master-isla-type.rosetta), and
  [ICMA](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-master-icma-type.rosetta)
  master-agreement sources, whose branch depth must be assessed separately;
- [`legaldocumentation-csa-type.rosetta`](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/legaldocumentation-csa-type.rosetta)
  for credit support, collateral transfer, and security-agreement elections;
- [`event-common-type.rosetta`](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/event-common-type.rosetta)
  for contract details, formation instructions, and agreement events, plus
  [`event-common-func.rosetta`](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/event-common-func.rosetta)
  for the corresponding formation and agreement-event functions.

Locate the same anchors in any resolved release with:

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
resolved_cdm_jar=/path/to/resolved/cdm-java.jar
"$CDM_SOURCE" --jar "$resolved_cdm_jar" version
"$CDM_SOURCE" --jar "$resolved_cdm_jar" search '^type (LegalAgreement|LegalAgreementBase|LegalAgreementIdentification|AgreementName|Agreement):'
"$CDM_SOURCE" --jar "$resolved_cdm_jar" search '^type (ContractDetails|ContractFormationInstruction|AgreementEvent|AgreementTermsChangeInstruction):'
"$CDM_SOURCE" --jar "$resolved_cdm_jar" search '^func (Create_ContractFormation|Create_AgreementEvent|Create_AgreementTermsChange):'
"$CDM_SOURCE" --jar "$resolved_cdm_jar" search '^enum (LegalAgreementTypeEnum|LegalAgreementPublisherEnum|MasterAgreementClauseIdentifierEnum):'
```

Do not infer the wire shape from Rune alone. Generated JVM fields annotated with metadata are
wrapper types, while Rune JSON uses `@data`, `@scheme`, `@key`, and `@ref`; older examples may
use legacy `value` and `meta` wrappers. Follow the selected runtime and the
[Rune serialization specification](https://rune.finos.org/docs/serialization/), and declare the
dialect at every boundary.

### Know what validation proves

Rune cardinalities and conditions generate executable validators; see the
[Rune validation guide](https://rune.finos.org/docs/modelling-components/data-validation/).
Against 7.0.0, validating an empty `LegalAgreement` produced three meaningful failures:

- neither `agreementTerms` nor `umbrellaAgreement` was set;
- required `legalAgreementIdentification` was absent; and
- required `contractualParty` was absent.

This proves model inconsistency only. A validator cannot prove that a document was signed,
that a mapped election matches the prose, that a signatory had authority, that a netting
opinion covers the parties, or that an agreement is enforceable.

### Treat coverage gaps as gaps

The 7.0.0 source exposes `isdaMaster`, `islaGmsla`, and `icmaGmra` master-election branches, but
their depth is not equivalent:

- the ISDA Master branch has typed election structures;
- the GMSLA branch has a typed subset and the generic `MasterAgreementSchedule` clause library;
- `MasterAgreementClauseIdentifierEnum` and its variant enum contain GMSLA identifiers only;
- `GlobalMasterRepoAgreement` has an empty body, so the GMRA branch identifies the agreement
  but carries no typed GMRA elections.

Never file GMRA terms under GMSLA clause identifiers to make a document validate. If an
application must represent an unsupported clause set, keep it in a clearly named extension,
record the external taxonomy/version and licence, and label the output `extension` rather than
CDM. Recheck these observations on every version change.

## Respect product, master, and collateral boundaries

### Choose the agreement family from evidence

- OTC derivatives commonly use an ISDA Master Agreement, transaction confirmations and
  definitions, with separate credit-support documentation where applicable.
- Securities lending commonly uses an ISLA GMSLA. Distinguish the 2010 title-transfer form
  from the 2018 security-interest-over-collateral framework and its supporting security and
  control agreements.
- Repo commonly uses an ICMA/SIFMA GMRA. Do not substitute GMSLA merely because both concern
  securities financing, or an ISDA Master merely because CDM originated in derivatives.

A product qualification can suggest the usual document family; it cannot establish which
agreement these parties executed. Rank evidence explicitly: an executed agreement on file is
stronger than a feed-stated agreement, which is stronger than a qualification-derived guess.
Return `unknown` when none exists.

### Model collateral documents by legal function

Do not collapse these structures:

- CSA/CSD elections cover variation margin, initial margin, or legacy credit support;
- a CTA covers collateral-transfer mechanics, while a related Security Agreement covers the
  grant and enforcement of security;
- GMSLA title-transfer and pledge structures have different property and control mechanics;
- eligible-collateral criteria describe what may be posted; a collateral portfolio or position
  describes what is actually posted; and a transaction's collateral economics are not the
  governing collateral agreement.

The selected jurisdiction, form, vintage, margin type, custodian/control arrangement, related
agreements, and amendments all matter. Never derive one from a similarly named enum. Require a
legal/domain owner to decide the applicable documents and any opinion-coverage policy.

## Treat formation and amendment as lifecycle events

CDM separates execution from contract formation. In 7.0.0,
`Create_ContractFormationInstruction` requires every supplied legal agreement to have an
`agreementDate`; `Create_ContractFormation` appends distinct agreements to
`trade.contractDetails.documentation` and moves the position state to `Formed`. This date rule
does not mean every standalone `LegalAgreement` must be executed: an undated negotiation draft
can exist, but it cannot be used by this formation path or referenced from `ContractDetails`.

Agreement lifecycle is distinct from trade lifecycle. `AgreementEvent` carries event and
effective dates, before references, instructions, intent, and after agreements. The 7.0.0
`Create_AgreementTermsChange` branches implement legacy, variation-margin, and initial-margin
CSA election changes; the party-change function is separate. The enum also names termination,
but a name in an intent enum is not proof of a complete state transition.

Therefore:

- retain immutable source documents and before/after legal records;
- link an amendment, protocol adherence, annex, or notice as evidence for the change;
- use the released function only for a case its source actually implements;
- validate the after agreement and all still-governed trades; and
- implement unsupported master, GMRA, GMSLA, termination, or status workflows as explicit
  application policy until exact-version CDM behaviour exists and is tested.

Do not overwrite the prior agreement or silently mutate every governed trade. Agreement dates,
effective dates, event dates, and transaction dates are different facts.

## Implement from evidence

1. **Inventory the document set.** Identify base form, schedule, confirmation, definitions,
   CSA/CSD or CTA/SA, GMSLA/GMRA annexes, amendments, protocols, notices, and governing
   relationships. Record execution and effective status separately.
2. **Pin the technical baseline.** Record CDM coordinate, source tag/commit, runtime, language
   distribution, JSON dialect, root type, and generated-code version.
3. **Create an evidence record.** For every source record capture publisher, canonical title,
   document/version date, retrieval date, agreement identifier, file hash, access control,
   licence, extraction method, reviewer, and source location.
4. **Map identification first.** Map exact parties, agreement type and subtype, publisher,
   vintage, governing law, bilateral identifier and issuer. Do not default missing law, date,
   agreement, party, or election.
5. **Map terms to one valid branch.** Use the exact form and margin type. Preserve bespoke or
   unmodelled terms as reviewed extensions or unmapped findings; never borrow a neighbouring
   enum value.
6. **Build relationships upward.** A child agreement names the master that governs it. Resolve
   references using stable keys and reject ambiguous or contradictory matches.
7. **Validate in layers.** Deserialize and resolve references, run generated cardinality and
   data-rule validators, then run application policy and source-to-structured reconciliation.
8. **Form only with executed evidence.** Add an agreement to transaction contract details only
   after execution status, parties and applicability have been established.
9. **Apply changes append-only.** Produce a dated event and valid after-state, retaining the
   amendment and before-state. State whether CDM, an extension, or application policy performed
   the transition.
10. **Have a human approve legal assertions.** Legal counsel or the authorised documentation
    function must approve enforceability, coverage, interpretation, and production use.

## Apply lessons from production-style implementations

These guardrails came from failures that produced plausible, validator-clean output:

- **Absence must stay visible.** A feed that lacks governing law or agreement date must yield
  `unmapped` or `unknown`, not the most common value in test data.
- **State the basis per claim.** Distinguish `on-file`, `source-stated`, `qualification-derived`,
  `extracted-draft`, `extension`, and `simulated`. Validation does not upgrade provenance.
- **Match a relationship, not a filename.** Require both counterparties. Prefer identifiers,
  but refuse a match when an LEI and a clearly different legal name contradict each other;
  do not guess which identifier is wrong.
- **Keep a citable source.** An agreement record needs its bilateral identifier, execution
  status, and attached source or controlled-document reference. A type/publisher/vintage tuple
  alone is not the parties' agreement.
- **Do not confuse an illustrative snippet with a valid object.** Official examples can omit
  parties, agreement terms, dates, metadata wrappers, or references to show one concept.
- **Revalidate reconstructed objects.** Rebuilding a counterparty view or projection can lose
  identifier issuers, metadata wrappers, reference keys, or a required choice even when the
  original was valid.
- **Preserve legal dependencies through trade events.** An unrelated amendment must not drop
  settlement accounts, agreement references, or inputs from which legal elections are derived.
  Missing optional input often shortens an election list without producing a failure.
- **Namespace extensions.** A CDM-shaped clause schedule is not CDM if its identifiers and
  semantics come from an application. Publish its owner, version, mapping and conformance rules.
- **Separate reconciliation scope.** Compare the governing agreements and fields actually held
  by both sides; do not report every supporting annex or confirmation as a missing master.

## Use association material carefully

Use publisher landing pages to choose the current applicable material. Never select a document
only because its year is numerically latest; jurisdiction, collateral structure, party type,
annexes, amendments, and opinion coverage determine applicability.

### Derivatives and ISDA documentation

- Use [ISDA MyLibrary](https://www.isda.org/isda-solutions-infohub/mylibrary/) for the current
  controlled catalogue and version comparison; many documents require a purchase or subscription.
- Use the [ISDA Clause Library](https://www.isda.org/book/isda-clause-library-isda-master-agreement/)
  and [ISDA Create](https://www.isda.org/isda-solutions-infohub/isda-create/) for current access,
  supported forms, negotiation, and structured-data context. Do not assume CDM contains every
  taxonomy outcome offered by either service.
- Use [ISDA's opinions overview](https://www.isda.org/opinions-overview/) and
  [current opinion-update status](https://www.isda.org/status-isda-opinion-updates/) to identify
  the relevant netting and collateral opinion. Confirm document form, governing law,
  jurisdiction, branch, counterparty type, reliance rights, assumptions, and update date.

### Securities lending and ISLA documentation

- Start at [ISLA Legal Services](https://www.islagroup.org/legal-services/) and distinguish
  [GMSLA title transfer](https://www.islagroup.org/gmsla-title-transfer/) from
  [GMSLA security interest](https://www.islagroup.org/gmsla-security-interest/).
- Use the [ISLA Clause Library & Taxonomy](https://www.islagroup.org/isla-clause-library-and-taxonomy/)
  for business-outcome identifiers, variants, variables and usage terms. It is licensed content,
  not legal advice, and current CDM coverage must be checked separately.
- Use the [GMSLA netting-opinions page](https://www.islagroup.org/gmsla-title-transfer/gmsla-netting-opinions/)
  and the applicable [security-interest opinions](https://www.islagroup.org/gmsla-security-interest/gmsla-security-interest-opinions/).
  Coverage and reliance are not interchangeable between title transfer and pledge.

### Repo and ICMA documentation

- Use ICMA's [GMRA landing page](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/legal-documentation/global-master-repurchase-agreement-gmra/)
  to choose the official form, related annexes and guidance. Check for newer addenda affecting
  the specific transaction rather than hard-coding “GMRA 2011” as a universal answer.
- Use the [ICMA GMRA Clause Library and Taxonomy](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/legal-documentation/icma-gmra-clause-library-and-taxonomy/)
  for licensed GMRA outcomes. CDM 7.0.0 does not provide equivalent typed GMRA election fields.
- Use [ICMA GMRA legal opinions](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/legal-documentation/icma-gmra-legal-opinions/)
  for the current jurisdiction, counterparty and annex coverage. Opinion matrices and the
  underlying opinions change independently of CDM releases.

Public reachability does not grant reuse rights. Link by default. Do not scrape, vendor, embed,
fine-tune on, or build a shared vector index from agreement text, clause libraries, taxonomies,
opinions, or member material unless the licence expressly permits that use. For authorised
private retrieval, enforce tenant isolation, access expiry, source-level permissions, deletion,
and citations to the exact document version.

## Test non-vacuously

Keep the following properties executable. Every corpus test needs a positive floor before
`all` or loop assertions so an empty directory cannot pass.

### Model and runtime contract

- Assert the resolved CDM version and inspect the matching Rune source.
- Validate at least one populated `LegalAgreement` with two real-shaped parties,
  identification, one agreement branch, an identifier, and meaningful terms.
- Mutate that fixture to prove independent failures for: one contractual party; neither
  `agreementTerms` nor `umbrellaAgreement`; a CSA/security election inconsistent with its
  identification; and an executed child pointing to an undated governing agreement.
- Prove that attaching an undated agreement to `ContractDetails` or contract formation fails,
  while an explicitly labelled standalone draft remains representable.
- Test both Rune JSON and any supported legacy dialect with metadata wrappers and resolved
  references; JSON Schema alone is insufficient.

### Mapping, provenance, and reconciliation

- Remove each source legal field in turn and assert it becomes `unmapped` or absent, never a
  default. Change governing law in the source and assert the result follows it.
- Assert precedence among on-file, source-stated and qualification-derived agreement claims,
  including an `unknown` case.
- Test cosmetic party-name variation, identifier-only matches, one-counterparty-only matches,
  duplicate relationships, and an LEI/name contradiction that must be refused.
- Assert that every returned agreement retains its source reference, bilateral identifier,
  execution status, provenance and validator findings.
- Derive every reported reconciliation break from two actual views; assert at least one
  compared agreement and one deliberately introduced difference.

### Lifecycle and extension boundaries

- Assert the before agreement remains byte-for-byte available after an amendment; validate the
  after agreement and link the source amendment, event date and effective date.
- Apply an unrelated trade lifecycle event and assert governing agreements and inputs to legal
  elections survive unchanged.
- Exercise one supported CSA terms change and one unsupported master-agreement change. The
  latter must be refused or clearly emitted as an extension, never silently approximated.
- Assert extension identifiers cannot be mistaken for CDM enum members and every extension
  carries owner, version, source taxonomy, licence and mapping version.

### Documentation freshness

- Run the repository link checker over this file in CI, following redirects and failing
  definitive 404/410 responses.
- Require publisher, title, canonical URL, document/version date, status, retrieval date and
  access/licence for every durable external claim.
- Review legal forms, annexes and opinion coverage on a scheduled cadence. A reachable page is
  not evidence that the selected document or opinion remains applicable.
