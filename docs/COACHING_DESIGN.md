# Coaching implementation

The Coach tab uses a shared deterministic plan engine, not a live language model. Selected passages from all six user-supplied ISSA PDFs were reviewed. Titles and PDF page numbers appear in the Sources view and exported documents. `coaching-source-manifest.json` records the exact inputs. The private study build now bundles extracted text from all six textbooks for local source retrieval; original PDF files and diagrams are not bundled.

## Source mapping

- Sports Nutrition, PDF 409–410 and 562: individual energy estimation and review of observed outcomes.
- Strength and Conditioning, PDF 47–51: FITT and individual progression.
- Bodybuilding, PDF 188–189: recovery, training volume and experience.
- Transformation Specialist, PDF 14 and 20–21: confidence, client choice and supportive behavior change.
- Corrective Exercise, PDF 103–104 and 121–122: symptoms, referral and appropriate movement challenges.
- Exercise Therapy, PDF 35–36: individual limitations and contextual assessment.

The source pages inform principles, not the exact software thresholds. General activity guidance was cross-checked against CDC Adult Activity Overview and energy-estimate limitations against NIDDK Body Weight Planner on September 11, 2026.

## Runtime behavior

Assessment, diet preference and selected goal persist under the authenticated user's existing profile document. The plan screen listens to body profile, goal, preference and previous-seven-day workout streams. Only distinct days logged as Strength count toward consistency; logs are not treated as performance measurements. A fresh recovered check-in and sufficient logged strength days permit three sets. Tiredness reduces sets; missing or stale check-ins hold starting workload. No automatic weight increase occurs. A linked completed fitness goal selects maintenance. An unlinked or nonfitness goal has no effect.

Weight trends require at least three distinct days in each of two adjacent seven-day windows. Trend observations do not automatically cut calories. Body profile changes recalculate existing nutrition formulas. Pain or condition-specific requirements pause personalized prescriptions and produce an assessment export.

Meals provide portion weights, approximate 4/4/9 macro energy totals, explicit macro-target differences and shopping totals. Food values are illustrative rounded app estimates, not USDA-verified or product-specific measurements. Filters cover only the catalog's tagged ingredient groups and do not guarantee allergy safety. Raw/cooked weights are stated. Meal generation does not claim exact macro matching or medical nutrition therapy.

Chat reloads the same context for each response/export. Word uses a real OOXML ZIP package; PDF and Word consume the same plan text, including references. Generated schedules are not recorded as completed activity or consumed meals.

## Validation

Unit tests cover goal transitions, recovery, equipment, exclusions, energy consistency, sparse/duplicate/stale weight measurements and exports. Widget tests cover narrow and wide plan layouts. Firebase-dependent integration tests require the emulator suite separately.

## Measurement preferences

Profile > Measurement units supports independent kg/lb, cm/feet-and-inches, g/oz and kcal/kJ preferences, plus metric/imperial presets. Save Profile persists choices in the body-profile document. Older profiles default to metric. Body measurements, weight history and food logs retain canonical kg, cm, g and kcal values; formatting and entry conversion happen at the UI boundaries. Untouched profile fields preserve their exact canonical values when switching display units. BMI, energy formulas and planned food quantities are independent of the chosen display system. Weight charts, profile summaries, dashboard, meal input, coaching responses and Word/PDF exports use the preferences. Time and percentages are unchanged.


## Full-text library upgrade (2026-09-15)

`tools/import_issa.py` verifies each supplied PDF against its SHA-256 in the
source manifest and extracts every page with Poppler. The generated private asset
contains 2,451 PDF pages (2,450 with text), preserving empty-page positions.
`issa-library-coverage.json` records per-book coverage. Extraction is not a claim
of human review of every passage, OCR, or diagram interpretation.

`IssaLibrary` lazily builds a local inverted index. Ranking uses term frequency,
page length, and term rarity; all meaningful query words must occur on a page.
Search supports course filters and bounded excerpts. The reader shows surrounding
page text and supports previous/next and page-number navigation. No source text
or questions are sent to an AI provider. Loading failures are retryable.

Chat retains the shared assessment-based plan engine. Medical/referral and
supplement responses take precedence over retrieval. Retrieved passages are
explicitly labeled source excerpts and open the exact page in the reader; they
are not synthesized into new medical or exercise prescriptions. General source
questions can be answered without a body profile. The same plan date is used
for today's meals and workout. Invalid profiles return setup guidance.

The coaching home has a current-session preview, weekly habit, equipment, time
budget, recovery freshness, and direct library access even before profile setup.
Existing unit preferences, persistence, meals, review gating and exports remain.

The full-text asset is intentionally ignored by Git. A fresh checkout must run
the importer before tests/builds. Local binaries include supplied textbook text
and are private study artifacts; public redistribution requires source rights.
