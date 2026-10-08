# One-time Xcode Cloud setup

## Current status

Repository-side plans, native core/UI targets, shared scheme and `ci_scripts` hooks are implemented. Xcode Cloud has **not** been provisioned or connected from this environment. GitHub's Apple Silicon fallback remains active and required until the steps below are completed. No provider credentials, signing team or App Store record were invented.

## Connect once

1. In the current stable Xcode 26.6, open `PhotoVeil.xcodeproj`, select **PhotoVeil** scheme, select your existing Apple Developer team locally and verify the app's existing bundle ID (`com.maksym1503.veil`). Do not change bundle identity or commit your local DEVELOPMENT_TEAM edits. Ensure your App Store Connect account has a role permitted to manage Xcode Cloud and the matching app record exists; supply real legal/app details yourself if it does not.
2. Product → Xcode Cloud → Create Workflow. Select the real app record/team. Authorize the GitHub App to access **maksym1503/photo-veil**. Give only this repository access if possible. Xcode/App Store Connect must perform this initial registration; checking in a YAML file does not create Cloud workflows.
3. Confirm Cloud resolves the committed `PhotoVeil.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. The local ImageGeometry package comes from the same checkout. Do not inject another package-resolution/build step.
4. Use managed signing for archive actions with the selected team. Cloud supplies its team context; verify the first archive log. If your account's project setup needs an explicit team assignment, make it only in the Cloud checkout via owner-controlled CI settings, not by overwriting/committing the local signing edits. Never upload a personal signing key to the repository.

## Create these workflows

| Workflow | Start / branch | Actions / plan | Required To Pass | Destination / parallelism |
|---|---|---|---|---|
| **Veil PR** | Pull Request Changes targeting `main`; all source branches, including `feature/veil-v4`; cancel obsolete PR builds | Test: PhotoVeil scheme, **VeilPR** only | Test **Required To Pass** | iPhone 17 Pro, iOS 26.5 (or exact available stable equivalent); core parallel enabled, PR UI serial as plan specifies |
| **Veil Apple Integration** | Branch Changes on `main`; daily scheduled build at 02:30 UTC on `main`; manual any candidate SHA | Test: **VeilIntegration**; Build: Release iOS | Both **Required To Pass** within this workflow; not a required PR status | modern iPhone iOS 26.5; add smaller iPhone/oldest supported available OS as additional scheduled destinations after pilot; legacy UI serial |
| **Veil Release Candidate** | Manual only, exact reviewed release branch/tag/SHA; no automatic PR start | Test: **VeilPR** and **VeilIntegration** (separate Test actions); Analyze; Archive Release | All actions **Required To Pass** | same validated stable simulator; Archive any iOS device / real app team |

Disable automatic test retries/repetitions in Cloud; the plans specify no retries and one execution. Verify the first native report has no retry attempts.

Do not mark failing integration actions **Not Required To Pass** to create a green release. Optional exploratory beta-OS destinations may be **Not Required To Pass**, clearly named and outside release acceptance. Xcode Cloud controls worker allocation; enable test parallelization for the native core target, retain serial UI target settings. Do not configure multiple workers for the shared-state legacy UI class. Start with one integration destination, not a multiplied 35-test device matrix.

Set all production workflows to **Xcode 26.6 stable and compatible macOS 26** initially, not automatically “latest beta.” If unavailable in your Cloud account, choose the nearest stable supported pair, record the exact versions and rerun both plans before switching. Align fallback/local versions when upgrading. The deployment target remains iOS 17; latest-Simulator testing does not replace oldest-supported-device acceptance.

Cloud runs its own build-for-testing/test scheduling and retains native xcresult/logs. The post-clone hook enforces inventory/security guardrails; post-xcodebuild prints result summaries even on failure. Do not run `scripts/ci/run_apple.sh` inside a Cloud Test action (that would duplicate builds).

The macOS AppKit performance profile is `VEIL_RUN_DETECTION_BENCHMARK=1 swift test --filter DetectionBenchmarkTests`. The post-xcodebuild hook runs it after the successful **Release Build action** in the exactly named **Veil Apple Integration** workflow, checks Release fixture exclusion and prints both measurement JSON files into retained Cloud logs. Configure that Build action for Release/generic iOS so the checked output path exists. Native Test actions cover the iOS plan; the hook supplies the two macOS-only profiles without recursively running another xcodebuild. Confirm these two methods actually executed (not skipped) in the first Cloud pilot. The GitHub fallback Integration workflow runs the same profile and retains JSON artifacts.

## TestFlight path

In **Veil Release Candidate**, first use Archive without distribution to validate managed signing. Only after exact-SHA Integration and physical acceptance are recorded, configure the post-action for **internal TestFlight** with the correct existing app record and internal tester group. Keep external TestFlight and App Store submission manual. Resolve export compliance, privacy/account disclosures and app metadata with real owner information before distributing. Native Cloud build-number management should produce a unique CFBundleVersion; confirm it on the first archive rather than modifying the marketing version here.

## Environment / secrets

PR and Integration require **no Supabase, Apple OAuth, Google, BrowserStack or production secrets**. Local editor mode and mocked auth/core boundary tests remain independent. For later real-provider tests use dedicated test tenants and Cloud secret environment variables restricted to that workflow; never expose them to fork PRs or write them into fixture builds. No auth/backend setup changes are required by this migration. `CI_PRIMARY_REPOSITORY_PATH`, `CI_RESULT_BUNDLE_PATH` and Apple-provided signing context are service variables, not hand-written secrets.

## Move branch protection without a gap

1. Manually run Veil PR and Integration against this branch. Confirm 52 PR tests and 85 integration tests, native evidence and expected status names in GitHub. Do not rely on a workflow name guessed here: copy the actual successful Cloud status context from PR checks.
2. In GitHub Settings → Rules/Branches for `main`, require **repository-security**, **backend-policy-and-deletion-tests**, and the observed **Veil PR Xcode Cloud** status. Keep the current **apple-pr-gate** fallback required until Cloud has succeeded on the current PR SHA. Require up-to-date branches; do not bypass checks for an administrator.
3. Remove only the fallback `apple-pr-gate` requirement after the Cloud requirement is active. Then set repository Actions variable **APPLE_CI_PROVIDER=xcode-cloud**. This disables both GitHub Apple fallback jobs; Ubuntu checks remain active. Never reverse this order (a skipped job is not Apple validation).
4. To roll back, clear that variable, run the fallback, require its successful status, then remove the Cloud requirement if necessary. Keep at least one real Apple gate required throughout.
5. Review Cloud usage, queue time, runtime and artifact privacy after the first week. Confirm scheduled main integration failures notify the owner through existing GitHub/Cloud notifications; no bot messaging credentials are needed.

Sources: [initial setup](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow), [workflow actions and Required To Pass](https://developer.apple.com/documentation/xcode/configuring-your-xcode-cloud-workflow-s-actions), [custom hooks](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts), [service environment variables](https://developer.apple.com/documentation/xcode/environment-variable-reference).
