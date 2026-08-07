# Getting started with CDM

Use this reference when a project does not yet consume CDM, when its CDM distribution is
unclear, or when choosing a language or integration path. Do not add a dependency until the
task and required capability are known.

## Contents

- [Choose an entry point](#choose-an-entry-point)
- [Use precise terminology](#use-precise-terminology)
- [Resolve a version](#resolve-a-version)
- [Java and JVM applications](#java-and-jvm-applications)
- [Python applications](#python-applications)
- [TypeScript, JSON Schema, and Excel](#typescript-json-schema-and-excel)
- [Other language generators](#other-language-generators)
- [Model authors and contributors](#model-authors-and-contributors)
- [Prove the installation](#prove-the-installation)

## Choose an entry point

| Goal | Start here |
|---|---|
| Learn the model without integrating it | Read the [FINOS CDM documentation](https://cdm.finos.org/docs/common-domain-model/) or take the free [introductory course](https://training.linuxfoundation.org/training/introduction-to-the-common-domain-model-cdm-lfel1016/). |
| Execute the complete reference implementation | Use the Java `cdm-java` distribution from [Maven Central](https://central.sonatype.com/artifact/org.finos.cdm/cdm-java). |
| Build a native Python application | Use [`finos-cdm` on PyPI](https://pypi.org/project/finos-cdm/) and account for its native-function limitations. |
| Consume CDM data shapes in TypeScript | Download the versioned [`cdm-typescript` artifact](https://central.sonatype.com/artifact/org.finos.cdm/cdm-typescript). |
| Validate or exchange structural JSON | Download the versioned [`cdm-json-schema` artifact](https://central.sonatype.com/artifact/org.finos.cdm/cdm-json-schema). |
| Browse types, attributes, and enums in a workbook | Download the versioned [`cdm-excel` artifact](https://central.sonatype.com/artifact/org.finos.cdm/cdm-excel). |
| Inspect or change the model itself | Use the matching tag in the [FINOS CDM repository](https://github.com/finos/common-domain-model) and its Rune source. |

Treat these as different capability levels. A generated type distribution or schema is not an
executable lifecycle implementation.

## Use precise terminology

- **CDM** is the model and its versioned distributions, hosted by FINOS.
- **Rune DSL** is the current name of the language in which CDM is defined. Its source files
  retain the `.rosetta` extension; older documentation may call the language Rosetta DSL.
- **Rosetta Design** is optional REGnosys tooling for editing and contributing Rune models. It
  is not required to consume a released CDM distribution. See [Rosetta Design](https://rosetta-technology.io/design)
  and the open-source [Rune DSL](https://github.com/finos/rune-dsl).
- **ISDA, ISLA, and ICMA** provide market-domain guidance. They do not supersede the active
  version's Rune declarations or executable behavior.

## Resolve a version

1. For an existing application, read its build declaration and lock or resolution output. Use
   the version it actually resolves, not the version mentioned in prose or a nearby repository.
2. For a new application, select a production release from [FINOS CDM releases](https://github.com/finos/common-domain-model/releases).
   A release labelled `-dev` is not the current production version merely because GitHub or an
   artifact registry lists it as latest.
3. Pin an exact version. Do not copy `LATEST` from documentation examples.
4. Keep the generated distribution, Rune source, fixtures, and reference outputs on the same
   version. Re-run model and runtime probes when upgrading.

Release notes and the language's package registry take precedence over an older download page.
Official pages can lag during a distribution migration, so record the URL and retrieval date
when the acquisition route matters to a durable decision.

## Java and JVM applications

Use the Maven coordinates `org.finos.cdm:cdm-java:<version>`. For Maven:

```xml
<dependency>
  <groupId>org.finos.cdm</groupId>
  <artifactId>cdm-java</artifactId>
  <version>${cdm.version}</version>
</dependency>
```

For Gradle:

```kotlin
implementation("org.finos.cdm:cdm-java:<version>")
```

Read the version-matched [Java distribution guidance](https://cdm.finos.org/docs/cdm-java-distribution/)
and the examples in the [FINOS repository](https://github.com/finos/common-domain-model/tree/master/examples).

Gotchas:

- Java is the complete reference executable distribution, including manually implemented
  defaults that are not necessarily present in another generated language.
- Generated model objects use generated builders. Functions, validators, qualifiers, and
  post-processors may require dependency injection; use the project's runtime wiring or the
  supplied `CdmRuntimeModule` instead of constructing injected functions blindly.
- The Java level required to consume a release can differ from the JDK required to build that
  release's source repository. Check the selected artifact and tag rather than assuming they
  are the same.
- Resolve the exact JAR before using `scripts/cdm-source`; refuse multiple candidate versions.

Kotlin applications can normally consume `cdm-java` directly on the JVM. Do not choose a
separate Kotlin generator unless native generated Kotlin is an explicit requirement.

## Python applications

Use Python 3.11 or later when required by the selected package metadata, create an isolated
environment using the project's normal tooling, and pin the matching CDM version:

```bash
python -m pip install "finos-cdm==<version>"
```

The distribution provides Pydantic v2 model classes, Rune-defined conditions and functions,
Rune JSON serialization, and reference resolution. Its package version follows the CDM release
version.

Gotchas:

- PyPI coverage begins in the 5.x line and covers only recent maintenance releases per major
  version; for earlier CDM versions, download the matching `org.finos.cdm:cdm-python`
  `.tar.gz` from Maven Central and install it directly.
- Functions implemented natively in Java are represented by Python stubs and raise
  `NotImplementedError` unless an application registers a Python replacement.
- Runtime code-list loading is one such native gap; applications that require it must supply an
  implementation. Read the current [package support statement](https://pypi.org/project/finos-cdm/)
  before promising behavioral parity with Java.
- Do not assume the Python wheel embeds `.rosetta` inputs. When exact model intent is required,
  use Rune source from the matching FINOS tag or the matching `cdm-java` artifact as a source
  container without making Java part of the application architecture.
- Inspect generated Pydantic fields and Python function signatures. Do not translate a recalled
  Java builder API into Python by analogy.

## TypeScript, JSON Schema, and Excel

FINOS publishes all three as versioned artifacts for current releases; follow the links in
[Choose an entry point](#choose-an-entry-point) or the
[FINOS download page](https://cdm.finos.org/docs/download/). Note that the JSON Schema and
Excel artifacts do not exist for the oldest supported lines (both start in the 5.x era), so
on older versions derive schemas or workbooks from the Rune source or `cdm-java` artifact
instead.

- TypeScript contains the generated data model but not the complete executable function set.
  Treat it as generated source, not as an npm runtime unless a particular release explicitly
  introduces one.
- JSON Schema describes structural JSON shapes. It does not execute Rune conditions, lifecycle
  functions, qualification, reference resolution, or application policy.
- Excel is an inspection aid containing types, attributes, and enums. It is not a serialization
  or validation authority.

When an application needs executable behavior, either use a supported runtime behind a service
boundary or implement and test the missing behavior explicitly. Do not present structural
validation as CDM conformance.

## Other language generators

The open-source [Rosetta code-generator repository](https://github.com/REGnosys/rosetta-code-generators)
contains community generators for C#, DAML, Go, Kotlin, Scala, and TypeScript; the default
Java generator is built into the [Rune DSL repository](https://github.com/finos/rune-dsl)
itself, not this repo.

A generator's presence does not establish that its current output is a complete, released, or
behaviorally equivalent CDM runtime. Before adopting one, verify:

1. compatibility with the selected Rune/CDM version;
2. generated coverage for types, functions, conditions, metadata, and serialization;
3. treatment of Java-native default implementations;
4. release packaging and maintenance status; and
5. positive and negative conformance tests against the Java reference behavior where parity is
   required.

## Model authors and contributors

Clone the [FINOS CDM repository](https://github.com/finos/common-domain-model), select the intended
tag or development branch, and follow that version's contribution and development guidance.
Use the source repository for upstream model changes, not generated Java or Python files.

Rosetta Design can create a CDM workspace and submit a pull request without a local model-build
environment. A local workflow can edit `.rosetta` files directly with the available Rune/Rosetta
editor tooling. In either route, begin with a FINOS issue, include model tests and documentation,
and satisfy the project's contributor-license requirements.

## Prove the installation

Before changing application behavior, record:

```text
CDM version:
Distribution and package coordinates:
Capability level (complete runtime, partial runtime, types, or schema):
Rune source used for model claims:
JSON dialect and document root:
Focused smoke test:
```

Use the smallest smoke test appropriate to the distribution:

- Java: compile a generated builder, serialize a populated object, run validation through the
  application's runtime wiring, and assert meaningful output.
- Python: import a generated type, construct and Rune-round-trip a populated object, validate
  it, and call a Rune-defined function; test native-function replacements separately.
- TypeScript: type-check a representative populated object and verify its emitted JSON shape.
- JSON Schema: validate both a representative positive document and a close invalid document.

A successful import or empty-object validation is not sufficient. Confirm that a meaningful
economic field survives construction and serialization, then keep the smoke test if the
integration depends on it.
