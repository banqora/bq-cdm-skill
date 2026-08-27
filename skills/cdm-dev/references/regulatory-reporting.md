# Regulatory reporting with CDM and ISDA DRR

Use this reference when an implementation creates reportable events, evaluates reporting rules,
projects reports into submission formats, or upgrades ISDA Digital Regulatory Reporting (DRR).
Treat it as an engineering guide, not legal advice. Have the appropriate legal or compliance
owner approve the applicable obligation, interpretation, effective date, and firm policy.

## Contents

- [Keep the layers separate](#keep-the-layers-separate)
- [Pin the complete compatibility stack](#pin-the-complete-compatibility-stack)
- [Query the selected source and runtime](#query-the-selected-source-and-runtime)
- [Implement an auditable reporting path](#implement-an-auditable-reporting-path)
- [Preserve decisions and lineage](#preserve-decisions-and-lineage)
- [Guard against high-risk traps](#guard-against-high-risk-traps)
- [Test reporting in layers](#test-reporting-in-layers)
- [Use current official evidence](#use-current-official-evidence)
- [Respect access and licence limits](#respect-access-and-licence-limits)

## Keep the layers separate

| Layer | What it establishes | What it does not establish |
|---|---|---|
| Primary law, rules, and regulator technical material | The legally applicable obligation, field definitions, deadlines, schemas, and validation rules for an effective period | That a particular DRR release implements every current requirement |
| Firm applicability policy | Entity and branch scope, capacity, exemptions, reporting side, delegation, jurisdiction, product/event scope, and approved interpretation | CDM validity or successful report generation |
| FINOS CDM | Standardised products, parties, trades, states, business events, workflow lineage, validation, and qualification | A reporting obligation, a reportable jurisdiction, or an accepted submission |
| ISDA DRR | A separately released CDM extension containing reporting types, enrichment interfaces, eligibility and reporting logic, output types, and projections | That every policy seam is implemented for the firm, or that every rule reference remains current |
| Projection and messaging | Transformation from a DRR report object to a regime or trade-repository message such as ISO 20022 XML | Transport acceptance, timeliness, or reconciliation |
| Submission operations | Scheduling, credentials, transport, acknowledgements, retries, corrections, reconciliation, and audit retention | The legal correctness of the upstream determination |

The [official DRR pipeline](https://drr-docs.isda.org/next/docs/using-drr/implement-drr/)
uses the stages Ingest, Enrich, Report, and Project. Preserve those boundaries even when an
application names its stages differently.

Do not equate these three decisions:

1. **Reportable-event determination** decides whether a CDM workflow or state becomes a DRR
   `ReportableEvent` and supplies jurisdictional reporting information.
2. **Eligibility or applicability** decides whether a particular report declaration applies to
   that event, regime, authority, party, product, and effective period.
3. **Report generation** evaluates field rules and creates a typed report output.

A generated report proves only that the selected code path returned an object. It does not prove
that the firm had an obligation, chose the right reporting side, met the deadline, projected the
right schema version, or received an acceptance from the destination.

## Pin the complete compatibility stack

**Never pair DRR and CDM by matching their version numbers. Never run DRR over an independently
chosen newer CDM object graph without compatibility proof.** DRR and CDM are released on separate
cadences, and the DRR parent POM declares the CDM and Rune versions against which it was built.

Record this tuple for every build, test result, defect, and durable report:

- DRR artifact coordinate, exact version, and checksum;
- CDM coordinate and version declared by that DRR release;
- Rune compiler/runtime and generated-code bundle versions;
- ISO 20022 model or projection artifact version, when used;
- jurisdiction, supervisory body, corpus/report name, regulator specification, and effective date;
- DRR Test Pack version or commit, application policy version, and retrieval date.

Do not use Maven `LATEST`, a floating development tag, or the repository metadata's `release`
element as a production selector. The `release` value can identify a development build and
`latest` can be empty. Enumerate strict `MAJOR.MINOR.PATCH` versions, then select an approved,
supported production release.

This reproduces the repository and parent-POM inspection:

```bash
DRR_METADATA_URL=https://europe-west1-maven.pkg.dev/production-208613/isda-maven/com/regnosys/drr/rosetta-source/maven-metadata.xml
DRR_REPOSITORY="${DRR_METADATA_URL%/com/regnosys/drr/rosetta-source/maven-metadata.xml}"
DRR_METADATA="$(mktemp)"
curl -fsSL "$DRR_METADATA_URL" -o "$DRR_METADATA"

DRR_VERSION="$(
python3 - "$DRR_METADATA" <<'PY'
import re
import sys
from xml.etree import ElementTree

root = ElementTree.parse(sys.argv[1]).getroot()
versions = [node.text for node in root.findall("./versioning/versions/version") if node.text]
stable = [version for version in versions if re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version)]
if not stable:
    raise SystemExit("no strict production version found")
print(max(stable, key=lambda value: tuple(map(int, value.split(".")))))
PY
)"

DRR_PARENT_POM="$(mktemp)"
curl -fsSL \
  "$DRR_REPOSITORY/com/regnosys/drr/$DRR_VERSION/drr-$DRR_VERSION.pom" \
  -o "$DRR_PARENT_POM"
rg -n 'finos.cdm.version|rosetta.dsl.version|rosetta.bundle.version|iso20022.version' \
  "$DRR_PARENT_POM"
```

The highest numerical release is not automatically the right production release. Check ISDA's
support status, the applicable regulatory effective date, the firm's approval, and the selected
Test Pack before changing a pin.

### Time-bounded compatibility observation

The following is evidence retrieved at **2026-08-07T10:15:46Z**, not a timeless recommendation:

- the [artifact metadata](https://europe-west1-maven.pkg.dev/production-208613/isda-maven/com/regnosys/drr/rosetta-source/maven-metadata.xml)
  had an empty `latest`, a `release` of `7.6.0`, a `lastUpdated` value of `20260807100354`, and
  `7.6.0` as the highest strict production version;
- the immutable [DRR 7.6.0 parent POM](https://europe-west1-maven.pkg.dev/production-208613/isda-maven/com/regnosys/drr/7.6.0/drr-7.6.0.pom)
  declared CDM `6.23.0`, Rune DSL `9.85.1`, the generated-code bundle `11.124.2`, and ISO 20022
  `1.42.0`;
- the DRR `7.6.0` `rosetta-source` JAR inspected for this reference had SHA-256
  `41007807101dada1e023697d31be3dd103bdb79ea87303a034b5d7e5ed42eb56`;
- the earlier DRR `7.0.0` parent declared CDM `6.21.0` and Rune DSL `9.83.0`, demonstrating that
  equal-looking DRR and CDM release numbers are not a compatibility contract.

An earlier metadata response in the same research session had pointed `release` at
`8.0.0-dev.12` and had `7.5.0` as its highest strict production version. The repository changed
during the research itself, which is why a retrieval timestamp and reproducible lookup matter.

Re-run the metadata and POM inspection on the retrieval date. Do not copy these versions into a
new build merely because they appear here.

Before executing DRR:

1. Run the consuming build's dependency report and identify the single resolved DRR, CDM, Rune,
   mapper, and Guice/runtime stack.
2. Inspect the DRR JAR for bundled `cdm/` classes as well as its declared CDM dependency. The
   inspected `7.6.0` artifact contained generated `drr/` and `cdm/` classes, so classpath order,
   dependency exclusions, and forced upgrades can silently select an incompatible class.
3. Fail the build on duplicate or unexpected CDM versions. Do not solve a dependency conflict by
   forcing the application's newer CDM version unless an explicit compatibility suite proves it.
4. Compile and execute a populated `ReportableEvent` through the selected injected functions,
   validation, serialization, and projection. A clean dependency tree without a runtime probe is
   insufficient.
5. If the application must use a newer CDM release, isolate the DRR-compatible graph or introduce
   an explicit, versioned translation boundary. Do not cast, share builders, or serialize blindly
   between the two graphs.

For a non-Java implementation, pin the generated DRR distribution and its source model to the
same release. Compare behavior with the release's Java reference implementation and Test Packs;
language parity is a claim to prove, not assume.

## Query the selected source and runtime

Read the `.rosetta` sources embedded in the exact DRR artifact. Do not infer current behavior from
documentation examples, a different release, or the existence of a generated class.

```bash
DRR_JAR=path/to/selected-drr.jar
DRR_SOURCE_DIR="$(mktemp -d)"
unzip -q "$DRR_JAR" -d "$DRR_SOURCE_DIR"

rg -n '^namespace |^version "' "$DRR_SOURCE_DIR/drr/rosetta"
rg -n '^type (ReportableEvent|ReportableInformation|ReportableJurisdictionInformation|TransactionReportInstruction)( extends [^:]+)?:' \
  "$DRR_SOURCE_DIR/drr/rosetta"
rg -n '^report |^eligibility rule |^reporting rule ' "$DRR_SOURCE_DIR/drr/rosetta"
rg -n '\[codeImplementation\]|filter True|Demonstrative eligibility|TODO|unsupported|add text here' \
  "$DRR_SOURCE_DIR/drr/rosetta"
rg -n 'docReference|ruleReference' "$DRR_SOURCE_DIR/drr/rosetta"
```

Locate before opening because names and paths can change. Useful source areas usually include:

- common reporting types for `ReportableEvent`, `ReportableInformation`, jurisdiction information,
  reporting sides, and transaction/collateral/valuation instructions;
- common trade enrichment for reportable-event creation and external enrichment seams;
- the selected authority's `report` declarations, eligibility rules, output types, conditions,
  and reporting rules;
- ingest functions and synonyms for the selected input format;
- projection functions and the exact output schema model;
- the embedded CDM workflow, event, trade-state, and qualification declarations on which DRR
  depends.

For every intended report, follow the whole graph:

1. the `report` input type, `when` rule, timing annotation, and output type;
2. every eligibility-rule extraction, filter, alias, and helper function;
3. every output field's reporting rule, `ruleReference`, cardinality, and output condition;
4. `ReportableInformation`, regime and supervisory-body enrichment, reporting-side selection,
   and delegated-reporting data;
5. any `[codeImplementation]`, external API, reference data, or application-supplied function;
6. projection rules, schema artifact, serializer, and destination validation rules.

Then inspect the generated interface and default implementation and execute a focused injected
probe. Confirm that the generated behavior matches the Rune declaration, especially for literal
booleans, empty results, cardinality, output conditions, and native function replacements.

### Time-bounded policy-seam observation

In the exact DRR `7.6.0` artifact inspected at **2026-08-07T10:15:46Z**:

- `Create_ReportableEvents` called `PreEnrich`, filtered trade states through `IsEligible`, and
  constructed `ReportableEvent` values using `PostEnrich`;
- `IsEligible` returned literal `True`, `PreEnrich` was an identity function, and `PostEnrich` was
  marked `[codeImplementation]` for custom jurisdictional/reporting enrichment;
- the CFTC Part 43 and Part 45 reports used `IsReportableEvent`, whose filter was literal
  `True` and whose own source note said regulator applicability was not filtered;
- at least one CFTC document provision contained placeholder text, and several margin, valuation,
  or control eligibility declarations called themselves demonstrative;
- report namespaces existed for multiple regimes, while TODOs and unsupported paths remained.

These observations identify integration and test obligations; they are not assertions about a
later release. Repeat the searches above, read the active rules in context, and record which gaps
the application or vendor owns. Namespace or class presence alone is not proof of complete,
current, production-ready coverage.

## Implement an auditable reporting path

1. Create an obligation matrix approved by legal or compliance. Include regime, authority,
   entity and branch, capacity, reporting side, delegation, product, venue, event/action, report
   type, exemptions, effective period, deadline, destination, and message/schema version.
2. Pin the compatible DRR/CDM/Rune/ISO stack and matching Test Pack. Capture checksums and the
   resolved dependency graph in build evidence.
3. Map source data into the expected CDM root. Reject unknown enum values, units, roles, and
   jurisdictions rather than guessing. Record missing, skipped, defaulted, transformed, and
   residual fields separately.
4. Build and validate the CDM `WorkflowStep`, `BusinessEvent`, `TradeState`, parties, identifiers,
   and previous-step lineage. Qualification describes product or event shape; it does not decide
   reportability.
5. Enrich a DRR `ReportableEvent` with versioned jurisdiction, entity, branch, counterparty,
   reporting-role, venue, identifier, and reference data. Distinguish facts supplied by a source
   from policy-derived values.
6. Evaluate and persist firm applicability and the DRR report eligibility rule as separate
   outcomes, including negative decisions and reason codes.
7. Create the correct instruction and reporting side, execute the intended report function,
   validate the typed output, and explain every missing or suppressed field.
8. Project to the exact regulator or repository message version. Validate the schema and current
   authority or repository rules; do not treat a DRR JSON object as a submission message. The
   projection seam is where reported values change convention, so apply the
   [wire-schema projection card](implementation-patterns.md#pat-006-project-model-values-onto-an-external-wire-schema):
   quote each side's declared basis, unit, and lexical facets from its own authority, keep
   absence, zero, and empty distinct, and prove the seam with round-trip and over-facet probes.
9. Schedule, submit, reconcile, correct, and retain acknowledgements under application policy.
   Make retries idempotent and preserve the relationship among original, corrected, cancelled,
   and resubmitted reports.

Keep reporting jurisdiction separate from governing law, agreement type, booking location, and
counterparty domicile. Any of those may be an input to approved applicability policy, but none is
a safe substitute for it.

## Preserve decisions and lineage

Persist enough evidence to reproduce both a positive report and a decision not to report:

- immutable input identifier, hash, source-system version, business timestamp, and ingestion
  timestamp;
- CDM root identifier, event/action, before/after state, previous workflow step, qualifications,
  validation findings, and serialization dialect;
- regime, authority, report/corpus, effective date, entity/branch, reporting party, counterparty,
  delegation, and approved policy version;
- DRR/CDM/Rune/ISO versions and checksums, function or rule names, Test Pack version, and build
  identifier;
- per output field: source path, mapping, transform, enrichment source and as-of time, reporting
  rule, default status, omission reason, and validation result;
- applicability result, eligibility result, generated-report result, projection/schema result,
  destination submission identifier, acknowledgement, rejection reason, and correction lineage.

Do not collapse `missing`, `not applicable`, `false`, `zero`, `blank`, `defaulted`, `failed
transformation`, and `intentionally suppressed` into one empty value. Their regulatory and audit
meanings differ.

Use stable event and report identifiers across retries. Link corrections and cancellations to the
previous accepted report and the CDM workflow history; a child state can validate while its
transition or reporting history is still wrong.

## Guard against high-risk traps

- **Version lockstep:** equal DRR and CDM numbers do not imply compatibility. Inspect the parent
  POM and resolved classes every time.
- **Validation overreach:** CDM validity and qualification do not prove reportability, legal
  applicability, reporting-side correctness, or economic correctness.
- **Policy hidden as mapping:** do not silently infer a regime, authority, party role, exemption,
  or default. Label application policy and obtain approval.
- **Party reversal:** swapping reporting party and counterparty can still produce structurally
  valid, plausible output. Use asymmetric fixtures and assert role-dependent fields.
- **Non-executable timing:** DRR documents that a report declaration's `T+1` timing is syntactic
  information only. Implement calendars, cut-offs, time zones, holidays, and scheduling outside
  the generated report function.
- **Coverage by filename:** a regime, asset-class, or report class existing does not show that all
  events, fields, eligibility branches, projections, or effective periods are supported.
- **Output-format confusion:** a typed DRR report, JSON serialization, ISO 20022 projection, trade
  repository message, and acknowledgement are different artifacts with separate validation.
- **Reference-data time travel:** identifiers, classifications, MICs, LEIs, UPI data, and entity
  status can change. Store source, version, and as-of time and make replay deterministic.
- **Stale legal references:** a Rune `docReference` records the interpretation encoded in that
  artifact; it does not establish that the cited rule or technical specification remains current.
- **Ingest optimism:** an FpML or proprietary mapping can be partial or lossy. Inspect typed CDM
  output, residual input, canonical serialization, and the exact economic leaves before reporting.
- **Happy-path conformance:** a matching positive sample can coexist with over-broad eligibility.
  Require close negative controls and mutation tests.

## Test reporting in layers

| Test layer | Minimum proof |
|---|---|
| Version contract | Resolve the approved DRR artifact, assert its declared CDM/Rune/ISO tuple and checksums, reject duplicate or forced CDM classes, and run a populated compatibility probe |
| Mapping | Assert required source values survived into typed CDM/DRR fields; report residual, missing, skipped, defaulted, and failed fields; reject unknown roles and jurisdictions |
| CDM model | Run generated validators and expected product/event qualifiers with a close negative case; assert the exact economic leaf, unit, and convention |
| Applicability policy | Pair the same economics with in-scope and out-of-scope entities, branches, jurisdictions, venues, products, events, exemptions, reporting sides, and effective dates |
| DRR eligibility | Execute each selected report's actual `when` rule; mutation-test fields that should change the decision and detect literal or demonstrative fallbacks |
| Reporting rules | Assert populated values, deliberate omissions, cardinality, output conditions, rule lineage, and both reporting-side orientations |
| Conformance | Run the exact release's official DRR Test Packs by regime, report, asset class, and event; require non-empty discovery, input, expected output, and executed-case counts |
| Projection | Compare canonical output, validate the exact schema and current authority/repository rules, and test invalid or missing mandatory fields |
| Lifecycle | Cover new, modify, correct, cancel, terminate, reopen, valuation, and collateral paths that are in scope; assert previous-report and workflow lineage |
| Operations | Test calendar deadlines, duplicate delivery, retry idempotency, rejection, acknowledgement, reconciliation, and corrected resubmission |
| Upgrade | Diff dependencies, report declarations, eligibility rules, code implementations, TODOs, rule references, output types, projections, schemas, and Test Packs before approval |

Use Test Packs to prove conformance to a named DRR release, not legal completeness. The
[DRR implementation guidance](https://drr-docs.isda.org/next/docs/using-drr/implement-drr/)
describes comparing firm output with expected Test Pack output. Add firm-owned tests for
applicability, mappings, reference data, deadlines, destination behavior, and known policy seams.

For every supported asset-class/regime/report combination, keep at least one meaningful positive
case and one close negative case. Use asymmetric parties, realistic identifiers, non-default
economics, and assertions below the document root. Add count floors so an empty scenario discovery
or skipped parameter set cannot make the suite green.

## Use current official evidence

Apply this evidence order for each implementation or upgrade:

1. Start with the current regulator or statutory landing page and select the material applicable
   to the report's effective date. Record publication, update, and retrieval dates.
2. Use the [ISDA DRR InfoHub](https://www.isda.org/isda-solutions-infohub/isda-digital-regulatory-reporting/)
   for programme, coverage, and adoption context.
3. Use the current [DRR introduction](https://drr-docs.isda.org/next/docs/introduction/),
   [DRR and CDM boundary](https://drr-docs.isda.org/next/docs/get-started/drr-and-cdm/),
   [scope and report declarations](https://drr-docs.isda.org/next/docs/using-drr/scope-and-structure/),
   and [versioning policy](https://drr-docs.isda.org/next/docs/governance/versioning/)
   for architecture and release semantics. Record the version shown by the documentation site;
   its examples can lag the artifact repository.
4. Use the exact selected DRR artifact, embedded Rune source, generated implementation, parent
   POM, and matching Test Packs for executable behavior.
5. Use the [FINOS CDM repository](https://github.com/finos/common-domain-model) and
   [FINOS Rune DSL repository](https://github.com/finos/rune-dsl) for their respective source and
   language contracts, always at versions compatible with the DRR release.
6. Compare every embedded `docReference` and schema claim with current primary authority material.
   Log discrepancies instead of silently modernising the generated rule.

Examples of current primary authority landing pages include the
[CFTC Parts 43/45 rulemaking and technical specifications](https://www.cftc.gov/LawRegulation/DoddFrankAct/Rulemakings/DF_17_Recordkeeping/index.htm),
the [ESMA EMIR reporting page](https://www.esma.europa.eu/data-reporting/emir-reporting), and the
[LEI ROC Global LEI System and harmonised data guidance index](https://www.leiroc.org/leiroc_gls/index.htm).
On 2026-08-07, the LEI ROC index listed Revised CDE Technical Guidance Version 4 dated December
2025; this illustrates why an older CDE namespace or embedded document reference must not be
treated as current merely because the code executes.

If official sources disagree, do not decide the legal interpretation in code review. Record the
conflict, effective dates, and affected reports; obtain an approved interpretation; version the
resulting policy and tests.

## Respect access and licence limits

DRR has a separate [ISDA DRR licence](https://www.isda.org/2023/09/19/isda-digital-regulatory-reporting-drr-license/).
Review it before copying, modifying, distributing, hosting, or building a searchable corpus from
DRR model source, documentation, or Test Packs. Do not assume that DRR inherits the licence of
FINOS CDM or Rune merely because it extends and uses them.

Publicly reachable does not mean freely redistributable. Link to official material by default.
Do not scrape, vendor, embed, or redistribute regulator documents, licensed DRR content, member
material, or derived vector indexes unless the applicable terms permit that use. Preserve
attribution and licence notices, restrict access where required, and ask the user for an authorised
copy when a source is access-controlled.
