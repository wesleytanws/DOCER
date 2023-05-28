This folder contains the manual annotation data for the paper `Detecting Outdated Code Element References in Software Repository Documentation`. The first 50 rows were annotated by all three authors to measure the inter-rater agreement, with the rest annotated by the first author. Each code element reference was annotated according to the coding guide below. We submitted GitHub issues to projects that contained at least one reference found to be outdated and have had commits within the past year (as of December 2021). The links to the issues submitted are listed below.

### Coding guide

| is_outdated | reason                      |
|-------------|-----------------------------|
| N           | Source and doc are the same |
| N           | Common word                 |
| N           | URL or URL alt text         |
| N           | Source is a doc             |
| N           | Source code comment         |
| Y           | Code element deleted        |
| Y           | File deleted                |

### Issues submitted

| repo_name                      | status                                                                       | issue_link                                                 |
|--------------------------------|------------------------------------------------------------------------------|------------------------------------------------------------|
| google_cctz                    | updated recently                                                             | https://github.com/google/cctz/issues/210                  |
| google_clif                    | updated recently                                                             | https://github.com/google/clif/issues/52                   |
| google_fruit                   | updated recently                                                             | https://github.com/google/fruit/issues/137                 |
| google_glog                    | updated recently                                                             | https://github.com/google/glog/issues/750                  |
| google_gnostic                 | updated recently                                                             | https://github.com/google/gnostic/issues/273               |
| google_ground-android          | updated recently                                                             | https://github.com/google/ground-android/issues/1094       |
| google_ko                      | updated recently                                                             | https://github.com/google/ko/issues/523                    |
| google_megalista               | updated recently                                                             | https://github.com/google/megalista/issues/51              |
| google_mug                     | updated recently                                                             | https://github.com/google/mug/issues/25                    |
| google_hs-portray              | updated a month ago                                                          | https://github.com/google/hs-portray/issues/7              |
| google_caliper                 | updated 2 months ago                                                         | https://github.com/google/caliper/issues/459               |
| google_stijl                   | updated 3 months ago                                                         | https://github.com/google/stijl/issues/37                  |
| google_openrtb-doubleclick     | updated 5 months ago                                                         | https://github.com/google/openrtb-doubleclick/issues/160   |
| google_googlesource-auth-tools | updated 9 months ago                                                         | https://github.com/google/googlesource-auth-tools/issues/4 |
| google_hypebot                 | updated 11 months ago                                                        | https://github.com/google/hypebot/issues/23                |
| google_EXEgesis                | updated a year ago                                                           |                                                            |
| google_openrtb                 | updated a year ago                                                           |                                                            |
| google_embedding-tests         | updated 2 years ago                                                          |                                                            |
| google_gdata-objectivec-client | updated 3 years ago                                                          |                                                            |
| google_horenso                 | updated 3 years ago                                                          |                                                            |
| google_MOE                     | updated 3 years ago                                                          |                                                            |
| google_agera                   | updated 4 years ago                                                          |                                                            |
| google_depan                   | updated 4 years ago                                                          |                                                            |
| google_dimsum                  | updated 4 years ago                                                          |                                                            |
| google_ioweb2016               | updated 5 years ago                                                          |                                                            |
| google_traceur-compiler        | updated 5 years ago                                                          |                                                            |
| google_qpp                     | updated 8 years ago                                                          |                                                            |
| google_clicktrackers-panel     | project did not enable 'Issues'                                              |                                                            |
| google_pytruth                 | project did not enable 'Issues'                                              |                                                            |
| google_codeu_project_2017      | project archived by the owner                                                |                                                            |
| google_eme_logger              | outdated reference resolved after detection                                  |                                                            |
| google_keyczar                 | project skipped: "Keyczar is deprecated"                                     |                                                            |
| google_pack-n-play             | deleted JavaScript built-in function: console.log(result)                    |                                                            |
| google_textfsm                 | deleted Python built-in function: .read()                                    |                                                            |
| google_web-starter-kit         | captured JSDoc @return in documentation, matched SCSS @return in source code |                                                            |
