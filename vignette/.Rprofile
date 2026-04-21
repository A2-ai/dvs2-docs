local({
  # Quarto starts R with cwd = the document directory (vignette/).
  # Temporarily step up to the project root so that rv's activate.R can
  # resolve its relative library path correctly, then restore the cwd.
  old_wd      <- getwd()
  project_root <- normalizePath(file.path(getwd(), ".."))
  rvr_script      <- file.path(project_root, "rv", "scripts", "rvr.R")
  activate_script <- file.path(project_root, "rv", "scripts", "activate.R")

  if (file.exists(rvr_script) && file.exists(activate_script)) {
    setwd(project_root)
    source(rvr_script)
    source(activate_script)
    setwd(old_wd)
  }
})
