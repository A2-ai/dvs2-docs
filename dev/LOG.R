mkdir("demo_dvs2_rpkg")
setwd("demo_dvs2_rpkg")
usethis::create_project(".")

system2("rv", "init")
rv project successfully initialized at .

# Session -> Restart R

rv repositories active!
  repositories:
  PRISM: https://prism.a2-ai.cloud/rpkgs/nimbus/2025.08

rv libpaths active!
  library paths:
  /data/user-homes/mossa/demo_dvs2_rpkg/rv/library/4.5/x86_64/noble
/opt/R/4.5.1/lib/R/library


.rv$add("dvs", "--git https://github.com/a2-ai/dvs2", "--directory dvs-rpkg", "--branch main")

go to https://prism.a2-ai.cloud/
find a registry you like (maybe latest)

change rproject.toml to
repositories = [
  #{alias = "PRISM", url = "https://prism.a2-ai.cloud/rpkgs/nimbus/2025.08/"},
  {alias = "PRISM", url = "https://prism.a2-ai.cloud/rpkgs/nimbus/2026.03/"},
]

.rv$sync()

usethis::create_quarto_project(".")

Now we are inside vignette/intro.qmd

.rv$add("here")

quarto needs

.rv$add("stringr", "stringi")

.rv$add("dplyr")


